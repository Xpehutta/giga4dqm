/*
Функция: fn_generate_je_line_data
Назначение: Генерация тестовых данных для таблицы проводок (t_je_line)
Параметры:
  in_row_count - количество записей для генерации

Алгоритм работы:
1. Проверка входного параметра на положительность
2. Получение списка подходящих coa_id из t_coa для использования в проводках
3. Получение списка coa_id для создания перекоса в данных
4. Создание временной таблицы vt_je_line с такой же структурой как t_je_line
5. Генерация первоначального набора данных (1000 записей):
   - Случайный выбор coa_id из существующих или генерация несуществующего
   - Случайный выбор je_line_cred_ind (Y - 30%, N - 70%)
   - Логика выбора src_system_type_id:
     * Для кредитовых записей - любой UUID
     * С вероятностью 20% - специальные UUID из списка
     * Иначе - UUID не из исключенного списка
   - Случайные суммы проводок и даты в диапазоне
6. Многократное тиражирование данных до достижения требуемого объема
7. Очистка целевой таблицы t_je_line и вставка сгенерированных данных

Особенности:
- Создает перекос в данных каждые 3 проводки
- Поддерживает генерацию больших объемов данных через последовательное удвоение
- Обеспечивает разнообразие данных для тестирования различных сценариев
- Включает логику для тестирования условий фильтрации
*/
drop FUNCTION IF EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_je_line_data(int8,BIGINT);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_generate_je_line_data(in in_workflow_run_id int8,in in_row_count BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
table_name TEXT;
query TEXT;
v_je_header_id uuid;
v_je_line_coa_id uuid;
v_je_line_corr_coa_id uuid;
v_src_system_type_id uuid;
v_je_line_cred_ind text;
v_i int;
v_j int;
v_lines_per_header int;
v_total_lines int := 0;
v_coa_ids uuid[];
v_coa_ids_for_skew uuid[];
v_excluded_uuids uuid[] := ARRAY[
'd0e4a790-25f3-5f88-1c1c-214004c0d4ae',
'0a1d09cc-bee7-d908-2370-0a3cbb6578e7',
'1f2d41d2-b7a8-f08c-65b4-d5f7212e6358',
'e9fa5b05-e3f6-d3bc-5bab-7687f67bcb06',
'25dc0ea1-e64f-f5e4-3000-1edd696094d8',
'3ce5886d-d247-d4cf-ace2-134722d78b5a',
'cd6f831a-9512-6be3-0eec-0ff318dcb974',
'7689e4b3-0bc6-bcc8-3c33-802ecb62b782',
'c8d27015-6719-4c0b-8b81-dcf432787538',
'c08cd80a-6ef6-a1d0-be6d-770174b97717',
'52400026-01ad-0406-6c4e-69e7b407f342',
'7cea101d-085d-8380-7c71-44213e74e973',
'f63e07f2-f532-6048-4fc1-80949571163c',
'be520b9e-c375-a138-ae1b-18be6c55db2b',
'fb1cf1d3-a409-6450-dd5c-fd448932673b',
'18a95624-a4f1-2620-d711-6a65c5d525f8',
'5595dd5f-d6e4-c28b-b902-3c13648cfc3e',
'ca6d697d-8d6a-e0ca-45e4-2838df2e0f7b'
];
v_special_uuids uuid[] := ARRAY[
'be520b9e-c375-a138-ae1b-18be6c55db2b',
'0a1d09cc-bee7-d908-2370-0a3cbb6578e7'
];

vt_tbl text default 'vt_je_line_'||in_workflow_run_id::text;
sql_query text;

BEGIN
-- Проверка входного параметра
IF in_row_count <= 0 THEN
RAISE EXCEPTION 'Параметр in_row_count должен быть положительным числом';
END IF;

-- Получаем существующие coa_id из t_coa

    table_name := 't_coa_' || in_workflow_run_id;
    
    -- Формируем динамический запрос
    query := format('
        SELECT ARRAY_AGG(coa_id) 
        FROM (
            SELECT coa_id
            FROM %I.%I
            WHERE deleted_flag = ''N''
                AND info_system_inst_cd = ''000004''
                AND substr(coa_num, 1, 3) IN (''706'', ''707'')
                AND substr(coa_num, 14, 7) = ANY (ARRAY[''4860600'',''2820403'',''4730403'',''4740102'',
                                                     ''2840102'',''2880399'',''4861199'',''4780399'',
                                                     ''2880354'',''4780358'',''4780354'',''2880358''])
            LIMIT 1000
        ) t
    ', 's_grnplm_as_t_didsd_nnn_db_tmd', table_name);
    
    -- Выполняем запрос
    EXECUTE query INTO v_coa_ids;

-- отберем случайные 10 счетов для перекоса в данных
 query := format('
        SELECT ARRAY_AGG(coa_id) 
        FROM (
            SELECT coa_id
            FROM %I.%I
            WHERE deleted_flag = ''N''
                AND info_system_inst_cd = ''000004''
                AND substr(coa_num, 1, 3) NOT IN (''706'', ''707'')
            LIMIT 10
        ) t
    ', 's_grnplm_as_t_didsd_nnn_db_tmd', table_name);
    
    -- Выполняем запрос
    EXECUTE query INTO v_coa_ids_for_skew;

-- Проверка, что найдены coa_id
IF v_coa_ids IS NULL OR array_length(v_coa_ids, 1) = 0 THEN
RAISE EXCEPTION 'Не найдены подходящие записи в t_coa. Сначала выполните fn_generate_coa_data()';
END IF;

sql_query = 'drop table if exists '||vt_tbl||';
create temporary table '||vt_tbl||' (like s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line);';
execute sql_query;

RAISE NOTICE 'Найдено % coa_id для использования', array_length(v_coa_ids, 1);

-- Генерируем заголовки и строки пока не достигнем нужного количества записей
v_i := 1;
WHILE v_total_lines < 1000 LOOP
v_je_header_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();

-- Определяем количество строк для текущего заголовка (от 1 до 3)
v_lines_per_header := 1 + floor(random() * 3);

-- Корректируем, чтобы не превысить общее количество
IF v_total_lines + v_lines_per_header > 1000 THEN
v_lines_per_header := 1000 - v_total_lines;
END IF;

-- Генерируем строки для текущего заголовка
FOR v_j IN 1..v_lines_per_header LOOP
-- Выбираем случайные coa_id из существующих (или NULL для проверки условий)
IF random() < 0.7 THEN
  v_je_line_coa_id := v_coa_ids[1 + floor(random() * array_length(v_coa_ids, 1))];
ELSE
  v_je_line_coa_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(); -- Несуществующий coa_id
END IF;
IF random() < 0.6 THEN
  v_je_line_corr_coa_id := v_coa_ids[1 + floor(random() * array_length(v_coa_ids, 1))];
ELSE
  v_je_line_corr_coa_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(); -- Несуществующий coa_id
END IF;

if  v_total_lines % 3 = 0 then
v_je_line_coa_id := v_coa_ids_for_skew[1 + floor(random() * array_length(v_coa_ids_for_skew, 1))];
--raise notice 'skew acc -> %',v_je_line_coa_id;
end if;

-- Определяем тип записи для выполнения условий фильтрации
v_je_line_cred_ind := CASE WHEN random() < 0.3 THEN 'Y' ELSE 'N' END;

-- Выбираем src_system_type_id в зависимости от условий
IF v_je_line_cred_ind = 'Y' THEN
-- Для кредитовых записей подойдет любой uuid
v_src_system_type_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();
ELSIF random() < 0.2 THEN
-- Специальные uuid для проверки условия с coa
v_src_system_type_id := v_special_uuids[1 + floor(random() * 2)];
ELSE
-- UUID не из исключенного списка
LOOP
v_src_system_type_id := s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid();
-- сделаем перекос по счетам как в распределении на пром на 10 счетов приходится 30% проводок
EXIT WHEN NOT (v_src_system_type_id = ANY(v_excluded_uuids));
END LOOP;
END IF;


sql_query = '
INSERT INTO '||vt_tbl||'  
(
int_org_id,
je_header_id,
je_header_val_dt,
je_line_cat_id,
je_line_coa_id,
je_line_corr_coa_id,
je_line_cred_ind,
je_line_local_amt,
je_line_trans_amt,
je_type_id,
optn_id,
registry_id,
reg_bank_cd,
set_of_books_cd,
je_header_desc,
host_je_header_rel_id,
je_header_create_dt,
pymnt_doc_id,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
src_system_type_id
) VALUES (s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),'''||v_je_header_id||''',current_date + (floor(random() * 100) - 65)::int, -- даты в диапазоне
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),'''||v_je_line_coa_id||''','''||v_je_line_corr_coa_id||''','''||v_je_line_cred_ind||''',(random() * 1000000)::numeric(38,2),(random() * 1000000)::numeric(38,2),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
''-1'',
CASE WHEN random() < 0.7 THEN ''СБ_РСБУ'' ELSE ''-1'' END,
''Test JE Header Description ' || v_i || '-' || v_j||''',
''HOST_REL_ID_' || v_i || '_' || v_j||''',
''2026-02-01''::date,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
''N'',  -- deleted_flag = ''N'' обязательно
CASE WHEN random() < 0.7 THEN ''I'' ELSE ''U'' END,
7000000 + '||v_i||',
1000000 + ('||v_i||' % 100),
2000 + '||v_i||',
1210,
''000004'','''||v_src_system_type_id||''');';


--RAISE NOTICE 'Сгенерировано % записей в vt_je_line', sql_query;
--RETURN;
execute sql_query;

v_total_lines := v_total_lines + 1;
END LOOP;

v_i := v_i + 1;

-- Вывод прогресса каждые 1000 записей
IF v_total_lines % 1000 = 0 THEN
RAISE NOTICE 'Сгенерировано % записей в vt_je_line', v_total_lines;
END IF;
END LOOP;

RAISE NOTICE 'Генерация данных в vt_je_line завершена. Всего записей: %', v_total_lines;
-- тиражируем созданные записи
-- Последующие итерации чтения+вставки
WHILE v_total_lines < in_row_count  LOOP

sql_query = 'INSERT INTO '||vt_tbl||'  (
int_org_id,
je_header_id,
je_header_val_dt,
je_line_cat_id,
je_line_coa_id,
je_line_corr_coa_id,
je_line_cred_ind,
je_line_local_amt,
je_line_trans_amt,
je_type_id,
optn_id,
registry_id,
reg_bank_cd,
set_of_books_cd,
je_header_desc,
host_je_header_rel_id,
je_header_create_dt,
pymnt_doc_id,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
src_system_type_id
)
select
int_org_id,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
je_header_val_dt,
je_line_cat_id,
je_line_coa_id,
je_line_corr_coa_id,
je_line_cred_ind,
je_line_local_amt,
je_line_trans_amt,
je_type_id,
optn_id,
registry_id,
reg_bank_cd,
set_of_books_cd,
je_header_desc,
host_je_header_rel_id,
je_header_create_dt,
pymnt_doc_id,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
src_system_type_id
from '||vt_tbl||';';
execute sql_query;

RAISE NOTICE 'Сгенерировано % записей в vt_je_line', v_total_lines;
v_total_lines := v_total_lines * 2;
END LOOP;

sql_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line);';
execute sql_query;


sql_query = 'INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_workflow_run_id||'(
int_org_id,
je_header_id,
je_header_val_dt,
je_line_cat_id,
je_line_coa_id,
je_line_corr_coa_id,
je_line_cred_ind,
je_line_local_amt,
je_line_trans_amt,
je_type_id,
optn_id,
registry_id,
reg_bank_cd,
set_of_books_cd,
je_header_desc,
host_je_header_rel_id,
je_header_create_dt,
pymnt_doc_id,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
src_system_type_id
)
select
int_org_id,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid(),
je_header_val_dt,
je_line_cat_id,
je_line_coa_id,
je_line_corr_coa_id,
je_line_cred_ind,
je_line_local_amt,
je_line_trans_amt,
je_type_id,
optn_id,
registry_id,
reg_bank_cd,
set_of_books_cd,
je_header_desc,
host_je_header_rel_id,
je_header_create_dt,
pymnt_doc_id,
deleted_flag,
action_cd,
workflow_run_id,
session_inst_id,
input_file_id,
info_system_id,
info_system_inst_cd,
src_system_type_id
from '||vt_tbl||'
LIMIT '||in_row_count||';
analyze s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line_'||in_workflow_run_id||';';
execute sql_query;

end;
$$;




