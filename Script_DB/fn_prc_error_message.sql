CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.prc_error_message(v_error_sqlstate text, v_error_text text, v_error_hint text, v_error_context text, v_error_details text default null, out _errortext text)
    RETURNS text
    LANGUAGE plpgsql
    VOLATILE
AS $$

    /* function returns the native error message 
    * v_error_sqlstate  - optional(use null)    -  RETURNED_SQLSTATE value from GET STACKED DIAGNOSTICS 
    * v_error_text      - optional(use null)    -  MESSAGE_TEXT value from GET STACKED DIAGNOSTICS
    * v_error_hint      - optional(use null)    -  PG_EXCEPTION_HINT value from GET STACKED DIAGNOSTICS
    * v_error_context   - optional(use null)    -  PG_EXCEPTION_CONTEXT value from GET STACKED DIAGNOSTICS
    * v_error_details   - optional(use null)    -  PG_EXCEPTION_DETAIL value from GET STACKED DIAGNOSTICS
    */
    
<<LMAIN>>
begin
    
        _errortext = 'ERROR: SQL Error ['|| coalesce(v_error_sqlstate,'')::text ||']: '|| coalesce(v_error_text,'')::text ||'. '|| chr(13) || chr(10) || case when length(v_error_details::text) >= 0 or 1=1 then '  Detail: ' || coalesce(v_error_details,'')::text || chr(13) || chr(10) else '' end || case when length(v_error_hint::text) > 0 then '  Hint: ' || coalesce(v_error_hint,'')::text || chr(13) || chr(10) else '' end || '  Where: ' || coalesce(v_error_context,'')::text;

End LMAIN;
$$
EXECUTE ON ANY;