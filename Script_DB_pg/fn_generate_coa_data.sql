/*
Функция: fn_generate_coa_data
Назначение: Генерация тестовых данных для таблицы счетов (t_coa)
Параметры:
  in_row_count - количество записей для генерации

Алгоритм работы:
1. Проверка входного параметра на положительность
2. Создание временной таблицы vt_coa с такой же структурой как t_coa
3. Генерация первоначального набора данных (1000 записей):
   - Уникальный UUID для coa_id
   - Префиксы номеров счетов: 706 (20%), 707 (30%), 408 (50%)
   - Суффиксы номеров счетов из предопределенного списка
   - Случайные значения для других полей
4. Многократное тиражирование данных до достижения требуемого объема
5. Очистка целевой таблицы t_coa и вставка сгенерированных данных

Особенности:
- Использует функцию gen_random_uuid() для генерации уникальных идентификаторов
- Обеспечивает разнообразие данных для тестирования
- Поддерживает генерацию больших объемов данных через последовательное удвоение
*/
drop FUNCTION IF EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_coa_data(BIGINT,BIGINT);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_coa_data(in in_workflow_run_id int8,in in_row_count BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS 

--do
$$

DECLARE
--numb_test text  DEFAULT '1';
---in_row_count BIGINT DEFAULT 1000000;

v_coa_id uuid;
v_i int;
v_coa_num_prefix text;
v_coa_num_suffix text;
v_suffixes text[] := ARRAY['4860600', '2820403', '4730403', '4740102', '2840102','2880399', '4861199', '4780399', '2880354', '4780358','4780354', '2880358'];
v_total_lines int := 0;
sql_query text;
vt_tbl text default 'vt_coa_'||in_workflow_run_id::text;



BEGIN
-- Проверка входного параметра
IF in_row_count <= 0 THEN
RAISE EXCEPTION 'Параметр in_row_count должен быть положительным числом';
END IF;

sql_query = 'drop table if exists '||vt_tbl||';
			create temporary table '||vt_tbl||' (like s_grnplm_as_t_didsd_nnn_db_tmd.t_coa);';
execute sql_query;

-- Генерация указанного количества записей
FOR v_i IN 1..1000 LOOP
v_coa_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();
v_coa_num_prefix := CASE
                      WHEN random() < 0.2 THEN '706'
                      WHEN random() < 0.5 THEN '707'
                      ELSE '408'
                    END;
v_coa_num_suffix := v_suffixes[1 + floor(random() * array_length(v_suffixes, 1))];

sql_query = '
INSERT INTO '||vt_tbl||' 
(
gl_int_org_id,
coa_end_dt,
coa_id,
coa_name,
coa_num,
coa_start_dt,
coa_type_id,
crncy_id,
gl_main_acct_id,
pl_rpt_cd_id,
set_of_books_cd,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
del_dt
) VALUES (s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),''2026-12-31''::date,'''||v_coa_id||''',''Test COA Name ' || v_i||''', '||v_coa_num_prefix || LPAD(v_i::text, 10, '0') || v_coa_num_suffix||',''2026-01-01''::date,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
''-1'',
''N'',
''I'',
1000000 + '||v_i||',
1000 + '||(v_i % 100)||',
5000 + '||v_i||',
1210,
''000004'',
NULL
);';

--RAISE NOTICE '%', sql_query;

execute sql_query;

-- Вывод прогресса каждые 1000 записей (опционально)
IF v_i % 1000 = 0 THEN
RAISE NOTICE 'Сгенерировано % записей в t_coa', 1000;
END IF;
v_total_lines = v_i;
END LOOP;

-- тиражируем созданные записи
-- Последующие итерации чтения+вставки
WHILE v_total_lines < in_row_count  LOOP

sql_query = '
INSERT INTO '||vt_tbl||' (
gl_int_org_id,
coa_end_dt,
coa_id,
coa_name,
coa_num,
coa_start_dt,
coa_type_id,
crncy_id,
gl_main_acct_id,
pl_rpt_cd_id,
set_of_books_cd,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
del_dt
)
select
gl_int_org_id,
coa_end_dt,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
coa_name,
coa_num,
coa_start_dt,
coa_type_id,
crncy_id,
gl_main_acct_id,
pl_rpt_cd_id,
set_of_books_cd,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
del_dt
from '||vt_tbl||';';

--RAISE NOTICE '%', sql_query;
execute sql_query;

RAISE NOTICE 'Сгенерировано % записей в vt_coa', v_total_lines;
v_total_lines := v_total_lines * 2;
END LOOP;

--truncate table s_grnplm_as_t_didsd_nnn_db_tmd.t_coa;
sql_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.t_coa);';
execute sql_query;

sql_query = '
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_coa_'||in_workflow_run_id::text||' (
gl_int_org_id,
coa_end_dt,
coa_id,
coa_name,
coa_num,
coa_start_dt,
coa_type_id,
crncy_id,
gl_main_acct_id,
pl_rpt_cd_id,
set_of_books_cd,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
del_dt
)
select
gl_int_org_id,
coa_end_dt,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
coa_name,
coa_num,
coa_start_dt,
coa_type_id,
crncy_id,
gl_main_acct_id,
pl_rpt_cd_id,
set_of_books_cd,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
del_dt
from '||vt_tbl||'
LIMIT '||in_row_count||';
analyze s_grnplm_as_t_didsd_nnn_db_tmd.t_coa;';

--RAISE NOTICE '%', sql_query;
execute sql_query;

RAISE NOTICE 'Генерация данных в t_coa завершена. Всего записей: %', in_row_count;
END;
$$;

