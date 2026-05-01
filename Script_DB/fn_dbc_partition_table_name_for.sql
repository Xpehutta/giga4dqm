CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_dbc_partition_table_name_for(inschemename text, intablename text, inpartitionvalue text, OUT _res text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
    /*
    * inschemename      - required              -  scheme name
    * intablename       - required              -  parent table name
    * inpartitionvalue  - required              -  partition value to define partition name
    */
<<LMAIN>>

    Declare v_proc                          text DEFAULT 'sp_dbc_partition_table_name_for';
    Declare v_param_log                     text DEFAULT '';

 BEGIN
    
    select max(parchildrelid::regclass::text) into _res
      from pg_class c
      join pg_namespace s
        on s.oid = c.relnamespace
      left
      join pg_partition p
        on p.parrelid = c.oid
      left
      join pg_partition_rule r
        on r.paroid = p.oid
     where 1=1
       and c.relkind  = 'r'
       and c.relname  = lower(trim(intablename))
       and s.nspname  = lower(trim(inschemename))
       and pg_get_expr(r.parlistvalues, p.parrelid)::text = ''''||lower(trim(inpartitionvalue))||'''::text'
       and p.parrelid is not null
     ;
 
END LMAIN;
 
$function$
