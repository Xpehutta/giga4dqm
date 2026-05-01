/*
Функция: sp_spt_je_header_fltr
Назначение: Основная процедура расчета витрины t_spt_je_header_fltr с использованием временной таблицы
Параметры:
  in_workflow_run_id - идентификатор запуска workflow
  in_info_system_inst_cd - код системы источника ('000004' или '000027')
  return_int_return_code - код возврата (0 - успех, -1 - ошибка)

Алгоритм работы:
1. Определение имени партиционированной таблицы по коду системы
2. Для системы '000004' создание временной таблицы vt_coa_add со счетами 706/707 определенных типов
3. Очистка целевой партиционированной таблицы
4. Формирование и выполнение SQL-запроса вставки данных:
   - Для '000004': с учетом временной таблицы и различных условий фильтрации
   - Для '000027': упрощенный запрос
5. Сбор статистики по таблице

Особенности:
- Использует динамический SQL с подстановкой параметров
- Поддерживает два режима работы для разных систем источников
- Использует временные таблицы для оптимизации фильтрации
- Интегрирована с системой логирования через sp_execute_run
- Выполняет EXPLAIN ANALYZE для анализа плана выполнения
*/
drop FUNCTION if exists s_grnplm_as_t_didsd_nnn_db_tmd.sp_spt_je_header_fltr_separate(int8,int8, text);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_spt_je_header_fltr_separate(in in_workflow_run_id int8,in in_data_wf int8, in in_info_system_inst_cd text, out return_int_return_code int4)
	RETURNS int4
	LANGUAGE plpgsql
	VOLATILE
AS $$
	


<<lmain>>
  declare v_proc text default 'sp_spt_je_header_fltr'||'_'||in_info_system_inst_cd;
  declare tmp_result_row_count bigint default 0;
  declare tmp_result_code int default 0;
  declare _activity_count bigint default 0;
  declare _log text;
  declare vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
  declare v_calc_params s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params%rowtype ;
  declare v_sql text default '';
  declare v_error_msg text;
  declare v_full_error_msg text;
  declare v_partition_table_full_name text;
  declare v_partition_table_name text;
  declare v_books_cd text = case
                                  when in_info_system_inst_cd = '000004' then '''СБ_РСБУ'',''-1'''
                                  when in_info_system_inst_cd = '000027' then '''СБ_РСБУ_ГК'''
  end;
begin

begin

return_int_return_code = 0;
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'START', 'workflow_run_id='||in_workflow_run_id, vlog);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.sp_get_calc_params(in_workflow_run_id,v_proc) into v_calc_params;

tmp_result_code = 2;
v_sql = 'create table s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr);';
vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, v_sql, v_proc , vlog);

/*select s_grnplm_as_t_didsd_nnn_db_tmd.sp_dbc_partition_table_name_for( 's_grnplm_as_t_didsd_nnn_db_tmd', 't_spt_je_header_fltr', in_info_system_inst_cd ) into v_partition_table_full_name;

v_partition_table_name = substr(v_partition_table_full_name,position('.' in v_partition_table_full_name)+1);
_log='step='||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' v_partition_table_full_name -> '||v_partition_table_full_name||' v_partition_table_name -> '||v_partition_table_name;
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'QRY_RUN', _log, vlog);
*/
-- для SL требуется по исключамым системам использовать полупроваодки по 706 и 707 счетам
if in_info_system_inst_cd = '000004' then
  tmp_result_code = tmp_result_code + 1;
  v_sql = 'drop table if exists vt_coa_add_'||in_workflow_run_id::text||';';
 vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, v_sql, v_proc , vlog);
v_sql = ' create temporary table vt_coa_add_'||in_workflow_run_id::text||'
             (coa_id uuid); ';
vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, v_sql, v_proc , vlog);

v_sql = ' insert into vt_coa_add_'||in_workflow_run_id::text||'
             select coa_id from s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||in_data_wf::text||' c
             where c.deleted_flag = ''N''
               and c.info_system_inst_cd = ''000004''
               and substr(c.coa_num,1,3)in (''706'',''707'')
               and substr(c.coa_num, 14, 7) = ANY (''{{{revenue_subtype_code_lst}}}'')
			   ;';


 v_sql = replace(v_sql, '{{revenue_subtype_code_lst}}',v_calc_params.revenue_subtype_code_lst);
 vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, v_sql, v_proc , vlog,true,true);
end if;

tmp_result_code = tmp_result_code + 1;
--v_sql = 'truncate table {{target_table_name}}';
tmp_result_code = tmp_result_code + 1;
v_sql = case when in_info_system_inst_cd = '000004'
    then 'insert into {{target_table_name}} (
         je_header_id,
         je_line_coa_id,
         incl_reason,
         info_system_inst_cd,
         pymnt_doc_id,
         registry_id,
         host_je_header_rel_id,
         workflow_run_id,
         deleted_flag,
         int_org_id,
         je_header_val_dt,
         je_line_trans_amt,
         je_line_local_amt,
         je_header_desc,
         je_line_cred_ind,
			je_type_id,
         src_system_type_id)
    select je_header_id,
         je_line_coa_id,
         1 as incl_reason,
         ''{{in_info_system_inst_cd}}'',
         pymnt_doc_id,
         registry_id,
         host_je_header_rel_id,
         workflow_run_id,
         deleted_flag,
         int_org_id,
         je_header_val_dt,
         je_line_trans_amt,
         je_line_local_amt,
         je_header_desc,
         je_line_cred_ind,
			je_type_id,
         src_system_type_id
      from s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_data_wf::text||' ln
      left
      join vt_coa_add_'||in_workflow_run_id::text||' c
        on ln.je_line_coa_id = c.coa_id
      left
      join vt_coa_add_'||in_workflow_run_id::text||' cc
        on ln.je_line_corr_coa_id = cc.coa_id
    where ln.deleted_flag = ''N''
       and set_of_books_cd in ({{books_cd}})
       and info_system_inst_cd = ''{{in_info_system_inst_cd}}''
       and ln.je_header_val_dt between  date''{{period_start_dt}}'' and date''{{period_end_dt}}''
       and (
         (je_line_cred_ind=''N'' and src_system_type_id not in ({{src_system_excl_list_quoted}}))
         or (je_line_cred_ind=''Y'')
         or (ln.src_system_type_id in ({{add_src_system_list}}) and (c.coa_id is not null or cc.coa_id is not null ))
         )
       and src_system_type_id is not null 
	   ;'
    when in_info_system_inst_cd = '000027'
    then ' insert into {{target_table_name}} (je_header_id,je_line_coa_id,incl_reason,info_system_inst_cd, pymnt_doc_id,registry_id,host_je_header_rel_id,workflow_run_id,deleted_flag,int_org_id,je_header_val_dt,je_line_trans_amt,je_line_local_amt,je_header_desc,je_line_cred_ind,je_type_id,src_system_type_id,number_test_parallel) 
	select je_header_id,
        je_line_coa_id,
        1 as incl_reason,
        ''{{in_info_system_inst_cd}}'',
        pymnt_doc_id,
        registry_id,
        host_je_header_rel_id,
        workflow_run_id,
        deleted_flag,
        int_org_id,
        je_header_val_dt,
        je_line_trans_amt,
        je_line_local_amt,
        je_header_desc,
        je_line_cred_ind,
		  je_type_id,
        src_system_type_id
  from s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_data_wf::text||' ln
  where ln.deleted_flag = ''N''
    and set_of_books_cd in ({{books_cd}})
    and info_system_inst_cd = ''{{in_info_system_inst_cd}}''
    and ln.je_header_val_dt between  date''{{period_start_dt}}'' and date''{{period_end_dt}}'''
 end;

    v_sql = replace(
                 replace(
                    replace(
                          replace(
                                  replace(
                                         replace(
                                                 replace(v_sql,'{{src_system_excl_list_quoted}}',v_calc_params.src_system_excl_list_quoted)
                                             ,'{{period_start_dt}}',v_calc_params.period_start_dt)
                                     ,'{{period_end_dt}}',v_calc_params.period_end_dt)
                             ,'{{in_info_system_inst_cd}}',in_info_system_inst_cd)
                     ,'{{books_cd}}',v_books_cd)
             ,'{{target_table_name}}', 's_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr_'||in_workflow_run_id::text)
      , '{{add_src_system_list}}',v_calc_params.revenue_subtype_filter_src_list_quoted);




-- выполнение сформированного SQL c explain
vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run(in_workflow_run_id , tmp_result_code, v_sql, v_proc , vlog,true,true);


-- сбор статистики
perform s_grnplm_as_t_didsd_nnn_db_tmd.sp_collect_stat('s_grnplm_as_t_didsd_nnn_db_tmd','t_spt_je_header_fltr_'||in_workflow_run_id::text);
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'FINISH', 'workflow_run_id='||in_workflow_run_id, vlog);
--Логирование ошибок
exception when others then

get stacked diagnostics
v_error_msg = pg_exception_context;

v_full_error_msg = 'FAIL : '||v_proc||' : '||substr((cast(clock_timestamp() as text)), 1, 22) ||chr(10)
||' ErrorState:=' || sqlstate
 || ' ErrorCode:=' || sqlerrm ||chr(10)
 || ' result_code=' || cast(tmp_result_code as text) ||chr(10)
 || ' SqlQuery:=' || current_query() ||chr(10)
 || ' pg_exception_context:=' ||v_error_msg;

vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'FAIL', v_full_error_msg, vlog);
return_int_return_code = -1;

--raise notice '%', result_s;
end;

perform s_grnplm_as_t_didsd_nnn_db_tmd.save_prc_log(vlog);

end lmain;


$$
