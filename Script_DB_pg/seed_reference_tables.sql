TRUNCATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param;
TRUNCATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type;
TRUNCATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_settings;
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'AGRMNT_INI_DT', '2018-01-01', 'Глубина хранения договоров и счетов в витрине, строка в формате "ГГГГ-ММ-ДД"');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'APP_ID', 'gpbvd818-bvd-449f-b5bf-c03da4e1459b', 'app_id for kibana logging');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'T_JE_LINE_IDFN_PARTITION_TYPE', '2', 'Переключение алгоритма работы с T_JE_LINE_IDFN: 1- партиции по дате нет, 2 - выполнено партицирование по дате и таблица переинициализирована');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'COLLECT_STAT_DOW', '2,7', 'Дни недели, по которым собирается статистика крупных таблиц. Номер дня от 1 до 7, либо номера дней в неделе через запятую. Пример значения: 3,7 .');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PERIOD_END_DT', '2024-08-26', 'Дата окончания периода загрузки PYMNT_DOC и других таблиц фактов, строка в формате "ГГГГ-ММ-ДД"');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_INI_DT', '2024-08-01', 'Сценарий PLCOMISS. Минимальная дата проводок, начиная с которой считаем новые шаги сценария PLCOMISS. Строка в формате "ГГГГ-ММ-ДД".');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'INCREMENT_FLAG', '1', 'Признак инкрементальной/архивной загрузки таблиц витрины. 0 - архивная загрузка, 1 - инкрементальная загрузка (штатный режим).');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PYMNT_DOC_INCREMENT_FLAG', '1', 'Признак инкрементальной/архивной загрузки PYMNT_DOC и других таблиц фактов. 0 - архивная загрузка за период PERIOD_START_DT-PERIOD_END_DT, 1 - инкрементальная загрузка (штатный режим).');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PERIOD_START_DT', '2024-09-27', 'Дата начала периода загрузки PYMNT_DOC и других таблиц фактов, строка в формате "ГГГГ-ММ-ДД"');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES ('S_GRNPLM_AS_T_DIDSD_SBT_LOAD', 'wf_C_IEDW_999_B', null, null, null, 'TREE-R-GRAPH', 'TRUE', 'Parameter for graph mode.');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'SRC_SYSTEM_EXCL_LIST', 'ТКП,ВСПЗ,КРФЛ,ТКП_ДП,EKP,ЦОД,ЧЕЧ,ЖИЛПРО,ЗР,ПЕРЕВОДЫ,АФЛ,КАССПОД,ВиС,СНУиЛ,СВКО,ИПФЛ,СЕРТ,ИЗК,ВЦБ,ЕКП,ЕБП,СС,УСА,SBE,КАССА,ПЛАТЕЖИ,ДЕПО', 'Список кодов фабрик, исключаемых из расчета pymnt_doc');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PYMNT_DOC_CALC_DT_HWM', '2025-09-29', 'Верхняя граница последнего расчета PYMNT_DOC, PYMNT_DOC_SL, ACCNT_DOC, ACCNT_DOC_SL');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'INI_DT', '2024-01-01', 'Начальная дата хранения фактов в витрине, строка в формате "ГГГГ-ММ-ДД"');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_USE_AUTO_DATES', '0', 'Сценарий PLCOMISS. Признак инкрементальной/архивной загрузки
0 - архивная загрузка за период PLCOMISS_START_DT - PLCOMISS_END_DT
1 - инкрементальная загрузка (штатный режим) за период
current_date-(минус) PLCOMISS_START_SHIFT_DAYS - current_date-1');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_START_DT', '2026-01-01', 'Сценарий PLCOMISS. Дата начала периода архивной загрузки, строка в формате "ГГГГ-ММ-ДД".');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_END_DT', '2026-01-08', 'Сценарий PLCOMISS. Дата окончания периода архивной загрузки, строка в формате "ГГГГ-ММ-ДД".');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_START_SHIFT_DAYS', '11', 'Сценарий PLCOMISS. Расчёт дат по алгоритму, смещение начала периода расчёта от текущей даты в днях.');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PLCOMISS_WORK_DAYS', '4', 'Сценарий PLCOMISS. Номер рабочего дня с начала месяца, в который следует запускать расчёт за предыдущий месяц. Целое число от 0 до 23 (0 = не выполнять расчёт за предыдущий месяц).');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'PYMNT_DOC_DEPTH_DAYS', '10', 'Глубина инкрементального расчета фактов в днях (строка состоящая из цифр)');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'REVENUE_SUBTYPE_FILTER_SOURCES', 'ЕКП,ТКП', 'Для этих фабрик нужно включить полупроводки, по счетам, указанным в настройке REVENUE_SUBTYPE_CODE');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param("folder_name", "workflow_name", "workflow_inst_name", "worklet_inst_name", "session_name", "param_name", "param_val", "param_desc") VALUES (null, 'wf_C_IEDW_999_B', null, null, null, 'REVENUE_SUBTYPE_CODE', '4860600,2820403,4730403,4740102,2840102,2880399,4861199,4780399,2880354,4780358,4780354,2880358', 'Список кодов подвида доходов/асходов (символы с 14 по 20 в номер счета) полупроводки по которым необходимо отбирать в витрину ');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('1f2d41d2-b7a8-f08c-65b4-d5f7212e6358'::uuid,'ТКП_ДП',NULL,'N','I',15752374,1000570,4405,1210,'000004'),
('32590a4f-e3d8-ffdd-6efe-59591ae97ae9'::uuid,'БРОК',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('0b467dbb-02bd-ce99-07ed-dd07d8edeb93'::uuid,'МСФО_КЮЛ',NULL,'N','I',16998225,1000570,25808,1210,'000004'),
('0a1d09cc-bee7-d908-2370-0a3cbb6578e7'::uuid,'ЕКП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('18a95624-a4f1-2620-d711-6a65c5d525f8'::uuid,'ПЕРЕВОДЫ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('7689e4b3-0bc6-bcc8-3c33-802ecb62b782'::uuid,'ВСПЗ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('55b22279-329a-799d-d642-bfe1e6afe692'::uuid,'РЦРУБЛОРОНОСТРО',NULL,'N','I',15800073,600580,5012,1210,'000004'),
('768ff89c-52e4-3952-b2e1-0b632d6f88c8'::uuid,'УСА',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('3393d34c-1b97-2090-d7c6-4fd8e421043d'::uuid,'ЦФП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('9d2329dd-ed58-0541-7b92-0d31df60f6e4'::uuid,'УВЗ',NULL,'N','I',16677717,1000570,17778,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('92b211b9-d168-387e-dfee-486be4c23126'::uuid,'ФКТГ',NULL,'N','I',18151208,600580,50600,1210,'000004'),
('90a88fee-33aa-99dc-f321-5733d03d2800'::uuid,'УДКЗ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('b4a84eca-c6f9-4893-61fd-9169b0c0deb0'::uuid,'УВДОНП',NULL,'N','I',16251020,600580,10316,1210,'000004'),
('ec559251-df9f-2f60-6e32-86819e3f221c'::uuid,'ЭиИ',NULL,'N','I',15913504,600580,6445,1210,'000004'),
('d0e4a790-25f3-5f88-1c1c-214004c0d4ae'::uuid,'АФЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('78275a89-0e48-af74-66b9-341e68bf0328'::uuid,'ДММ',NULL,'N','I',16401872,600580,12013,1210,'000004'),
('12862fb0-64d2-5820-6b5e-9cd594f42cb6'::uuid,'EKP',NULL,'N','I',17462691,600580,35185,1210,'000004'),
('af044056-e5ba-a7f1-27c9-df8607a80f06'::uuid,'EKS',NULL,'N','I',16886126,1000570,23138,1210,'000004'),
('375cb2da-fa3e-5fdd-0447-245b686d2acf'::uuid,'ТРАНП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('5f1c2734-d9a0-891c-65e7-d71b2791f738'::uuid,'SberTips',NULL,'N','I',16401872,600580,12013,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('2066d261-f224-40d1-1c6e-f5a187293c37'::uuid,'ПАПИРУС',NULL,'N','I',17744888,600580,40730,1210,'000004'),
('74d41e54-cfb4-5817-bf69-b96bf8c6bc61'::uuid,'КАССПОД',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('2b2c3235-8f01-5da5-6b2b-5cae385f9bf6'::uuid,'COD',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('dcda3a32-2758-dffe-c8af-c478c1b9b1b7'::uuid,'Caldera',NULL,'N','I',17454876,600580,35019,1210,'000004'),
('ca6d697d-8d6a-e0ca-45e4-2838df2e0f7b'::uuid,'ЕБП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('bb8aa44b-9705-9de3-d1ce-c49ea889f5a9'::uuid,'РПФИ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('0c792501-0c12-b024-76e2-67501c9a70b8'::uuid,'ДСЖ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('ea527671-0083-318b-619c-b88c54ebe744'::uuid,'НИРО',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('098fcc62-dae9-6cad-2284-1c5cd7cd4066'::uuid,'ЦФВ',NULL,'N','I',16332830,600580,11249,1210,'000004'),
('7615e116-970c-da4b-517d-2ac2595693a2'::uuid,'ИНКАС',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('3aad12b7-3d51-99eb-2946-f3a852d896ac'::uuid,'РМФ',NULL,'N','I',16265474,600580,10466,1210,'000004'),
('e9fa5b05-e3f6-d3bc-5bab-7687f67bcb06'::uuid,'КАССА',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('d7f01153-23ab-6da4-7e9f-a00416d42f8c'::uuid,'SAPHCM',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('33eaba9e-255b-5944-23e4-9037199713b0'::uuid,'UDKZ',NULL,'N','I',18171701,1000570,51231,1210,'000004'),
('adc8170e-d544-ee53-3dac-e6f7a66758ef'::uuid,'ПСиВРД',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('fb1cf1d3-a409-6450-dd5c-fd448932673b'::uuid,'СС',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('0490b260-3922-5d23-c516-020c651bcf2f'::uuid,'САМО',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('ba9af067-2d1b-2616-cf3c-51bd6d547814'::uuid,'ЭКВАЙРИНГ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('0e2e605f-a4f9-65ff-ef25-750a8b9be430'::uuid,'УВХД',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('4bbbb827-53d3-e673-5e61-830dfdbf314a'::uuid,'ЗЛГ',NULL,'N','I',16139216,600580,9079,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('745a0e72-6efe-5c19-395d-b43d1340f727'::uuid,'УФП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('97653b73-782f-3204-d473-3b4e473e3528'::uuid,'КИЦ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('a5de7e7c-efbe-3a89-cee8-18ada9c64c87'::uuid,'АЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('214b5579-ddc4-56a2-27c3-dd972e6a53b4'::uuid,'РООП_ВЭД',NULL,'N','I',16886126,600580,23134,1210,'000004'),
('79f48f82-4706-6831-4fbc-1bafb2939a4c'::uuid,'ЦФА',NULL,'N','I',16277741,1000570,10620,1210,'000004'),
('478330a7-2319-8919-c070-15e2dfa97b94'::uuid,'РКОЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('ba6bd8c4-0fdb-de80-7923-9a994c9645d0'::uuid,'RCR',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('724b2935-8398-7063-a81c-8e06613d1644'::uuid,'Г2БК',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('a12e2ff6-20ae-838f-2991-051a5117935e'::uuid,'РРВ',NULL,'N','I',16614354,1000570,16122,1210,'000004'),
('3ce5886d-d247-d4cf-ace2-134722d78b5a'::uuid,'СНУиЛ',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('2e897344-cdc0-6605-3e04-4ac493cb5094'::uuid,'НАСЛЕД',NULL,'N','I',15865179,600580,5812,1210,'000004'),
('5f040eef-077a-f2e4-4f59-6fdff694aad8'::uuid,'КОЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('43630e26-2fa5-d23e-485e-2db3ef7ab024'::uuid,'PLAT',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('cc02867f-6a91-0b96-65bb-1efb5c4c8d4c'::uuid,'СЕРТ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('8f4ea71d-6d58-d67b-8335-a6e5360e7c58'::uuid,'НЦБ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('c08cd80a-6ef6-a1d0-be6d-770174b97717'::uuid,'ЦОД',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('ed8a6240-7b98-b0fd-0af5-f54d080fd51a'::uuid,'РБР',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('d12efdb8-6b42-732b-fb35-d01f00545546'::uuid,'ДВД',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('62520b91-616a-6d8a-a159-9ecafafb41ee'::uuid,'УДиЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('4e797856-4ac9-ce41-abe7-1470275180e5'::uuid,'УВДОКОМИС',NULL,'N','I',16066469,600580,8229,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('6ce00dac-d3b3-3dcd-a3ed-0bf2c6e7c1fc'::uuid,'ДЮЛ_СТР',NULL,'N','I',16135301,600580,9029,1210,'000004'),
('727c5554-6682-3615-763a-01d8b35d1a7d'::uuid,'ФСКК',NULL,'N','I',17002057,1000570,25883,1210,'000004'),
('3f1004d3-9715-7958-209a-74d4653a3679'::uuid,'КОНВФЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('76929496-bc39-61ea-bf8f-e6791da0b8e4'::uuid,'БИЛЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('5c73f718-2b9c-0f5f-66ef-0c68c0ad7f80'::uuid,'КРЮЛ',NULL,'N','I',16570915,600580,15091,1210,'000004'),
('51b1e437-2bf7-35e1-7639-d4d64f1a7c6a'::uuid,'SPS',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('c3457126-0d80-49c4-d3e0-6139ae66b44d'::uuid,'SBERERP',NULL,'N','I',17305174,600580,31957,1210,'000004'),
('10bdab0d-a353-881b-1b27-8bd264c39aea'::uuid,'АГР',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('faa92363-db24-ce78-a4c8-0ff2d732db7e'::uuid,'ФПЭ',NULL,'N','I',16153420,600580,9229,1210,'000004'),
('490992d1-1386-a7c4-7e40-8cea06498f78'::uuid,'УчР',NULL,'N','I',15773176,600580,4629,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('f0fb48c1-2ffd-c8dd-a701-547937fde78c'::uuid,'ДЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('105ddeed-fe25-1742-79f0-ba39f64b7fdc'::uuid,'ГБК',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('c8d27015-6719-4c0b-8b81-dcf432787538'::uuid,'СВКО',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('8dc2ac0b-807d-0680-4363-a0dbfc16c028'::uuid,'ZR',NULL,'N','I',18118342,1000570,49613,1210,'000004'),
('2b5ee00c-1ae8-caf2-6080-d92aa2030a45'::uuid,'РЦВАЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('be520b9e-c375-a138-ae1b-18be6c55db2b'::uuid,'ТКП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('b329e997-7175-1fe1-1b87-190bd9d9f23a'::uuid,'РЦРУБ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('cb490761-d9d8-8335-160c-43d22e72e6d0'::uuid,'ВП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('cd6f831a-9512-6be3-0eec-0ff318dcb974'::uuid,'ПЛАТЕЖИ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('7cea101d-085d-8380-7c71-44213e74e973'::uuid,'ЖИЛПРО',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('08495d47-e66c-2a24-0499-4718a8c42cf2'::uuid,'ДО',NULL,'N','I',18171701,1000570,51231,1210,'000004'),
('c806b5e3-8594-a11a-5d75-02de32a44b34'::uuid,'CI05414732',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('7c75cb15-73c7-5c12-a771-ee580864ad52'::uuid,'РКО',NULL,'N','I',16990023,1000570,25642,1210,'000004'),
('d3c5bef6-a0c1-0bd4-566a-720355c174b4'::uuid,'КДК',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('48d78cb1-e677-459d-ddab-95f185dd5359'::uuid,'КОМП',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('c21c619d-b623-dc3b-849e-6e671b56993c'::uuid,'ПУЛЬС',NULL,'N','I',17942525,600580,45120,1210,'000004'),
('f63e07f2-f532-6048-4fc1-80949571163c'::uuid,'ДЕПО',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('345ef0fa-cb59-fd03-4568-0269b7440fe1'::uuid,'ДПП',NULL,'N','I',16037328,1000570,7883,1210,'000004'),
('80a46a53-ff72-7f7d-6468-6c72c9809f92'::uuid,'ЭСКРОУ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('2a68be53-946c-253b-004e-319be85b11ca'::uuid,'НСиР',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('b69476d1-8821-9795-89ff-6c10e5fad637'::uuid,'PEREV',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('3c2571f4-7ea8-6374-21bc-29493203ead6'::uuid,'UVDOCOMMON',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('304422af-1037-9df1-5649-3a59709c5c9d'::uuid,'АГР_СБ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('921c401e-0c6b-b82a-ede2-ff17d77753fb'::uuid,'КОНВЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('2f8593df-08b2-a164-90ba-40f0635aa030'::uuid,'УДКЗ. Возврат в рамках комиссии Юл.30',NULL,'N','I',16881968,600580,23017,1210,'000004'),
('8e4b0bf8-8894-edeb-698c-16a3ef0894e6'::uuid,'СБП_В2В',NULL,'N','I',16552296,600580,14704,1210,'000004'),
('5595dd5f-d6e4-c28b-b902-3c13648cfc3e'::uuid,'ИПФЛ',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('f8b39077-de4e-0710-ef51-1a0832f45337'::uuid,'DO',NULL,'N','I',18159610,1000570,50856,1210,'000004'),
('52400026-01ad-0406-6c4e-69e7b407f342'::uuid,'SBE',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('25dc0ea1-e64f-f5e4-3000-1edd696094d8'::uuid,'ЗР',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (src_system_type_id,src_system_type_cd,src_system_type_name,deleted_flag,action_cd,workflow_run_id,session_inst_id,input_file_id,info_system_id,info_system_inst_cd) VALUES
('978c5544-56b9-050e-b3a2-3e0971ed8542'::uuid,'LCR',NULL,'N','I',18109873,1000570,49383,1210,'000004'),
('d0074b41-ba42-0dbc-3015-cdd3de097a48'::uuid,'РСР',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('771f2727-130f-af60-421b-fdbcbad169ad'::uuid,'МСК',NULL,'N','I',15752374,600580,4401,1210,'000004'),
('b6f80ef2-b565-8355-31ce-3b403d4d56bc'::uuid,'КЮЛ',NULL,'N','I',15752374,600580,4401,1210,'000004');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('not_active_addendum_stts_type', 'DELETED', 'd_addendum_tree');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ИМПОРТ_КОММИС_КВУ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_ДОСТ_ЛИМ_ВЫДАЧ_УМЕНЬШ_ЛИМ_ВЫДАЧА_П_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_ЛИМИТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ДОСРОЧ_ВОЗВР_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ВЕДЕНИЕ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УВЕЛИЧ_ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ВЫНОС_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_red_on_prvsn_flag', 'СПИС_ССУД_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ОТКР_ЛИМИТ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ВЫНУЖ_ОТВ_СР', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('agr_cred_esg_type_code', 'GreenESGLending', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP603', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'RST141', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПРОЦ_КАП_ОТЛОЖ_ПРОЦ_КРЕД', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('tariff_interest_period', 'INTEREST_ANNUAL_OF_TARIFF', 'v_tarif_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('grntee_pymnt_optn_type', 'НЕУЧ_ПЛАТА_ВЫНУЖ_ОТВ_СР_ГАРАН', 'v_grntee_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ПРОЦ_КРЕД_БАЛ_БЕЗ_ПЛАНА_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ССУД_ЗАДОЛЖ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L034', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ИЗМ_УСЛ_АБС_ОПЕР_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ЛИМИТ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_СТРАХ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ОТЛОЖ_ПРОЦ_КРЕД_БАЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ЗАДОЛЖ_УВЕЛИЧ_ЛИМ_ВЫДАЧА_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УМЕНЬШ_УЧ_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС_ВЫНОС_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ЗАДОЛЖ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP1570', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP26', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f303_restruct_code', 'F303_RESTRUCT', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP1598', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP1221', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_issue_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_РУЧ_КОРРЕКТ_ЗАДОЛЖ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ПРОЦ_КРЕД_БАЛ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_КОМИСС_ГАРАНТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'SPEC_COND_CRED', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'GreenESGLending', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ВЫДАЧ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ПРОЦ_КРЕД_БАЛ_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ВЫНУЖ_ОТВ_СР', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_НЕИСП_ОБЕСП_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УМЕНЬШ_ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_ИЗМЕН_УСЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ДОСРОЧ_ВОЗВР', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УВЕЛИЧ_ПРОСР_ССУД_ЗАДОЛЖ_ПОГАШЕНИЕ_П_СТОРНО_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ЛИМ_МУЛЬТИВАЛ_КР_ЛИН', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_РЕСУРС_ПЕРИОД_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПРОЦ_КРЕД_БАЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f26_prod_code', 'CRED_TYPE_ADD', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('limit_plan_pymnt_optn_type_cd', 'УСТ_ЛИМ_ВЫДАЧ', 'v_agr_cred_limit_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('tariff_interest_period', 'TARIFF', 'v_tarif_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('early_registry_type', 'НЕУЧ_ПЛАТА_ДОСРОЧ_ВОЗВР_ФИКС', 'v_early_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ССУД_ЗАДОЛЖ_ПОГАШЕНИЕ_ПРОСР_ПРИСУЖД_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ПРОЦ_КРЕД_БАЛ_ПЕРЕНОС_МЕЖ_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'CREDIT_7M', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('not_active_addendum_stts_type', 'WAIT_CONF', 'd_addendum_tree');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ОБСЛУЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ИЗМЕН_УСЛ_ПРОЦ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД_БАЛ_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_РЕСУРС_ПЕРИОД', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'СРОЧ_ССУД_ЗАДОЛЖ_КАП_ПРОЦ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ПРОЦ_КРЕД_ГРЕЙС', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f303_inf_types_code', 'F303_FORM_7_10', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ПРОЦ_КРЕД_БАЛ_С_ПЛАНОМ_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_ДОСТ_ЛИМ_ЗАДОЛЖ_УВЕЛИЧ_ДОСТ_ЛИМ_П_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_ОТКР_ЛИМИТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ПРОЦ_КРЕД_ВОЗМ_ЮЛ', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('active_stts_for_active_flag', 'WORK', 'v_agr_cred_stts_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP2186', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_MCX_375', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'DATE_GIVE', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L029', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('collat_coa_2_num', '91414', 'd_coa');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УВЕЛИЧ_ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС_ВЫНОС_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД_БАЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_red_on_prvsn_flag', 'СПИС_ВНЕБАЛ_ПЛАТА', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ИЗМЕН_УСЛ_АБС_ОП', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ОБСЛУЖ_ФИКС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ОТКР_ЛИМИТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ОБСЛУЖ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_НЕУЧ_ПРОЦ_КРЕД_ПЕРЕНОС_МЕЖ_ДОГ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД_ВНЕБ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ВЫДАЧ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УСТ_ЛИМ_ВРКЛДС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_НЕИСП_ОБЕСП', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_ОБСЛУЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP_106FZ', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MPT_SUB2018', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP295', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'Z1389_08_APK', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_ВЫНУЖ_ОТВ_СР', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_inf_end_date', 'CRED_MODE', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'SBN_DIRECT_BUSINESS', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L039', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('collat_coa_2_num', '91313', 'd_coa');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ОПЕРАЦИОН_КОММИС_ПРОЦ_ТИП_НЕУЧ_ПЛАТА_ЗА_ЛИМИТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_УСТ_ЛИМ_ВЫДАЧ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ОТКР_ЛИМ_ОВ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MSP65_MER2017', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('purpose_ext_code', 'TARGET_CRED_EXT', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_KN', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('interest_pymnt_category', 'ПОГАШ_ПРОЦ', 'v_interest_param_plan_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_ВЕДЕНИЕ', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('grntee_pymnt_optn_type', 'НЕУЧ_ПЛАТА_ВЫНУЖ_ОТВ_СР', 'v_grntee_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'КРЕД_ЭСКРОУ_БАЗОВАЯ', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'DealType', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L032', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_L003', 'УЧ_ПРОЦ_КРЕД_ВОЗМ_БАЛ_ЮЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_НЕИСП_ОБЕСП_ФИКС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ОТЛОЖ_ПРОЦ_КРЕД_ВНЕБ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ПОДДЕРЖ_КРЛИН_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПРОЦЕНТЫ_ГОС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ЗАДОЛЖ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ОПЕРАЦИОН_КОММИС_ПРОЦ_ТИП', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_ИЗМЕН_УСЛ_ОПЕРАЦ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_move_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_ПЕРЕНОС_МЕЖ_ДОГ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP671', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_MC_754', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ОТЛОЖ_ПРОЦ_КРЕД', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ПРОЦ_КРЕД_БАЛ_БЕЗ_ПЛАНА_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ССУД_ЗАДОЛЖ_БЕЗ_ПЛАНА_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'CRED_LONG_ADD', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'F303_FORM_7_10', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УВЕЛИЧ_НЕУЧ_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС_БЕЗ_ПЛАНА_ИСПРАВИТЕЛЬНАЯ_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ССУД_ЗАДОЛЖ_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_issue_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ДОСТ_ЛИМ_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_MPT', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP1818', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP252', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('prolong_dt', '2026-01-09', 'attr_for_migration');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_ЗА_ЛИМИТ', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('tariff_interest_period', 'INTEREST_ANNUAL_OF_TARIFFS', 'v_tarif_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_ПРОСР_ПРОЦ_КРЕД_БАЛ_ПЕРЕНОС_МЕЖ_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ПРОЦЕНТ_КОММИС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('collat_coa_2_num', '47426', 'd_coa');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПРОЦ_КРЕД_ВОЗМ_БАЛ_ЮЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПРОЦ_КРЕД_ВНЕБ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_РЕСУРС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ДОСТ_ЛИМ_ВЫДАЧ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_write_off_red_on_prvsn_flag', 'УМЕНЬШ_ПРОЦ_СПИС_НА_ВНЕБ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PROGRAM_MB_2022', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PROGRAM_MB_START_EXT', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MER995', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'ID_КНР', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L031', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('collat_coa_2_num', '91311', 'd_coa');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ВЕДЕНИЕ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_НЕИСП_ОБЕСП_ФИКС_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_red_on_prvsn_flag', 'ПРОЦ_СПИС_НА_ВНЕБ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_РЕЗЕРВ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПРОЦ_КРЕД_БАЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УМЕНЬШ_ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ОТЛОЖ_ПРОЦ_КРЕД', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'IT_PP1598', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PPS', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP895', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MER_2', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('cred_long_add_code', 'CRED_LONG_ADD', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('limit_plan_pymnt_optn_type_cd', 'УСТ_ЛИМ_ВРКЛДС', 'v_agr_cred_limit_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('early_registry_type', 'НЕУЧ_ПЛАТА_ДОСРОЧ_ВОЗВР', 'v_early_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_issue_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_БЕЗ_ПЛАНА_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('not_active_addendum_stts_type', 'TO_CLOSE', 'd_addendum_tree');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_ДОСТ_ЛИМ_ЗАДОЛЖ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УМЕНЬШ_ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН_ФИКС_БЕЗ_ПЛАНА_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ПРЕД_ГАРАН', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_issue_flag', 'УМЕНЬШ_СВОБ_ОСТ_ЛИМ_ЕКС_СПИС_ЛИМ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_НЕВЫПОЛ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСРОЧ_ПЛАТА_СТРАХ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ВЫДАЧ_УВЕЛИЧ_ЛИМ_ВЫДАЧА_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ДОСТ_ЛИМ_МАКС_ССУД_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'УЧ_КАП_ОТЛОЖ_ПРОЦ_КРЕД', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('active_stts_for_active_flag', 'TO_BUH_CONTROL', 'v_agr_cred_stts_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PROGRAM_MB', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'APK_512', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('debt_pymnt_category', 'ПОГАШ_КРЕД', 'v_debt_param_plan_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('limit_plan_pymnt_optn_type_cd', 'УСТ_ЛИМ_ЗАДОЛЖ', 'v_agr_cred_limit_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('tariff_interest_period', 'PART_OF_TARIFF', 'v_tarif_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('not_active_optn_stts_code', 'Аннулирован', 'v_agr_cred_optn_pre');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ССУД_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'НЕУЧ_ПЛАТА_ЗА_ИЗМЕН_УСЛ_АБС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ПРОЦЕНТ_КОМ_ЭКА', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'FOND_RAZV_DVBR', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PROGRAM_MB_START_NEW', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'CRED_APK', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('eks_a_f26_agr_cred_type_code', 'CRED_MODE', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_САЛЬДИРОВАНИЕ_NEW_ПОГАШЕНИЕ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УСТ_ЛИМ_ВЫДАЧ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'ID_СRM _ЗПИФ', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_issue_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_ВЫДАЧА_Р_СЧ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ОПЕРАЦИОН_КОММИС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_write_off_red_on_prvsn_flag', 'УМЕНЬШ_СПИС_ССУД_ЗАДОЛЖ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_НЕУЧ_ПЛАТА_ЗА_ОБСЛУЖ_ПЕРЕНОС_МЕЖ_ДОГ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_РЕСУРС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ВЕДЕНИЕ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('active_stts_for_active_flag', 'IN_SUPPORT', 'v_agr_cred_stts_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f26_asset_collat_type_code', 'MAIN_ZALOG_TYPE', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP811', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f303_cond_types_code', 'SPEC_COND_CRED', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SUBSID_REP_KIND_APK', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'PP407', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_С_ПЛАНОМ_РУЧНАЯ_ОПЕРАЦИЯ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'MAIN_ZALOG_TYPE', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПРОЦ_КРЕД_ВНЕБ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_НЕВЫПОЛ_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ЗАДОЛЖ_УВЕЛИЧ_ДОСТ_ЛИМ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_ДОСТ_ЛИМ_ВЫДАЧ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_for_grntee_comiss_flag', 'УМЕНЬШ_УЧ_ПЛАТА_ЗА_ПРЕД_ГАРАН_ВЫНОС_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_СУБС_ПРОЦ', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('inactive_stts_for_active_flag', 'CLOSED', 'v_agr_cred_stts_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('bus_line_type_code', 'SBN_DIRECT_BUSINESS', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'spb_dog_312', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L026', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УВЕЛИЧ_УЧ_ПРОЦ_КРЕД_БАЛ_ПОГАШЕНИЕ_П_СТОРНО_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ИМПОРТ_КОММИС_ТРАНШ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ВЫНУЖ_ОТВ_СР_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УВЕЛИЧ_СРОЧ_ССУД_ЗАДОЛЖ_ПОГАШЕНИЕ_П_СТОРНО_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ДОСТ_ЛИМ_ВРКЛДС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_НЕИСП_ОБЕСП', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УЧ_ПЛАТА_ЗА_РЕСУРС_М9', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_MT_745', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_ME_574', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('grntee_spec_code', 'GUARANTEE_SPECIFIC', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MSP6_5', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MER_0', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'SOP_MPT_GAR', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_НЕИСП_ОБЕСП', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_КАП_ПРОЦ_ПОГАШЕНИЕ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'TARGET_CRED_EXT', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'GUARANTEE_SPECIFIC', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'FOND_KOEF', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('collat_coa_2_num', '91312', 'd_coa');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_УСТ_ЛИМ_ВЫДАЧ_УМЕНЬШ_НЕДОСТ_ЛИМ_ФАКТ_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_move_flag', 'УМЕНЬШ_СРОЧ_ССУД_ЗАДОЛЖ_ПЕРЕНОС_МЕЖ_ДОГ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'СРОЧ_ССУД_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УВЕЛИЧ_ДОСТ_ЛИМ_ВЫДАЧ_УВЕЛИЧ_ДОСТ_ЛИМ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УВЕЛИЧ_УЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД_БАЛ_ПОГАШЕНИЕ_П_СТОРНО_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_L003', 'УЧ_ПРОЦЕНТЫ_ГОС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_rise_limit_flag', 'УМЕНЬШ_ДОСТ_ЛИМ_ВЫДАЧ_УВЕЛИЧ_ДОСТ_ЛИМ_П_СТОРНО', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'УСТ_ЛИМ_ЗАДОЛЖ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРОСР_ПЛАТА_ЗА_ЛИМИТ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ПРОЦ_КРЕД', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MSP65_MER2018', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('limit_plan_pymnt_optn_type_cd', 'УСТ_ЛИМ_ЗАДОЛЖ_ГАРАН', 'v_agr_cred_limit_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_ЗА_ИЗМЕН_УСЛ', 'v_comiss_plan_pymnt_cond_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('optn_type_code_for_repymnt_flag', 'УМЕНЬШ_УЧ_ОТЛОЖ_ФИКС_ПРОЦ_КРЕД_БАЛ_МИГРАЦИЯ_П', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ПРИСУЖ_ГОСПОШ', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_inf_end_date', 'CRED_TYPE_ADD', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'KIND_INSURANCE', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('feature_categ_src_end_date', 'COND_VZYSK_ZAL', 'v_agr_cred_prop_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('exclude_close_tranche', 'AGRA_L042', 'd_agr_cred_coa_period_prep_main_debts');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_inc_flag', 'ТРЕБ_ДОХОД_ПРОЦЕНТЫ_ГОС', 'v_agr_cred_optn');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('registry_type_for_rate_detail', 'НЕУЧ_ПРОЦ_КРЕД_ВОЗМ', 'v_agr_cred_rate_detail');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f303_ins_types_code', 'KIND_INSURANCE', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('subsidy_filter', 'MSP65_MER85', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('f303_purpose_code', 'F303_TARGET_CRED', 'v_feature_categ_type');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('limit_plan_pymnt_optn_type_cd', 'УСТ_ЛИМ_ВЫДАЧ_ГАРАН', 'v_agr_cred_limit_period');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('migration_dt', '2025-06-01', 'attr_for_migration');
INSERT INTO s_grnplm_as_t_didsd_nnn_db_tmd.d_settings("set_code", "set_value", "src_tbl") VALUES ('comiss_registry_type', 'НЕУЧ_ПЛАТА_ЗА_ОБСЛУЖ', 'v_comiss_plan_pymnt_cond_period');
