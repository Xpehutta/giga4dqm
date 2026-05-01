CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()
RETURNS uuid AS $$
BEGIN
    RETURN (md5(random()::text || clock_timestamp()::text))::uuid;
END;
$$ LANGUAGE plpgsql;