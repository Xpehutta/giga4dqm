CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.prc_debug(sql_query text, param text, proc text)
RETURNS void
LANGUAGE plpgsql
AS $function$
<<LMAIN>>
BEGIN
INSERT INTO S_GRNPLM_AS_T_DIDSD_NNN_db_tmd.DEBUG_LOG (SQL_QUERY,RUN_TM,PARAM,PROC) VALUES(SQL_QUERY,clock_timestamp(),PARAM,PROC);

End LMAIN;
$function$
