-- Функция для генерации тестовых данных в таблицу d_agr_cred_optn с использованием сгенерированных записей в d_agr_cred_coa

CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred(in_workflow_run_id BIGINT)
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
v_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred);';
execute v_query;
-- Логирование начала процесса
RAISE NOTICE 'Starting generation of records';

table_name := 'd_agr_cred_'||in_workflow_run_id::text;
    
    -- Формируем динамический запрос
    v_query := format('
		insert into s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||in_workflow_run_id::text||'
		(agr_cred_id, prnt_agr_cred_id, info_system_id)
		select agr_id, prnt_agr_cred_id, -1104
		from  s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' 
		group by agr_id, prnt_agr_cred_id;
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


