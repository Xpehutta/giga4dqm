/*
Функция: fn_run_test3
Назначение: Основная функция запуска тестирования запроса вычисления точек расчета показателей по кредитным сделкам
Параметры:
 in_num_records  -- Общее количество записей для генерации
 in_max_agr_per_coa INTEGER DEFAULT 100, -- Максимальное количество agr_cred_id на один coa_id
 in_batch_size INTEGER DEFAULT 100    -- Размер пакета для вставки
 return_int_return_code - код возврата (0 - успех, отрицательное значение - ошибка на этапе с номером |кода|)

Описание работы:
1. Генерация тестовых данных:
   1.1. связей счет - договор  (d_agr_cred_coa)
   1.2. фактические операции по кредитным сделкам  (d_agr_cred_optn)
   1.3. справочник кредитных сделок (d_agr_cred)
   1.4. даты изменения баланса на счетах, связанных с кредитными сделками (d_tech_tbl_coa_bal_h)
2. Расчет таблицы d_agr_cred_coa_period_calc_dt (форимрования дат (точек расчета) показателей по кредитным сделкам).
3. Логирование всех этапов выполнения

Логирование: Все этапы логируются в массив vlog, который затем сохраняется в etl_bkmart_log
Обработка ошибок: При возникновении исключения фиксируется код ошибки и сообщение, возвращается отрицательный код возврата
*/
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test3(in_num_records bigint,in_max_agr_per_coa bigint, in_batch_size bigint, out return_int_return_code int4)
 RETURNS int4
LANGUAGE plpgsql
AS $$
DECLARE
   v_start_time TIMESTAMP := clock_timestamp();
   _log text;
   vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
   v_workflow_run_id bigint:= (select abs(uuid_hash(s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()))::bigint);
   v_proc text :='fn_run_test3_'||in_num_records::text;
   v_error_msg text;
   v_full_error_msg text;
   v_partition_table_full_name text;
   tmp_result_code int default 0;
   v_sql text;
BEGIN
begin

 -- очищаем и заполняем систетику
  return_int_return_code = 0;
  tmp_result_code = 1;
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'START', 'workflow_run_id='||v_workflow_run_id, vlog);
  tmp_result_code = tmp_result_code + 1;
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных d_agr_cred_coa';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
  perform s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_coa(v_workflow_run_id,in_num_records,in_max_agr_per_coa,in_batch_size);
 _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных d_agr_cred_coa';
 vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

tmp_result_code = tmp_result_code + 1;
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных d_agr_cred_optn';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
perform s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_optn(v_workflow_run_id);
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных d_agr_cred_optn';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

tmp_result_code = tmp_result_code + 1;
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных d_tech_tbl_coa_bal_h';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
perform s_grnplm_as_t_didsd_nnn_db_tmd.generate_tech_tbl_coa_bal_h(v_workflow_run_id);
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных d_tech_tbl_coa_bal_h';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

tmp_result_code = tmp_result_code + 1;
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных d_agr_cred';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
perform s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred(v_workflow_run_id);
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных d_agr_cred';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

tmp_result_code = tmp_result_code + 1;
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск тестового расчета ';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);
   perform from s_grnplm_as_t_didsd_nnn_db_tmd.sp_dm_ent_ld_d_agr_cred_coa_period_calc_dt(v_workflow_run_id);
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершен тестовый расчет ';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);


v_sql = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt_'||v_workflow_run_id::text||';';
_log = v_sql;

vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'drop tables', _log, vlog);
execute v_sql;

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

vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'FAIL', v_full_error_msg, vlog);
return_int_return_code = tmp_result_code * (-1);

--raise notice '%', result_s;
end;

perform s_grnplm_as_t_didsd_nnn_db_tmd.save_prc_log(vlog);

END;
$$;