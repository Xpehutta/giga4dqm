CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_explain_to_debug(
in_workflow_run_id bigint,
p_sql TEXT,
p_in_param TEXT,
p_in_proc TEXT,
INOUT in_log s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log[]
)
RETURNS s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log[]
LANGUAGE plpgsql
AS $$
DECLARE
v_row TEXT;
v_plan TEXT := '';


BEGIN
-- Выполняем EXPLAIN ANALYZE для переданного SQL-запроса
FOR v_row IN EXECUTE 'EXPLAIN ANALYZE ' || p_sql LOOP
v_plan := v_plan || E'\n' || v_row;
END LOOP;

-- Передаем результат в процедуру отладки
--perform s_grnplm_as_t_didsd_nnn_db_tmd.prc_debug(p_sql,v_plan, p_in_proc);
in_log =  s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, p_in_proc, v_plan, p_sql, in_log);
EXCEPTION
WHEN OTHERS THEN
-- В случае ошибки формируем сообщение об ошибке и также передаем его в процедуру отладки
v_plan := 'Ошибка при выполнении EXPLAIN ANALYZE: ' || SQLERRM || E'\n' ||
'Для запроса: ' || p_sql;
in_log =  s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, p_in_proc, v_plan, p_sql, in_log);
END;
$$;