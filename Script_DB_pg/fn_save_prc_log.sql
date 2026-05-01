CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.save_prc_log(vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE
AS $$
	
       
	begin       
       insert into s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log
(
workflow_run_id
, run_tm
, proc
, sql_query
, param
)
       select (t.a::s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log).* from (select unnest (vlog) a) as t ;       
	end; 

$$
 