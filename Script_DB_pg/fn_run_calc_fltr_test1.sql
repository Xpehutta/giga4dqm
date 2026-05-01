drop FUNCTION if exists s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_calc_fltr_test1();
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_calc_fltr_test1 (out return_int_return_code int4)
 RETURNS int4
LANGUAGE plpgsql
AS $$
DECLARE
   v_start_time TIMESTAMP := clock_timestamp();
   _log text;
   vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
   v_workflow_run_id bigint:= (select abs(uuid_hash(s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()))::bigint);
   v_data_wf bigint;
   v_proc text :='fn_run_calc_fltr_test1_'||v_workflow_run_id;
   v_error_msg text;
   v_sql text;
   v_full_error_msg text;
   v_partition_table_full_name text;
   tmp_result_code int default 0;
BEGIN
begin

select data_workflow_run_id into v_data_wf from s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune where test_num='test1';

  return_int_return_code = 0;
  tmp_result_code = 1;

_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' запуск тестового расчета оптимизированного по плану';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC_OPT', _log, vlog);

perform  s_grnplm_as_t_didsd_nnn_db_tmd.sp_spt_je_header_fltr_separate(v_workflow_run_id,v_data_wf,'000004'::text);
  tmp_result_code = tmp_result_code + 1;
_log = 'step= '||cast(tmp_result_code as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' завершение тестового расчета оптимизированного по плану';
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'MART_CALC_OPT', _log, vlog);


v_sql = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr_'||v_workflow_run_id::text||';';
_log = v_sql;
execute v_sql;
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'Сформированная таблица удалена', _log, vlog);


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
