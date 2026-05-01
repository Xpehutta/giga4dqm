-- Функция для генерации тестовых данных в таблицу d_agr_cred_coa с использованием generate_series
drop FUNCTION IF EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_coa(BIGINT);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.generate_agr_cred_coa(
in_workflow_run_id bigint,
p_num_records bigint DEFAULT 1000,  -- Общее количество записей для генерации
p_max_children_per_parent bigint DEFAULT 50,  -- Максимальное количество дочерних записей на одного родителя
p_batch_size bigint DEFAULT 100    -- Размер пакета для вставки
)
RETURNS TEXT AS $$
DECLARE
v_query text;
v_batch_count bigint := 0;
v_current_batch bigint := 0;
v_start_time TIMESTAMP;
v_end_time TIMESTAMP;
v_message TEXT;
v_parents_count bigint;
v_parent_ids UUID[];
v_offset bigint := 0;
v_batch_start bigint;
v_batch_end bigint;
v_sample_size bigint = least(p_num_records,200000);
v_total_lines bigint;
v_uuids_offset bigint := 10;
vt_tbl text default 'vt_agr_cred_coa';
BEGIN
v_start_time := clock_timestamp();

-- Логирование начала процесса
RAISE NOTICE 'Starting generation of % records (max % children per parent) ', p_num_records, p_max_children_per_parent;

v_query = 'drop table if exists '||vt_tbl||';
create temporary table '||vt_tbl||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa) distributed by(agr_id);
create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa) distributed by(agr_id);';

execute v_query;



-- Расчет количества родительских записей (50% от общего числа)
v_parents_count := CEIL(v_sample_size * 0.5)::INTEGER;

-- Генерация родительских ID
SELECT ARRAY_AGG(s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()::UUID)
INTO v_parent_ids
FROM generate_series(1, v_parents_count);

RAISE NOTICE 'Generated % parent records', v_parents_count;


-- Вставка данных пакетами
LOOP
v_batch_start := v_offset + 1;
v_batch_end := LEAST(v_offset + p_batch_size, v_sample_size);

IF v_batch_start > v_sample_size THEN
EXIT;
END IF;

-- Вставка пакета данных

INSERT INTO vt_agr_cred_coa (
agr_id, prnt_agr_cred_id, sl_coa_id, meas_cd, start_dt, end_dt,
registry_coa_stts_type_cd, gl_coa_flg, coa_num, coa_n_id,
crncy_id, crncy_cd, iso_crncy_cd, ignore_flag, registry_type_cd,
agr_cred_coa_type_id, info_system_id, gl_coa_id, eks_coa_id,
host_eks_coa_id, coa_name, coa_n_name, asset_liab_type_id,
prvsn_port_flag, registry_type_id
)
WITH
-- Генерация последовательности записей
record_seq AS (
SELECT
generate_series(v_batch_start, v_batch_end) as idx
),
-- Определение типа записи (родитель или ребенок)
record_types AS (
SELECT
idx,
CASE
WHEN idx <= v_parents_count THEN 'PARENT'
ELSE 'CHILD'
END as record_type,
-- Для детей определяем родителя
CASE
WHEN idx > v_parents_count THEN
v_parent_ids[1 + mod(idx - v_parents_count - 1, v_parents_count)]
ELSE NULL
END as parent_id
FROM record_seq
),
-- Константы для избежания переполнения
constants AS (
SELECT
1000000000000::BIGINT as base_eks,
9000000000::BIGINT as range_eks,
100000000000000::BIGINT as base_host,
987654321::BIGINT as multiplier,
1234567::BIGINT as eks_multiplier
)
-- Генерация основных данных
SELECT
-- agr_id
CASE
WHEN rt.record_type = 'PARENT' THEN v_parent_ids[rt.idx]
ELSE s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()
END as agr_id,
-- prnt_agr_cred_id
CASE
WHEN rt.record_type = 'PARENT' THEN v_parent_ids[rt.idx]
ELSE rt.parent_id
END as prnt_agr_cred_id,
-- Другие поля
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()as sl_coa_id,
-- meas_cd (используем детерминированный выбор на основе idx)
(ARRAY[
'AGRA_P025', 'AGRA_N003', 'AGRA_P024', 'AGRA_L001', 'AGRA_L032',
'AGRA_N026', 'AGRA_P022', 'AGRA_J023', 'AGRA_J003', 'AGRA_N007',
'AGRA_P051', 'AGRA_L003', 'AGRA_N005', 'AGRA_J051', 'AGRA_J029',
'AGRA_L007', 'AGRA_J007', 'AGRA_N029', 'AGRA_N051', 'AGRA_J026',
'AGRA_L022', 'AGRA_N023', 'AGRA_P001', 'AGRA_N022', 'AGRA_J001',
'AGRA_P002', 'AGRA_N001', 'AGRA_P005', 'AGRA_P003', 'AGRA_J002',
'AGRA_L024', 'AGRA_L049', 'AGRA_L050', 'AGRA_L034', 'AGRA_L026',
'AGRA_L039', 'AGRA_L029', 'AGRA_L036', 'AGRA_L051', 'AGRA_L005',
'AGRA_J022', 'AGRA_J005', 'AGRA_P007', 'AGRA_P021', 'AGRA_N002'
])[1 + mod(rt.idx, 45)] as meas_cd,
-- start_dt (от 1 до 3 лет назад)
(CURRENT_DATE - (30 + mod(rt.idx, 1095))::INTEGER)::DATE as start_dt,
-- end_dt (70% с '9999-12-31', 30% с будущей датой)
CASE
WHEN mod(rt.idx, 10) < 7 THEN '9999-12-31'::DATE
ELSE (CURRENT_DATE + (30 + mod(rt.idx, 365))::INTEGER)::DATE
END as end_dt,
-- registry_coa_stts_type_cd
(ARRAY['OPEN', 'TOBECLOSED'])[1 + mod(rt.idx, 2)] as registry_coa_stts_type_cd,
-- gl_coa_flg
(ARRAY['Y', 'N'])[1 + mod(rt.idx, 2)] as gl_coa_flg,
-- coa_num
(ARRAY[
'458188103', '474668106', '474258108', '454018108', '474418102',
'474668108', '474258107', '458208103', '474658106', '474668102',
'474258108', '474278101', '459218102', '474658104', '474658106',
'913178101', '474658109', '474668106', '474668102', '474658100',
'474438101', '458218109', '454158105', '474668106', '454168106',
'458188104', '454178109', '459188108', '474258101', '458208109',
'474438104', '409018109', '909078101', '474418108', '474438105',
'474528101', '474478103', '474418109', '913178107', '459128102',
'474658102', '459208107', '474258107', '474258100'
])[1 + mod(rt.idx, 45)] || LPAD(mod(rt.idx * 7, 1000000)::TEXT, 6, '0') as coa_num,
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()as coa_n_id,
-- crncy_id
'29fde458-b834-f3fa-26c5-b2da81c1a94d'::UUID as crncy_id,
-- crncy_cd
'810' as crncy_cd,
-- iso_crncy_cd
(ARRAY['RUR', 'USD', 'EUR'])[1 + mod(rt.idx, 3)] as iso_crncy_cd,
-- ignore_flag
(ARRAY['Y', 'N'])[1 + mod(rt.idx + rt.idx, 2)] as ignore_flag,
-- registry_type_cd
(ARRAY[
'RVP_COM2_OP_OVERDUE', 'CORR_RVP_PC_P', 'RVP_COM2_OP', 'СРОЧ_ССУД_ЗАДОЛЖ',
'ТРЕБ_ПРОЦЕНТ_КОММИС', 'CORR_SUBSIDY_P', 'RVP_COM2', 'CORR_RVP_COM2_OVERDUE_A',
'CORR_RVP_PC_A', 'CORR_RVP_US_P', 'RVP_NAVLIM', 'УЧ_ПРОЦ_КРЕД_БАЛ',
'CORR_RVP_PC_OVERDUE_P', 'CORR_RVP_NAVLIM_A', 'CORR_CORRECTVBS_A',
'ДОСТ_ЛИМ_ЗАДОЛЖ', 'CORR_RVP_US_A', 'CORR_CORRECTVBS_P', 'CORR_RVP_NAVLIM_P',
'CORR_SUBSIDY_A', 'УЧ_ПЛАТА_ЗА_ЛИМИТ_М9', 'CORR_RVP_COM2_OVERDUE_P',
'RVPS', 'CORR_RVP_COM2_P', 'CORR_RVPS_A', 'RVPS_OVERDUE', 'CORR_RVPS_P',
'RVP_PC_OVERDUE', 'RVP_PC', 'CORR_RVPS_OVERDUE_A', 'accred',
'ТРЕБ_ОПЕРАЦИОН_КОММИС_ПРОЦ_ТИП', 'УЧ_ПРОЦЕНТЫ_ГОС', 'EIR_ADJUSTMENT',
'ТРЕБ_ДОХОД_ПРОЦЕНТЫ_ГОС', 'НЕДОСТ_ЛИМ_ВЫДАЧ', 'ПРОСР_ПРОЦ_КРЕД_БАЛ',
'CORR_RVP_COM2_A', 'CORR_RVP_PC_OVERDUE_A', 'RVP_US', 'RVP_COM_KL'
])[1 + mod(rt.idx * 3, 45)] as registry_type_cd,
-- agr_cred_coa_type_id
(ARRAY['1', '4'])[1 + mod(rt.idx + 5, 2)] as agr_cred_coa_type_id,
-- info_system_id
(ARRAY[-1004, -1035])[1 + mod(rt.idx * 2, 2)] as info_system_id,
-- gl_coa_id
s_grnplm_as_t_didsd_nnn_db_tmd.gen_random_uuid()as gl_coa_id,
-- eks_coa_id (используем BIGINT для избежания переполнения)
(1000000000000::BIGINT + mod(rt.idx * 1234567, 9000000000)::BIGINT)::NUMERIC as eks_coa_id,
-- host_eks_coa_id
LPAD(mod(rt.idx * 987654321, 100000000000000)::TEXT, 14, '0') as host_eks_coa_id,
-- coa_name
'' as coa_name,
-- coa_n_name
'' as coa_n_name,
-- asset_liab_type_id
CASE
WHEN mod(rt.idx, 2) = 0 THEN '04632462-812f-4227-80b1-aaff0c474ec4'::UUID
ELSE 'beee32ab-dbda-4147-b9a9-21abb9c1ddea'::UUID
END as asset_liab_type_id,
-- prvsn_port_flag
(ARRAY['Y', 'N'])[1 + mod(rt.idx + 3, 2)] as prvsn_port_flag,
-- registry_type_id
'00000000-0000-0000-0000-0000fffffc11'::UUID as registry_type_id
FROM record_types rt
CROSS JOIN constants
ORDER BY rt.idx;

GET DIAGNOSTICS v_batch_count = ROW_COUNT;
v_current_batch := v_current_batch + 1;
v_offset := v_batch_end;

RAISE NOTICE 'Batch % inserted (%, total: %)', v_current_batch, v_batch_count, v_batch_end;

END LOOP;

v_total_lines = v_sample_size;
-- тиражируем созданные записи
-- Последующие итерации чтения+вставки
WHILE v_total_lines < p_num_records * 2 LOOP

INSERT INTO vt_agr_cred_coa (
agr_id
,prnt_agr_cred_id
,sl_coa_id
,meas_cd
,start_dt
,end_dt
,registry_coa_stts_type_cd
,gl_coa_flg
,coa_num
,coa_n_id
,crncy_id
,crncy_cd
,iso_crncy_cd
,ignore_flag
,registry_type_cd
,agr_cred_coa_type_id
,info_system_id
,gl_coa_id
,eks_coa_id
,host_eks_coa_id
,coa_name
,coa_n_name
,asset_liab_type_id
,prvsn_port_flag
,registry_type_id
)
select
md5((uuid_hash(agr_id) + v_uuids_offset)::text)::uuid
,md5((uuid_hash(prnt_agr_cred_id) + v_uuids_offset)::text)::uuid
,sl_coa_id
,meas_cd
,start_dt
,end_dt
,registry_coa_stts_type_cd
,gl_coa_flg
,coa_num
,coa_n_id
,crncy_id
,crncy_cd
,iso_crncy_cd
,ignore_flag
,registry_type_cd
,agr_cred_coa_type_id
,info_system_id
,gl_coa_id
,eks_coa_id
,host_eks_coa_id
,coa_name
,coa_n_name
,asset_liab_type_id
,prvsn_port_flag
,registry_type_id
from vt_agr_cred_coa;

v_uuids_offset = v_uuids_offset + 100;
RAISE NOTICE 'Сгенерировано % записей в vt_agr_cred_coa', v_total_lines;
v_total_lines := v_total_lines * 2;
END LOOP;

v_query = 'INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' (
agr_id
,prnt_agr_cred_id
,sl_coa_id
,meas_cd
,start_dt
,end_dt
,registry_coa_stts_type_cd
,gl_coa_flg
,coa_num
,coa_n_id
,crncy_id
,crncy_cd
,iso_crncy_cd
,ignore_flag
,registry_type_cd
,agr_cred_coa_type_id
,info_system_id
,gl_coa_id
,eks_coa_id
,host_eks_coa_id
,coa_name
,coa_n_name
,asset_liab_type_id
,prvsn_port_flag
,registry_type_id
)
 select agr_id
,prnt_agr_cred_id
,sl_coa_id
,meas_cd
,start_dt
,end_dt
,registry_coa_stts_type_cd
,gl_coa_flg
,coa_num
,coa_n_id
,crncy_id
,crncy_cd
,iso_crncy_cd
,ignore_flag
,registry_type_cd
,agr_cred_coa_type_id
,info_system_id
,gl_coa_id
,eks_coa_id
,host_eks_coa_id
,coa_name
,coa_n_name
,asset_liab_type_id
,prvsn_port_flag
,registry_type_id
from vt_agr_cred_coa;';

execute v_query;

v_end_time := clock_timestamp();
v_message := FORMAT('Successfully generated %s records in %s seconds (batches: %s)',
p_num_records,
EXTRACT(EPOCH FROM (v_end_time - v_start_time))::NUMERIC(10,2),
v_current_batch);

RAISE NOTICE '%', v_message;




RETURN v_message;
END;
$$ LANGUAGE plpgsql;


