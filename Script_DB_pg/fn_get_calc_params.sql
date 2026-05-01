/*
Функция: sp_get_calc_params
Назначение: Получение параметров расчета витрины из таблицы etl_task_param
Параметры:
  i_workflow_run_id - идентификатор запуска workflow
  i_proc - имя вызывающей процедуры
Возвращаемое значение: Пользовательский тип tp_calc_params с метаданными для расчета

Структура возвращаемого типа tp_calc_params:
- period_start_dt: начальная дата периода расчета
- period_end_dt: конечная дата периода расчета
- increment_flag: флаг инкрементального расчета
- pymnt_doc_increment_flag: флаг инкрементального расчета по документам
- old_data_del_flag: флаг удаления старых данных
- src_system_excl_list: список исключаемых систем источников (через запятую)
- src_system_excl_list_quoted: список исключаемых систем источников в формате UUID с кавычками
- agrmnt_ini_dt: дата начала действия договора
- ini_dt: дата инициализации
- pymnt_doc_new_period_start_dt: начальная дата нового периода для документов
- revenue_subtype_code_lst: список кодов подтипов доходов
- revenue_subtype_filter_src_list: список систем источников для фильтрации подтипов доходов
- revenue_subtype_filter_src_list_quoted: список систем источников в формате UUID с кавычками

Алгоритм работы:
1. Чтение параметров из etl_task_param для основных значений
2. Получение списка исключаемых систем источников из t_src_system_type
3. Получение списка систем источников для фильтрации подтипов доходов
4. Формирование результирующего набора с учетом всех параметров

Особенности:
- Поддерживает инкрементальные расчеты с учетом глубины истории
- Обрабатывает как полные, так и инкрементальные режимы расчета
- Формирует параметры для использования в других процедурах расчета
- Включает логирование начала и завершения работы
*/
drop function if exists s_grnplm_as_t_didsd_nnn_db_tmd.sp_get_calc_params ( bigint,  text);
drop type if exists  s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params;
CREATE TYPE s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params as 
			(
             period_start_dt                       text,
             period_end_dt                         text,
		 increment_flag                        smallint,
		 pymnt_doc_increment_flag              smallint,
		 old_data_del_flag                     smallint,
             src_system_excl_list                  text,
		 src_system_excl_list_quoted           text,
		 agrmnt_ini_dt                         text,
		 ini_dt                                text,
             pymnt_doc_new_period_start_dt         text, -- ранее не рассчитываемые даты в скользящем окне для фактов
             revenue_subtype_code_lst              text,
             revenue_subtype_filter_src_list       text,
             revenue_subtype_filter_src_list_quoted text
            );


create or replace function s_grnplm_as_t_didsd_nnn_db_tmd.sp_get_calc_params (i_workflow_run_id bigint, i_proc text) returns s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params
    language plpgsql
as
$$
<<LMAIN>>


/*
Purpose : Функция возвращает пользовательский тип данных с метаданными для расчета витрины

+--------+-----------+------------+---------------------+
|date    |author     |feature     |description          |
+--------+-----------+------------+---------------------+
|20240122|Vidman Y.E.|DMPLACC-1547|Создана первая версия|
|20240819|Abramkin P.A.|DMPLACC-1750|Поле 
string_agg(''''||src_system_type_id::text,''',')||'''' as system_type_list_quoted
заменено на 
string_agg(''''||src_system_type_id::text,'''::uuid,')||'''' as system_type_list_quoted
+--------+-----------+------------+---------------------+
*/
    declare v_proc    text default i_proc||'/sp_get_calc_params';
    declare _log text;
    declare _activity_count bigint default 0;
    declare vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
    declare v_result s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params%rowtype;
begin

    vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(i_workflow_run_id, v_proc, 'START', 'Вычисление параметров расчета витрины', vlog);
    select period_start_dt             ,
           period_end_dt               ,
           increment_flag              ,
           pymnt_doc_increment_flag    ,
           old_data_del_flag           ,
           coalesce(system_type_list,md5('')::uuid::text) ,
           coalesce(system_type_list_quoted ,''''||md5('')::uuid::text||'''') ,
           agrmnt_ini_dt               ,
           ini_dt,
           case when pymnt_doc_new_period_start_dt is null or
                     pymnt_doc_new_period_start_dt < to_date(period_start_dt,'YYYY-MM-DD')
                 then period_start_dt
           else to_char(pymnt_doc_new_period_start_dt,'YYYY-MM-DD')
           end as pymnt_doc_new_period_start_dt,
           revenue_subtype_code_lst,
           revenue_subtype_filter_src_list,
           revenue_subtype_filter_src_list_quoted
    from into v_result
             (
              select dmmart,
              to_char(case when max(pymnt_doc_increment_flag) = 1
                 then current_date - max(pymnt_doc_depth_days)
               else max(period_start_dt)
            end,'YYYY-MM-DD') as period_start_dt,
              to_char(case when max(pymnt_doc_increment_flag) = 1
                    then current_date
                else  max(period_end_dt)
               end, 'YYYY-MM-DD') as  period_end_dt,
              max(pymnt_doc_depth_days) as pymnt_doc_depth_days,
              max(increment_flag) as increment_flag,
              max(pymnt_doc_increment_flag) as pymnt_doc_increment_flag,
              max(old_data_del_flag) as old_data_del_flag,
              max(system_type_list) as system_type_list,
              max(system_type_list_quoted) as system_type_list_quoted,
				  max(agrmnt_ini_dt) as agrmnt_ini_dt,
				  max(ini_dt) as ini_dt,
              max(pymnt_doc_new_period_start_dt) as pymnt_doc_new_period_start_dt,
              max(revenue_subtype_code_lst) as revenue_subtype_code_lst,
              max(revenue_subtype_filter_src_list) as revenue_subtype_filter_src_list,
              max(revenue_subtype_filter_src_list_quoted) as revenue_subtype_filter_src_list_quoted
    from (
             select 'DMPL_PARAM' as dmmart,
                    case upper(param_name)
                        when 'PERIOD_START_DT' then to_date(param_val,'YYYY-MM-DD')
                        end      as period_start_dt,
                    case upper(param_name)
                        when 'PERIOD_END_DT' then to_date(param_val,'YYYY-MM-DD')
                        end      as period_end_dt,
                    case upper(param_name)
                        when 'PYMNT_DOC_DEPTH_DAYS' then param_val::smallint
                        end      as pymnt_doc_depth_days,
                    case upper(param_name)
                        when 'INCREMENT_FLAG' then param_val::smallint
                        end      as increment_flag,
                    case upper(param_name)
                        when 'PYMNT_DOC_INCREMENT_FLAG' then param_val::smallint
                        end      as pymnt_doc_increment_flag,
                    case upper(param_name)
                        when 'OLD_DATA_DEL_FLAG' then param_val::smallint
                        end      as old_data_del_flag,
                    null::text as system_type_list,
                    null::text as system_type_list_quoted,
				  case upper(param_name)
                        when 'AGRMNT_INI_DT' then param_val
                        end      as agrmnt_ini_dt,
				  case upper(param_name)
                        when 'INI_DT' then param_val
                        end      as ini_dt,
			     case upper(param_name)
                        when 'PYMNT_DOC_CALC_DT_HWM' then to_date(param_val,'YYYY-MM-DD')
                        end      as pymnt_doc_new_period_start_dt
,
                     case upper(param_name)
                     when 'REVENUE_SUBTYPE_CODE' then  param_val
                     end      as revenue_subtype_code_lst,
                     null::text as  revenue_subtype_filter_src_list,
                     null::text as  revenue_subtype_filter_src_list_quoted
             from s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param
             where upper(param_name) in
                   ('PERIOD_START_DT',
                    'PERIOD_END_DT',
                    'INCREMENT_FLAG',
                    'PYMNT_DOC_INCREMENT_FLAG',
                    'PYMNT_DOC_DEPTH_DAYS',
                    'OLD_DATA_DEL_FLAG',
					'AGRMNT_INI_DT',
					'INI_DT',
			    'PYMNT_DOC_CALC_DT_HWM',
                    'REVENUE_SUBTYPE_CODE')
           union all
             select 'DMPL_PARAM' as dmmart,
                    null::date,
                    null::date,
                    null::smallint,
                    null::smallint,
                    null::smallint,
                    null::smallint,
                    string_agg(src_system_type_id::text,',') as system_type_list,
                    null::text,
				  null::text,
				  null::text,
			    null::date,
                    null::text,
                    null::text,
                    null::text
                    from s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type t
                      join
                  (select unnest(string_to_array(param_val,',')) as src_system_type_cd, param_name
                   from s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param where workflow_name = 'wf_C_IEDW_999_B'
                                                                   and param_name = 'SRC_SYSTEM_EXCL_LIST') params
                  on t.src_system_type_cd = params.src_system_type_cd
             group by dmmart
             union all
             select 'DMPL_PARAM' as dmmart,
                     null::date,
                    null::date,
                    null::smallint,
                    null::smallint,
                    null::smallint,
                    null::smallint,
                    null::text,
                    string_agg(''''||src_system_type_id::text,'''::uuid,')||'''::uuid' as system_type_list_quoted,
				  null::text,
				  null::text,
			    null::date,
                    null::text,
                    null::text,
                    null::text
             from s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type t
                      join
                  (select unnest(string_to_array(param_val,',')) as src_system_type_cd, param_name
                   from s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param where workflow_name = 'wf_C_IEDW_999_B'
                                                                   and param_name = 'SRC_SYSTEM_EXCL_LIST') params
                  on t.src_system_type_cd = params.src_system_type_cd
             group by dmmart
          ---
              union all
              select 'DMPL_PARAM' as dmmart,
                      null::date,
                      null::date,
                      null::smallint,
                      null::smallint,
                      null::smallint,
                      null::smallint,
                      null::text,
                      null::text,
                      null::text,
                      null::text,
                      null::date,
                      null::text,
                      string_agg(src_system_type_id::text,',') as revenue_subtype_filter_src_list,
                      null::text
              from s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type t
              join
              (select unnest(string_to_array(param_val,',')) as src_system_type_cd, param_name
              from s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param where workflow_name = 'wf_C_IEDW_999_B'
              and param_name = 'REVENUE_SUBTYPE_FILTER_SOURCES') params
              on t.src_system_type_cd = params.src_system_type_cd
              group by dmmart
              union all
              select 'DMPL_PARAM' as dmmart,
                      null::date,
                      null::date,
                      null::smallint,
                      null::smallint,
                      null::smallint,
                      null::smallint,
                      null::text,
                      null::text,
                      null::text,
                      null::text,
                      null::date,
                      null::text,
                      null::text,
                      string_agg(''''||src_system_type_id::text,'''::uuid,')||'''::uuid' as revenue_subtype_filter_src_list_quoted
              from s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type t
              join
              (select unnest(string_to_array(param_val,',')) as src_system_type_cd, param_name
              from s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param where workflow_name = 'wf_C_IEDW_999_B'
              and param_name = 'REVENUE_SUBTYPE_FILTER_SOURCES') params
              on t.src_system_type_cd = params.src_system_type_cd
              group by dmmart
         ) params
    group by dmmart) t;
    get diagnostics _activity_count = row_count;
    _log='step='||cast(1 as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' rows=' || cast(_activity_count as text)||' Params -> '||v_result;
    vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(i_workflow_run_id, v_proc, 'FINISH', _log, vlog);
    perform s_grnplm_as_t_didsd_nnn_db_tmd.save_prc_log(vlog);
    return v_result;
END LMAIN;
$$;