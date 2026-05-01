drop FUNCTION if exists s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test1(bigint,bigint);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_gen_data_test1(in_coa_cnt bigint,in_je_line_cnt bigint,  out return_int_return_code int4)
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
delete from s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune where test_num='test1';

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

insert into s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune(test_num,data_workflow_run_id,sp_workflow_run_id) values('test1',v_workflow_run_id,0); 


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
