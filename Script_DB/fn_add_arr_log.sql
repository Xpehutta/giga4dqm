CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in in_workflow2_run_id int8, in strobject text, in param text, in sql_query text
, inout vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array)

RETURNS s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array 
       LANGUAGE plpgsql
       VOLATILE
AS $nnn$

begin

 vlog = array_append(vlog, row(in_workflow2_run_id, clock_timestamp()::text, strobject, sql_query, param)::s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log) ;

end; 

$nnn$
EXECUTE ON ANY;

 