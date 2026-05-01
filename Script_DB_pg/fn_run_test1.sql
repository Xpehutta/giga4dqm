/*
Функция: fn_run_test1
Назначение: Основная функция запуска комплексного тестирования производительности витрины placc
Параметры:
  in_coa_cnt - количество счетов для генерации тестовых данных
  in_je_line_cnt - количество проводок для генерации тестовых данных
  return_int_return_code - код возврата (0 - успех, отрицательное значение - ошибка на этапе с номером |кода|)

Описание работы:
1. Генерация тестовых данных для счетов (t_coa)
2. Генерация тестовых данных для проводок (t_je_line)
3. Расчет витрины методом с временной таблицей (sp_spt_je_header_fltr)
4. Расчет витрины методом с CTE (sp_spt_je_header_fltr_skew_data)
5. Логирование всех этапов выполнения

Логирование: Все этапы логируются в массив vlog, который затем сохраняется в etl_bkmart_log
Обработка ошибок: При возникновении исключения фиксируется код ошибки и сообщение, возвращается отрицательный код возврата
*/
drop FUNCTION if exists s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1(bigint,bigint);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1(in_coa_cnt bigint,in_je_line_cnt bigint,  out return_int_return_code int4)
 RETURNS int4
LANGUAGE plpgsql
AS $$
DECLARE
   v_start_time TIMESTAMP := clock_timestamp();
   _log text;
   vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
   v_workflow_run_id bigint:= (select abs(uuid_hash(s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()))::bigint);
   v_proc text :='fn_run_test1_'||in_je_line_cnt::text;
   v_error_msg text;
   v_sql text;
   v_full_error_msg text;
   v_partition_table_full_name text;
   tmp_result_code int default 0;
BEGIN
begin
 -- очищаем и заполняем систетику
  return_int_return_code = 0;
  tmp_result_code = 1;
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'START', 'workflow_run_id='||v_workflow_run_id, vlog);
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных t_coa';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
  perform s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_coa_data(v_workflow_run_id,in_coa_cnt);
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных t_coa';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

  tmp_result_code = tmp_result_code + 1;
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск генерации тестовых данных t_je_line';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);
  perform s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_je_line_data(v_workflow_run_id,in_je_line_cnt);
 _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершена генерация тестовых данных t_je_line';
 vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'DATA_PREP', _log, vlog);

  tmp_result_code = tmp_result_code + 1;
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск тестового расчета оптимизированного по плану';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);
  --select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_je_line_data(in_coa_cnt);
   perform  s_grnplm_as_t_didsd_nnn_db_tmd.sp_spt_je_header_fltr(v_workflow_run_id,'000004'::text);
  _log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершен тестовый расчет оптимизированного по плану ';
  vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);

tmp_result_code = tmp_result_code + 1;
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск тестового расчета с перекосом в соедиении';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);
--select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_je_line_data(in_coa_cnt);
perform  s_grnplm_as_t_didsd_nnn_db_tmd.sp_spt_je_header_fltr_skew_data(v_workflow_run_id,'000004'::text);
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершен тестовый расчет с перекосом в соедиении';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC', _log, vlog);

--подчищаем следы

v_sql = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr_skew_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||v_workflow_run_id::text||';
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||v_workflow_run_id::text||';';
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