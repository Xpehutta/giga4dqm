drop FUNCTION if exists s_grnplm_as_t_didsd_nnn_db_tmd.fn_drop_gen_data_tables();
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_drop_gen_data_tables()
returns void
LANGUAGE plpgsql
AS $$
DECLARE
   v_start_time TIMESTAMP := clock_timestamp();
   _log text;
   vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
   v_workflow_run_id bigint;
   v_proc text :='fn_drop_gen_data_tables';
   v_error_msg text;
   v_sql text;
   v_full_error_msg text;
   v_partition_table_full_name text;
   tmp_result_code int default 0;
v_rec record;
BEGIN

tmp_result_code = tmp_result_code + 1;
--подчищаем следы
v_sql='';
for v_rec in 
select max(data_workflow_run_id) as data_workflow_run_id,test_num from s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune group by  test_num
loop
case v_rec.test_num
	when 'test1' 
		then v_sql=v_sql||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||v_rec.data_workflow_run_id::text||';'||E'\n'
						||'	drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||v_rec.data_workflow_run_id::text||';'||E'\n';
	when 'test2' 
		then v_sql=v_sql||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal_'||v_rec.data_workflow_run_id::text||';'||E'\n';
	when 'test3' 
		then v_sql=v_sql||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn_'||v_rec.data_workflow_run_id::text||';'||E'\n'
						||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||v_rec.data_workflow_run_id::text||';'||E'\n'
						||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||v_rec.data_workflow_run_id::text||';'||E'\n'
						||'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||v_rec.data_workflow_run_id::text||';'||E'\n';
	else NULL;
end case;
end loop;
--raise notice 'v_sql=%',v_sql;
_log = v_sql;
vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(v_workflow_run_id, v_proc, 'drop data tables', _log, vlog);
execute v_sql;
tmp_result_code = tmp_result_code + 1;
END 
$$;

