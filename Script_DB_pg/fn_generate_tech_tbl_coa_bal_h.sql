CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.generate_tech_tbl_coa_bal_h(in_workflow_run_id BIGINT)
RETURNS TEXT AS $$
DECLARE

v_start_time TIMESTAMP;
v_end_time TIMESTAMP;
v_message TEXT;
v_query text;
table_name text;

v_total_lines bigint;

BEGIN
v_start_time := clock_timestamp();
v_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h);';
execute v_query;
-- Логирование начала процесса
RAISE NOTICE 'Starting generation of records';

table_name := 'd_tech_tbl_coa_bal_h_'||in_workflow_run_id::text;
    
    -- Формируем динамический запрос
    v_query := format('
			insert into %I.%I (agr_id, sl_coa_id,h_start_dt, h_end_dt)
			with grain as
			(select agr_id,
			sl_coa_id,
			CURRENT_DATE - (random() * (365 * 2))::int as h_start_dt
			from  s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||'  
			join (select generate_series(1,10)) t
			on 1=1
			)
			select agr_id,
			sl_coa_id,
			h_start_dt,
			coalesce(lead(h_start_dt) over (partition BY AGR_ID, sl_coa_id),date''9999-12-31'') as h_end_dt
			from grain
  ', 's_grnplm_as_t_didsd_nnn_db_tmd', table_name);
    
    -- Выполняем запрос
    EXECUTE v_query;

get diagnostics v_total_lines = row_count;
v_end_time := clock_timestamp();
v_message := FORMAT('Successfully generated %s records in %s seconds ',
v_total_lines,
EXTRACT(EPOCH FROM (v_end_time - v_start_time))::NUMERIC(10,2));

RAISE NOTICE '%', v_message;




RETURN v_message;
END;
$$ LANGUAGE plpgsql;


