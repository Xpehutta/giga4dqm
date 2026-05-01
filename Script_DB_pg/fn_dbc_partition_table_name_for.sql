CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_dbc_partition_table_name_for(
    p_schema_name text,
    p_table_name text,
    p_partition_value text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    -- Greenplum-specific partition catalog lookup is not available in PostgreSQL.
    -- Return base table name as fallback for compatibility.
    RETURN format('%I.%I', p_schema_name, p_table_name);
END;
$$;
