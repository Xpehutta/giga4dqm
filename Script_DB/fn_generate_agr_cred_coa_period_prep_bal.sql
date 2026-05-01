-- Функция для генерации тестовых данных в таблицу d_agr_cred_coa_period_prep_bal
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_coa_period_prep_bal(
in_workflow_run_id bigint,
p_num_records bigint DEFAULT 1000,  -- Общее количество записей для генерации
p_max_agr_per_coa bigint DEFAULT 100, -- Максимальное количество agr_cred_id на один coa_id
p_batch_size bigint DEFAULT 100    -- Размер пакета для вставки
)
RETURNS TEXT AS $$
DECLARE
v_records_generated INTEGER := 0;
v_batch_count INTEGER := 0;
v_current_batch INTEGER := 0;
v_start_time TIMESTAMP;
v_end_time TIMESTAMP;
v_message TEXT;
v_table_name text;
v_query text;
-- Массивы для хранения batch данных
v_agr_cred_id UUID[];
v_coa_id UUID[];
v_coa_num TEXT[];
v_coa_n_id UUID[];
v_agr_coa_role_id UUID[];
v_coa_to_agrmnt_role_cd TEXT[];
v_meas_cd TEXT[];
v_start_dt DATE[];
v_end_dt DATE[];
v_crncy_id UUID[];
v_crncy_cd TEXT[];
v_iso_crncy_cd TEXT[];
v_bal_amt NUMERIC[];
v_bal_rub NUMERIC[];
v_prnt_agr_cred_id UUID[];
v_ignore_flag TEXT[];
v_own_calc_rub NUMERIC[];
v_old_calc_rub NUMERIC[];
v_agr_cred_coa_type_id TEXT[];
v_own_calc_rub_prep NUMERIC[];
v_calc_rub NUMERIC[];
v_calc_weight NUMERIC[];
v_prvsn_port_flag TEXT[];
v_lowest_flag TEXT[];
v_agr_cred_type_cd TEXT[];
v_P_cnt NUMERIC[];
v_J_cnt NUMERIC[];
v_N_cnt NUMERIC[];
v_info_system_id SMALLINT[];
v_agr_cred_close_dt DATE[];

-- Временные переменные
v_i INTEGER;
v_j INTEGER;
v_current_coa_id UUID;
v_current_coa_num TEXT;
v_current_coa_n_id UUID;
v_current_meas_cd TEXT;
v_current_start_dt DATE;
v_current_end_dt DATE;
v_agr_count INTEGER;

-- Массивы возможных значений для генерации
v_meas_cd_options TEXT[] := ARRAY['AGRA_L020', 'AGRA_L023', 'AGRA_L049', 'AGRA_L050', 'AGRA_L052', 'AGRA_L053'];
v_coa_to_agrmnt_role_options TEXT[] := ARRAY['СПИС_ССУД_ЗАДОЛЖ', 'СПИС_ВНЕБАЛ_НЕУСТ', 'СПИС_ВНЕБАЛ_ГОСПОШ', 'СПИС_ВНЕБАЛ_ТРЕТ_СБОР', 'ПРОЦ_СПИС_НА_ВНЕБ', 'accred'];
v_iso_crncy_options TEXT[] := ARRAY['RUR', 'USD', 'EUR'];
v_flag_options TEXT[] := ARRAY['Y', 'N'];
v_agr_cred_type_options TEXT[] := ARRAY['0', '1', '4', 'L'];
v_info_system_options SMALLINT[] := ARRAY[-1004, -1035];

-- UUIDs из сэмпла для реалистичности
v_crncy_id_rur UUID := '29fde458-b834-f3fa-26c5-b2da81c1a94d';

BEGIN
v_start_time := clock_timestamp();
v_table_name='d_agr_cred_coa_period_prep_bal_'||in_workflow_run_id::text;
v_query = 'create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal) distributed by(agr_cred_id);
drop table if exists vt_d_agr_cred_coa_period_prep_bal;
create temporary table vt_d_agr_cred_coa_period_prep_bal (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal) distributed by(agr_cred_id);';
execute v_query;


-- Логирование начала процесса
RAISE NOTICE 'Starting generation of % records (max % agr_cred per coa)', p_num_records, p_max_agr_per_coa;

-- Инициализация массивов
v_agr_cred_id := ARRAY[]::UUID[];
v_coa_id := ARRAY[]::UUID[];
v_coa_num := ARRAY[]::TEXT[];
v_coa_n_id := ARRAY[]::UUID[];
v_agr_coa_role_id := ARRAY[]::UUID[];
v_coa_to_agrmnt_role_cd := ARRAY[]::TEXT[];
v_meas_cd := ARRAY[]::TEXT[];
v_start_dt := ARRAY[]::DATE[];
v_end_dt := ARRAY[]::DATE[];
v_crncy_id := ARRAY[]::UUID[];
v_crncy_cd := ARRAY[]::TEXT[];
v_iso_crncy_cd := ARRAY[]::TEXT[];
v_bal_amt := ARRAY[]::NUMERIC[];
v_bal_rub := ARRAY[]::NUMERIC[];
v_prnt_agr_cred_id := ARRAY[]::UUID[];
v_ignore_flag := ARRAY[]::TEXT[];
v_own_calc_rub := ARRAY[]::NUMERIC[];
v_old_calc_rub := ARRAY[]::NUMERIC[];
v_agr_cred_coa_type_id := ARRAY[]::TEXT[];
v_own_calc_rub_prep := ARRAY[]::NUMERIC[];
v_calc_rub := ARRAY[]::NUMERIC[];
v_calc_weight := ARRAY[]::NUMERIC[];
v_prvsn_port_flag := ARRAY[]::TEXT[];
v_lowest_flag := ARRAY[]::TEXT[];
v_agr_cred_type_cd := ARRAY[]::TEXT[];
v_P_cnt := ARRAY[]::NUMERIC[];
v_J_cnt := ARRAY[]::NUMERIC[];
v_N_cnt := ARRAY[]::NUMERIC[];
v_info_system_id := ARRAY[]::SMALLINT[];
v_agr_cred_close_dt := ARRAY[]::DATE[];

-- Генерация данных
WHILE v_records_generated < p_num_records LOOP
-- Генерируем уникальный coa_id для группы
v_current_coa_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();
v_current_coa_num := '9180281' || LPAD(FLOOR(RANDOM() * 100000000)::TEXT, 8, '0');
v_current_coa_n_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();
v_current_meas_cd := v_meas_cd_options[1 + FLOOR(RANDOM() * array_length(v_meas_cd_options, 1))];

-- Генерируем start_dt и end_dt (одинаковые для всех записей с этим coa_id)
v_current_start_dt := CURRENT_DATE - (FLOOR(RANDOM() * 365) + 30)::INTEGER;
IF RANDOM() > 0.1 THEN -- 90% записей с '9999-12-31'
v_current_end_dt := '9999-12-31';
ELSE
v_current_end_dt := v_current_start_dt + (FLOOR(RANDOM() * 180) + 30)::INTEGER;
END IF;

-- Определяем количество agr_cred для этого coa_id (от 1 до p_max_agr_per_coa)
v_agr_count := GREATEST(1, FLOOR(RANDOM() * p_max_agr_per_coa)::INTEGER);

-- Корректируем, чтобы не превысить общее количество
IF v_records_generated + v_agr_count > p_num_records THEN
v_agr_count := p_num_records - v_records_generated;
END IF;

-- Генерируем записи для этого coa_id
FOR v_j IN 1..v_agr_count LOOP
-- Добавляем в массивы
v_agr_cred_id := array_append(v_agr_cred_id, s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid());
v_coa_id := array_append(v_coa_id, v_current_coa_id);
v_coa_num := array_append(v_coa_num, v_current_coa_num);
v_coa_n_id := array_append(v_coa_n_id, v_current_coa_n_id);
v_agr_coa_role_id := array_append(v_agr_coa_role_id, s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid());
v_coa_to_agrmnt_role_cd := array_append(v_coa_to_agrmnt_role_cd,
v_coa_to_agrmnt_role_options[1 + FLOOR(RANDOM() * array_length(v_coa_to_agrmnt_role_options, 1))]);
v_meas_cd := array_append(v_meas_cd, v_current_meas_cd);
v_start_dt := array_append(v_start_dt, v_current_start_dt);
v_end_dt := array_append(v_end_dt, v_current_end_dt);
v_crncy_id := array_append(v_crncy_id, v_crncy_id_rur);
v_crncy_cd := array_append(v_crncy_cd, '810');
v_iso_crncy_cd := array_append(v_iso_crncy_cd,
v_iso_crncy_options[1 + FLOOR(RANDOM() * array_length(v_iso_crncy_options, 1))]);

-- Генерация числовых значений
v_bal_amt := array_append(v_bal_amt, (RANDOM() * 10000000)::NUMERIC(20,2));
v_bal_rub := array_append(v_bal_rub, (RANDOM() * 10000000)::NUMERIC(20,2));

-- Parent ID (50% записей имеют parent)
IF RANDOM() > 0.5 AND v_j > 1 THEN
v_prnt_agr_cred_id := array_append(v_prnt_agr_cred_id, v_agr_cred_id[1]); -- ссылка на первый agr_cred в группе
ELSE
v_prnt_agr_cred_id := array_append(v_prnt_agr_cred_id, NULL);
END IF;

v_ignore_flag := array_append(v_ignore_flag, v_flag_options[1 + FLOOR(RANDOM() * 2)]);

-- Рассчитанные значения
v_own_calc_rub := array_append(v_own_calc_rub, (RANDOM() * 10000000)::NUMERIC(20,2));
v_old_calc_rub := array_append(v_old_calc_rub, (RANDOM() * 10000000)::NUMERIC(20,2));
v_agr_cred_coa_type_id := array_append(v_agr_cred_coa_type_id, (FLOOR(RANDOM() * 4) + 1)::TEXT);
v_own_calc_rub_prep := array_append(v_own_calc_rub_prep, (RANDOM() * 10000000)::NUMERIC(20,2));
v_calc_rub := array_append(v_calc_rub, (RANDOM() * 10000000)::NUMERIC(20,2));
v_calc_weight := array_append(v_calc_weight, (RANDOM())::NUMERIC(20,18));
v_prvsn_port_flag := array_append(v_prvsn_port_flag, v_flag_options[1 + FLOOR(RANDOM() * 2)]);
v_lowest_flag := array_append(v_lowest_flag, v_flag_options[1 + FLOOR(RANDOM() * 2)]);
v_agr_cred_type_cd := array_append(v_agr_cred_type_cd,
v_agr_cred_type_options[1 + FLOOR(RANDOM() * array_length(v_agr_cred_type_options, 1))]);
v_P_cnt := array_append(v_P_cnt, FLOOR(RANDOM() * 100)::NUMERIC);
v_J_cnt := array_append(v_J_cnt, FLOOR(RANDOM() * 100)::NUMERIC);
v_N_cnt := array_append(v_N_cnt, FLOOR(RANDOM() * 100)::NUMERIC);
v_info_system_id := array_append(v_info_system_id,
v_info_system_options[1 + FLOOR(RANDOM() * array_length(v_info_system_options, 1))]);

-- Close date (10% записей имеют дату закрытия)
IF RANDOM() > 0.9 THEN
v_agr_cred_close_dt := array_append(v_agr_cred_close_dt, v_current_start_dt + (FLOOR(RANDOM() * 180) + 30)::INTEGER);
ELSE
v_agr_cred_close_dt := array_append(v_agr_cred_close_dt, NULL);
END IF;

v_records_generated := v_records_generated + 1;
END LOOP;


-- Вставляем пакет, когда накопилось достаточно записей
IF array_length(v_agr_cred_id, 1) >= p_batch_size OR v_records_generated >= p_num_records THEN
INSERT INTO vt_d_agr_cred_coa_period_prep_bal 
(agr_cred_id, coa_id, coa_num, coa_n_id, agr_coa_role_id, coa_to_agrmnt_role_cd,meas_cd, start_dt, end_dt, crncy_id, crncy_cd, iso_crncy_cd, bal_amt, bal_rub,prnt_agr_cred_id, ignore_flag, own_calc_rub, old_calc_rub, agr_cred_coa_type_id,own_calc_rub_prep, calc_rub, calc_weight, prvsn_port_flag, lowest_flag,
agr_cred_type_cd, p_cnt, j_cnt, n_cnt, info_system_id, agr_cred_close_dt)
SELECT
unnest(v_agr_cred_id), unnest(v_coa_id), unnest(v_coa_num), unnest(v_coa_n_id),
unnest(v_agr_coa_role_id), unnest(v_coa_to_agrmnt_role_cd), unnest(v_meas_cd),
unnest(v_start_dt), unnest(v_end_dt), unnest(v_crncy_id), unnest(v_crncy_cd),
unnest(v_iso_crncy_cd), unnest(v_bal_amt), unnest(v_bal_rub), unnest(v_prnt_agr_cred_id),
unnest(v_ignore_flag), unnest(v_own_calc_rub), unnest(v_old_calc_rub),
unnest(v_agr_cred_coa_type_id), unnest(v_own_calc_rub_prep), unnest(v_calc_rub),
unnest(v_calc_weight), unnest(v_prvsn_port_flag), unnest(v_lowest_flag),
unnest(v_agr_cred_type_cd), unnest(v_P_cnt), unnest(v_J_cnt), unnest(v_N_cnt),
unnest(v_info_system_id), unnest(v_agr_cred_close_dt)
;


v_current_batch := v_current_batch + 1;
v_batch_count := v_batch_count + array_length(v_agr_cred_id, 1);

v_query := 'analyze vt_d_agr_cred_coa_period_prep_bal;';
    EXECUTE v_query;
	
-- Очищаем массивы
v_agr_cred_id := ARRAY[]::UUID[];
v_coa_id := ARRAY[]::UUID[];
v_coa_num := ARRAY[]::TEXT[];
v_coa_n_id := ARRAY[]::UUID[];
v_agr_coa_role_id := ARRAY[]::UUID[];
v_coa_to_agrmnt_role_cd := ARRAY[]::TEXT[];
v_meas_cd := ARRAY[]::TEXT[];
v_start_dt := ARRAY[]::DATE[];
v_end_dt := ARRAY[]::DATE[];
v_crncy_id := ARRAY[]::UUID[];
v_crncy_cd := ARRAY[]::TEXT[];
v_iso_crncy_cd := ARRAY[]::TEXT[];
v_bal_amt := ARRAY[]::NUMERIC[];
v_bal_rub := ARRAY[]::NUMERIC[];
v_prnt_agr_cred_id := ARRAY[]::UUID[];
v_ignore_flag := ARRAY[]::TEXT[];
v_own_calc_rub := ARRAY[]::NUMERIC[];
v_old_calc_rub := ARRAY[]::NUMERIC[];
v_agr_cred_coa_type_id := ARRAY[]::TEXT[];
v_own_calc_rub_prep := ARRAY[]::NUMERIC[];
v_calc_rub := ARRAY[]::NUMERIC[];
v_calc_weight := ARRAY[]::NUMERIC[];
v_prvsn_port_flag := ARRAY[]::TEXT[];
v_lowest_flag := ARRAY[]::TEXT[];
v_agr_cred_type_cd := ARRAY[]::TEXT[];
v_P_cnt := ARRAY[]::NUMERIC[];
v_J_cnt := ARRAY[]::NUMERIC[];
v_N_cnt := ARRAY[]::NUMERIC[];
v_info_system_id := ARRAY[]::SMALLINT[];
v_agr_cred_close_dt := ARRAY[]::DATE[];

RAISE NOTICE 'Batch % inserted (%, total: %)', v_current_batch, array_length(v_agr_cred_id, 1), v_batch_count;
END IF;
END LOOP;

v_query := 'INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal_'||in_workflow_run_id::text||' 
(agr_cred_id, coa_id, coa_num, coa_n_id, agr_coa_role_id, coa_to_agrmnt_role_cd,meas_cd, start_dt, end_dt, crncy_id, crncy_cd, iso_crncy_cd, bal_amt, bal_rub,prnt_agr_cred_id, ignore_flag, own_calc_rub, old_calc_rub, agr_cred_coa_type_id,own_calc_rub_prep, calc_rub, calc_weight, prvsn_port_flag, lowest_flag,
agr_cred_type_cd, p_cnt, j_cnt, n_cnt, info_system_id, agr_cred_close_dt)
select 
agr_cred_id, coa_id, coa_num, coa_n_id, agr_coa_role_id, coa_to_agrmnt_role_cd,meas_cd, start_dt, end_dt, crncy_id, crncy_cd, iso_crncy_cd, bal_amt, bal_rub,prnt_agr_cred_id, ignore_flag, own_calc_rub, old_calc_rub, agr_cred_coa_type_id,own_calc_rub_prep, calc_rub, calc_weight, prvsn_port_flag, lowest_flag,
agr_cred_type_cd, p_cnt, j_cnt, n_cnt, info_system_id, agr_cred_close_dt
from vt_d_agr_cred_coa_period_prep_bal;';
    EXECUTE v_query;
v_query := 'analyze s_grnplm_as_t_didsd_nnn_db_tmd.'||v_table_name||';';
    EXECUTE v_query;

v_end_time := clock_timestamp();
v_message := FORMAT('Successfully generated %s records in %s seconds (batches: %s)',
v_batch_count,
EXTRACT(EPOCH FROM (v_end_time - v_start_time))::NUMERIC(10,2),
v_current_batch);

RAISE NOTICE '%', v_message;

RETURN v_message;
END;
$$ LANGUAGE plpgsql;

-- Пример использования функции:
-- Создать 10000 записей, максимум 50 agr_cred на один coa_id, размер пакета 500
-- SELECT s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_coa_period_prep_bal(10000, 50, 500);

-- Для проверки количества сгенерированных записей:
-- SELECT COUNT(*) FROM s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal;

-- Для проверки групп (одинаковые coa_id с разными agr_cred_id):
-- SELECT coa_id, COUNT(DISTINCT agr_cred_id) as agr_count, MIN(start_dt), MAX(end_dt)
-- FROM s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal
-- GROUP BY coa_id
-- HAVING COUNT(DISTINCT agr_cred_id) > 1
-- ORDER BY agr_count DESC
-- LIMIT 20;