-- Функция для генерации тестовых данных в таблицу d_agr_cred_optn с использованием сгенерированных записей в d_agr_cred_coa

CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_optn(in_workflow_run_id bigint)
RETURNS TEXT AS $$
DECLARE

v_start_time TIMESTAMP;
v_end_time TIMESTAMP;
v_message TEXT;
table_name text;
v_query text;

v_total_lines bigint;

BEGIN
v_start_time := clock_timestamp();

-- Логирование начала процесса
RAISE NOTICE 'Starting generation of records';

v_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn);';
execute v_query;


table_name := 'd_agr_cred_optn_'||in_workflow_run_id::text;
    
    -- Формируем динамический запрос
    v_query := format('
			insert into %I.%I
			(agr_cred_id, agr_cred_optn_id, optn_dt)
			with grain as
			(select agr_id
			from  s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' 
			group by agr_id, prnt_agr_cred_id
			)
			select agr_id as agr_cred_id
			,s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid() as agr_cred_optn_id
			,CURRENT_DATE - (random() * (365 * 2))::int as optn_dt
			from grain
			join (select generate_series(1,100)) t
			on 1=1
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


