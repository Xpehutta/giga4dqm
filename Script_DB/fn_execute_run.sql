-- DROP FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run(in int8, in int4, in text, in text, inout s_grnplm_as_t_didsd_nnn_db_tmd."_tp_dm_log", in bool, in bool);

CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run(in_workflow_run_id bigint, in_step integer, in_statement text, in_proc_name text, INOUT in_log s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log[], in_raise_exceptionflag boolean DEFAULT true, in_expalain_statement_flag boolean DEFAULT false)
 RETURNS s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log[]
 LANGUAGE plpgsql
AS $function$

    /** executing and logging sql-statement 
    * in_statement           - required              -  sql-statement
    * in_param               - required              -  procedure parameters
    * in_procname            - required              -  procedure name, sql-statement  owner
    * in_log                 - required              -  array of records log table debug_log_run
    * in_raise_exceptionflag  - optional              -  true/false flag, raise or don't error exception, false means silent exception, (default is true - non silent)
    
    +--------+-----------+------------+---------------------+
    |date    |author     |feature     |description          |
    +--------+-----------+------------+---------------------+
    |20240122|Vidman Y.E.|DMPLACC-1547|Создана первая версия|
    +--------+-----------+------------+---------------------+
	*/
<<LMAIN>>

    Declare _startTimeStamp timestamp;
    Declare _activity_count bigint;

    Declare v_error_text                    text;
    Declare v_error_sqlstate                text;
    Declare v_error_hint                    text;
    Declare v_error_context                 text;
    Declare v_error_details                 text;
	Declare _log                            text;

BEGIN

    _startTimeStamp = clock_timestamp();

    begin

    _log='step='||cast(in_step as text)||' before execute query  tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' v_sql -> '||in_statement;
    in_log =  s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, in_proc_name, 'QRY_RUN', _log, in_log);

-- если in_expalain_statement_flag - выполним запрос с explain analyze

 if  in_expalain_statement_flag then
    in_log = s_grnplm_as_t_didsd_nnn_db_tmd.fn_explain_to_debug(in_workflow_run_id,in_statement,'',in_proc_name,in_log);
else
-- иначе просто выполним
 execute in_statement;
  end if;

 


    get diagnostics _activity_count = row_count;
    _log='step='||cast(in_step as text)||' after execute query  tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || ' rows=' || cast(_activity_count as text)||' v_sql -> '||in_statement;
    in_log =  s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, in_proc_name, 'QRY_RUN', _log, in_log);


    exception
        when others then
            GET STACKED DIAGNOSTICS v_error_sqlstate    = RETURNED_SQLSTATE,
                                   v_error_text        = MESSAGE_TEXT,
                                  v_error_hint        = PG_EXCEPTION_HINT,
                                  v_error_context     = PG_EXCEPTION_CONTEXT,
                                  v_error_details     = PG_EXCEPTION_DETAIL;

            if in_raise_exceptionflag then

                raise exception '%', s_grnplm_as_t_didsd_nnn_db_tmd.prc_error_message( v_error_sqlstate, v_error_text,  v_error_hint, v_error_context, coalesce(v_error_details, '') || ': sql statement is :'|| in_statement);

            else
               _log='step='||cast(in_step as text)||' tm=' || substr((cast(clock_timestamp() as text)), 1, 22) || 'The statement "' || in_statement || '" was skipped because of exception: ' || s_grnplm_as_t_didsd_nnn_db_tmd.prc_error_message( v_error_sqlstate, v_error_text,  v_error_hint, v_error_context, v_error_details );
               in_log =  s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, in_proc_name, 'QRY_FAIL', _log, in_log);
            end if;

    end;

END LMAIN;


$function$
;