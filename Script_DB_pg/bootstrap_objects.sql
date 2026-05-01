CREATE SCHEMA IF NOT EXISTS s_grnplm_as_t_didsd_nnn_db_tmd;
DROP TABLE if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune(	
test_num text,
data_workflow_run_id int8 NULL,
sp_workflow_run_id int8 NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune IS 'Control table for selecting test scenario and workflow run ids.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune.test_num IS 'Test scenario identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune.data_workflow_run_id IS 'Workflow run id used for data preparation.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune.sp_workflow_run_id IS 'Workflow run id used for stored procedure execution.';

DROP TABLE if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_coa;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_coa (
gl_int_org_id uuid NULL,
coa_end_dt date NULL,
coa_id uuid NOT NULL,
coa_name text NULL,
coa_num text NULL,
coa_start_dt date NULL,
coa_type_id uuid DEFAULT lpad(to_hex('-1'::integer), 32, '0'::text)::uuid NOT NULL,
crncy_id uuid DEFAULT lpad(to_hex('-1'::integer), 32, '0'::text)::uuid NOT NULL,
gl_main_acct_id uuid NULL,
pl_rpt_cd_id uuid NULL,
set_of_books_cd text NULL,
deleted_flag text DEFAULT 'N'::text NOT NULL,
action_cd text NOT NULL,
workflow_run_id int8 NULL,
session_inst_id int4 NULL,
input_file_id int8 NULL,
info_system_id int2 NULL,
info_system_inst_cd text NOT NULL,
del_dt date NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_coa IS 'Staging chart of accounts records used in calculations.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.gl_int_org_id IS 'Internal organization identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_end_dt IS 'Account validity end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_id IS 'Chart of account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_name IS 'Chart of account name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_num IS 'Account number.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_start_dt IS 'Account validity start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.coa_type_id IS 'Account type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.gl_main_acct_id IS 'Main general ledger account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.pl_rpt_cd_id IS 'Profit and loss reporting code identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.set_of_books_cd IS 'Set of books code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.deleted_flag IS 'Logical deletion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.action_cd IS 'ETL action code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.session_inst_id IS 'Session instance identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.input_file_id IS 'Input file identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.info_system_inst_cd IS 'Source information system instance code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_coa.del_dt IS 'Record logical deletion date.';

-- s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line definition

-- Drop table

DROP TABLE if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line (
int_org_id uuid NULL,
je_header_id uuid NOT NULL,
je_header_val_dt date NULL,
je_line_cat_id uuid NULL,
je_line_coa_id uuid NULL,
je_line_corr_coa_id uuid NULL,
je_line_cred_ind text NULL,
je_line_local_amt numeric NULL,
je_line_trans_amt numeric NULL,
je_type_id uuid NOT NULL,
optn_id uuid NULL,
registry_id uuid NULL,
reg_bank_cd text NOT NULL,
set_of_books_cd text NOT NULL,
je_header_desc text NULL,
host_je_header_rel_id text NULL,
je_header_create_dt date NULL,
pymnt_doc_id uuid NULL,
deleted_flag text NOT NULL,
action_cd text NOT NULL,
workflow_run_id int8 NULL,
session_inst_id int4 NULL,
input_file_id int8 NULL,
info_system_id int2 NULL,
info_system_inst_cd text NOT NULL,
src_system_type_id uuid NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line IS 'Staging journal entry lines used for debt calculation flows.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.int_org_id IS 'Internal organization identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_header_id IS 'Journal entry header identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_header_val_dt IS 'Journal entry value date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_cat_id IS 'Journal line category identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_coa_id IS 'Journal line account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_corr_coa_id IS 'Corresponding account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_cred_ind IS 'Credit or debit indicator.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_local_amt IS 'Amount in local currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_line_trans_amt IS 'Amount in transaction currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_type_id IS 'Journal entry type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.optn_id IS 'Operation identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.registry_id IS 'Registry identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.reg_bank_cd IS 'Regulatory bank code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.set_of_books_cd IS 'Set of books code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_header_desc IS 'Journal entry description.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.host_je_header_rel_id IS 'Source system journal relation identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.je_header_create_dt IS 'Journal entry creation date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.pymnt_doc_id IS 'Payment document identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.deleted_flag IS 'Logical deletion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.action_cd IS 'ETL action code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.session_inst_id IS 'Session instance identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.input_file_id IS 'Input file identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.info_system_inst_cd IS 'Source information system instance code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_je_line.src_system_type_id IS 'Source system type identifier.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr;
CREATE TABLE if not EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr (
je_header_id           uuid,
je_line_coa_id         uuid,
incl_reason            smallint,
info_system_inst_cd    text,
pymnt_doc_id           uuid,
registry_id            uuid,
host_je_header_rel_id  text,
workflow_run_id        bigint,
deleted_flag           text,
int_org_id             uuid,
je_header_val_dt       date,
je_line_trans_amt      numeric,
je_line_local_amt      numeric,
je_header_desc         text,
je_line_cred_ind       text,
src_system_type_id     uuid,
corr_system_type_id    uuid,
je_type_id             uuid
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr IS 'Support table with filtered journal headers for intermediate processing.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_header_id IS 'Journal entry header identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_line_coa_id IS 'Journal line account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.incl_reason IS 'Inclusion reason code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.info_system_inst_cd IS 'Source information system instance code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.pymnt_doc_id IS 'Payment document identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.registry_id IS 'Registry identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.host_je_header_rel_id IS 'Source system journal relation identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.deleted_flag IS 'Logical deletion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.int_org_id IS 'Internal organization identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_header_val_dt IS 'Journal entry value date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_line_trans_amt IS 'Amount in transaction currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_line_local_amt IS 'Amount in local currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_header_desc IS 'Journal entry description.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_line_cred_ind IS 'Credit or debit indicator.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.src_system_type_id IS 'Source system type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.corr_system_type_id IS 'Corresponding source system type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_spt_je_header_fltr.je_type_id IS 'Journal entry type identifier.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param (
folder_name text NULL,
workflow_name text NULL,
workflow_inst_name text NULL,
worklet_inst_name text NULL,
session_name text NULL,
param_name text NOT NULL,
param_val text NULL,
param_desc text NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param IS 'ETL runtime parameters used by workflows and calculation functions.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.folder_name IS 'ETL folder name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.workflow_name IS 'ETL workflow name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.workflow_inst_name IS 'ETL workflow instance name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.worklet_inst_name IS 'ETL worklet instance name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.session_name IS 'ETL session name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.param_name IS 'Parameter name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.param_val IS 'Parameter value.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_task_param.param_desc IS 'Parameter description.';


drop type if exists s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params;
CREATE TYPE s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params as
(
period_start_dt             text,
period_end_dt               text,
increment_flag              smallint,
pymnt_doc_increment_flag    smallint,
old_data_del_flag           smallint,
src_system_excl_list        text,
src_system_excl_list_quoted text,
agrmnt_ini_dt               text,
ini_dt                      text);
COMMENT ON TYPE s_grnplm_as_t_didsd_nnn_db_tmd.tp_calc_params IS 'Composite type with runtime calculation parameters.';
drop type if exists s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log;
CREATE TYPE s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log as (
workflow_run_id int8,
run_tm timestamp(6),
proc text,
sql_query text,
param text
);
COMMENT ON TYPE s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log IS 'Composite type for ETL procedure log rows.';
DROP TABLE if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type (
src_system_type_id uuid NOT NULL,
src_system_type_cd text NULL,
src_system_type_name text NULL,
deleted_flag text DEFAULT 'N'::text NOT NULL,
action_cd text NOT NULL,
workflow_run_id int8 NULL,
session_inst_id int4 NULL,
input_file_id int8 NULL,
info_system_id int2 NULL,
info_system_inst_cd text NOT NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type IS 'Dictionary of source system types used across staging and marts.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.src_system_type_id IS 'Source system type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.src_system_type_cd IS 'Source system type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.src_system_type_name IS 'Source system type name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.deleted_flag IS 'Logical deletion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.action_cd IS 'ETL action code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.session_inst_id IS 'Session instance identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.input_file_id IS 'Input file identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.t_src_system_type.info_system_inst_cd IS 'Source information system instance code.';


drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log (
workflow_run_id int8 NOT NULL DEFAULT 0,
run_tm timestamp NOT NULL DEFAULT 'now'::text::timestamp(6) with time zone,
proc text NULL,
sql_query text NULL,
param text NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log IS 'Execution log for ETL and mart procedures.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log.run_tm IS 'Log event timestamp.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log.proc IS 'Procedure or process name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log.sql_query IS 'Executed SQL text.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log.param IS 'Procedure parameters or context.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.debug_log  ;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.debug_log (
id                             bigserial                      NOT NULL
, sql_query                      text                           NULL
, run_tm                         timestamp                      NULL
, param                          text                           NULL
, proc                           text                           NULL
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.debug_log IS 'Developer/debug trace log for SQL procedure troubleshooting.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.debug_log.id IS 'Debug log row identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.debug_log.sql_query IS 'Debug SQL text.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.debug_log.run_tm IS 'Debug event timestamp.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.debug_log.param IS 'Debug parameters payload.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.debug_log.proc IS 'Debug procedure name.';
;
drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal
(
agr_cred_id	uuid
,coa_id	uuid
,coa_num	text
,coa_n_id	uuid
,agr_coa_role_id	uuid
,coa_to_agrmnt_role_cd	text
,meas_cd	text
,start_dt	date
,end_dt	date
,crncy_id	uuid
,crncy_cd text
,iso_crncy_cd	text
,bal_amt	numeric
,bal_rub	numeric
,prnt_agr_cred_id	uuid
,ignore_flag	text
,own_calc_rub	numeric
,old_calc_rub	numeric
,agr_cred_coa_type_id	text
,own_calc_rub_prep	numeric
,calc_rub	numeric
,calc_weight	numeric
,prvsn_port_flag	text
,lowest_flag	text
,agr_cred_type_cd	text
,P_cnt					numeric
,J_cnt					numeric
,N_cnt					numeric
,info_system_id	smallint
,agr_cred_close_dt date
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal IS 'Prepared balances by agreement and account for intermediate debt calculations.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.agr_cred_id IS 'Agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.coa_id IS 'Account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.coa_num IS 'Account number.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.coa_n_id IS 'Normalized account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.agr_coa_role_id IS 'Agreement-account role identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.coa_to_agrmnt_role_cd IS 'Agreement-account role code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.meas_cd IS 'Measure code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.start_dt IS 'Period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.end_dt IS 'Period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.crncy_cd IS 'Currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.iso_crncy_cd IS 'ISO currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.bal_amt IS 'Balance amount in source currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.bal_rub IS 'Balance amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.prnt_agr_cred_id IS 'Parent agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.ignore_flag IS 'Row exclusion flag for downstream logic.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.own_calc_rub IS 'Calculated own amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.old_calc_rub IS 'Previous calculated amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.agr_cred_coa_type_id IS 'Agreement-account type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.own_calc_rub_prep IS 'Prepared own calculated amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.calc_rub IS 'Final calculated amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.calc_weight IS 'Calculation weight coefficient.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.prvsn_port_flag IS 'Provision portfolio flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.lowest_flag IS 'Flag for lowest selected value.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.agr_cred_type_cd IS 'Agreement credit type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.p_cnt IS 'Counter P used in calc diagnostics.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.j_cnt IS 'Counter J used in calc diagnostics.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.n_cnt IS 'Counter N used in calc diagnostics.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal.agr_cred_close_dt IS 'Agreement close date.';

drop table if exists  s_grnplm_as_t_didsd_nnn_db_tmd.d_settings;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_settings
(
set_code text
,set_value text
,src_tbl text

);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_settings IS 'Key-value settings used by calculation logic.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_settings.set_code IS 'Setting code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_settings.set_value IS 'Setting value.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_settings.src_tbl IS 'Source object where setting applies.';


drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts
(
prnt_agr_cred_id uuid,
agr_cred_id uuid,
coa_id uuid,
coa_num text,
coa_n_id uuid,
agr_coa_role_id uuid,
coa_to_agrmnt_role_cd text,
agr_cred_coa_type_id text,
meas_cd text,
start_dt date,
end_dt date,
crncy_id uuid,
crncy_cd text,
iso_crncy_cd text,
meas_amt numeric,
meas_rub numeric,
corr_own_meas_amt numeric,
corr_own_meas_rub numeric,
bal_amt numeric,
bal_rub numeric,
delta_rub numeric,
prvsn_port_flag text,
lowest_flag text,
calc_rub numeric,
agr_cred_type_cd text,
info_system_id smallint
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts IS 'Prepared main debt facts by agreement-account-period.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.prnt_agr_cred_id IS 'Parent agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.agr_cred_id IS 'Agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.coa_id IS 'Account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.coa_num IS 'Account number.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.coa_n_id IS 'Normalized account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.agr_coa_role_id IS 'Agreement-account role identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.coa_to_agrmnt_role_cd IS 'Agreement-account role code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.agr_cred_coa_type_id IS 'Agreement-account type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.meas_cd IS 'Measure code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.start_dt IS 'Period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.end_dt IS 'Period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.crncy_cd IS 'Currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.iso_crncy_cd IS 'ISO currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.meas_amt IS 'Measure amount in source currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.meas_rub IS 'Measure amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.corr_own_meas_amt IS 'Corrected own measure amount in source currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.corr_own_meas_rub IS 'Corrected own measure amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.bal_amt IS 'Balance amount in source currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.bal_rub IS 'Balance amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.delta_rub IS 'Difference amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.prvsn_port_flag IS 'Provision portfolio flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.lowest_flag IS 'Flag for lowest selected value.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.calc_rub IS 'Calculated amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.agr_cred_type_cd IS 'Agreement credit type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts.info_system_id IS 'Source information system identifier.';


drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred (
agr_cred_id	uuid	NOT null,
prnt_agr_cred_id	uuid	null,
info_system_id	int2	null,
agr_num	text	null,
grntee_agr_num	text	null,
tranche_order_num int8,
signed_dt	date	null,
close_dt	date	null,
expiration_dt	date	null,
host_agr_cred_id	text	null,
agr_frame_id	uuid	null,
has_higher_flag					text	null,
crncy_id						uuid	null,
agr_cred_type_id				int8	null,
open_dt							date	null,
agr_cred_type_cd				text	null,
rvlng_flag						text	null,
overdraft_flag					text	null,
agr_cred_start_amt				numeric	null,
host_eks_agr_id 				text,
prod_type_id					uuid,
objectid 						text,
cbr_uuid_cd						text,
agr_regls_type_id				uuid,
agr_cred_stts_migr_id 			uuid,
agr_cred_stts_migr_cd 			text,
limit_use_end_dt 				date,
issue_crncy_id					uuid	null,
host_prod_kful_id 				text,
host_prod_rootkful_id 			text,
let_of_cred_acc_scheme_id 		int2,
let_of_cred_cover_flag 			text,
letter_of_credit_type_id 		int2,
letter_of_cred_type_s_id 		uuid,
let_of_cred_revoce_flag 		text,
host_eks_let_of_cred_cover_id 	text,
host_let_of_cred_cover_id 		text,
let_of_cred_commodity_flag 		text,
agr_cession_id 					uuid,
workflow_run_id 				int8,
subject_area_type_id 			smallint,
let_of_cred_ufn_flag 			text,
let_of_cred_ctf_flag 			text,
let_of_cred_mmb_flag 			text,
effective_dt date
);

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period (
agr_cred_id	uuid
,start_dt	date
,end_dt	date
,prvsn_rate	numeric
,prvsn_limit_rate numeric
,info_system_id	smallint
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period IS 'Provision rates by agreement and period.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.agr_cred_id IS 'Agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.start_dt IS 'Provision period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.end_dt IS 'Provision period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.prvsn_rate IS 'Provision rate.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.prvsn_limit_rate IS 'Provision limit rate.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_prvsn_period.info_system_id IS 'Source information system identifier.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn (
agr_cred_id					uuid
,agr_cred_optn_id				uuid
,crncy_cd						text
,crncy_id						uuid
,iso_crncy_cd					text
,host_optn_id					text
,inc_flag						text
,agr_cred_crncy_cd				text
,issue_flag						text
,meas_cd						text
,move_flag						text
,optn_agr_cred_crncy_amt		numeric
,optn_crncy_amt					numeric
,optn_dt						date
,optn_issue_crncy_amt			numeric
,optn_rub						numeric
,optn_type_id					uuid
,src_registry_type_cd			text
,redemptn_on_prvsn_flag			text
,repymnt_flag					text
,rise_limit_flag				text
,write_off_rdmptd_on_prvsn_flag text
,grntee_comiss_flag				text
,own_flag						text
,tranche_flag 					text
,registry_debttype_cd 			text
,registry_debtcategory_cd 		text
,host_ext_id					text
,info_system_id          		int2
,workflow_run_id         		int8
,bus_srv_id                     uuid
,bus_srv_cd						text
,redemptn_on_cession_flag       text
,optn_rub_calc_dt               numeric -- upd
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn IS 'Operations/events by agreement used for debt and commission calculations.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.agr_cred_id IS 'Agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.agr_cred_optn_id IS 'Agreement operation identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.crncy_cd IS 'Currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.iso_crncy_cd IS 'ISO currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.host_optn_id IS 'Source system operation identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.inc_flag IS 'Increment flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.agr_cred_crncy_cd IS 'Agreement currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.issue_flag IS 'Issue operation flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.meas_cd IS 'Measure code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.move_flag IS 'Move operation flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_agr_cred_crncy_amt IS 'Operation amount in agreement currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_crncy_amt IS 'Operation amount in operation currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_dt IS 'Operation date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_issue_crncy_amt IS 'Issued amount in issue currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_rub IS 'Operation amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_type_id IS 'Operation type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.src_registry_type_cd IS 'Source registry type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.redemptn_on_prvsn_flag IS 'Redemption-on-provision flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.repymnt_flag IS 'Repayment flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.rise_limit_flag IS 'Limit increase flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.write_off_rdmptd_on_prvsn_flag IS 'Write-off redemption-on-provision flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.grntee_comiss_flag IS 'Guarantee commission flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.own_flag IS 'Own-funds operation flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.tranche_flag IS 'Tranche operation flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.registry_debttype_cd IS 'Registry debt type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.registry_debtcategory_cd IS 'Registry debt category code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.host_ext_id IS 'External source identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.workflow_run_id IS 'Workflow execution identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.bus_srv_id IS 'Business service identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.bus_srv_cd IS 'Business service code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.redemptn_on_cession_flag IS 'Redemption-on-cession flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn.optn_rub_calc_dt IS 'Operation amount in RUB at calculation date.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa
(
agr_id uuid
,prnt_agr_cred_id uuid
,sl_coa_id uuid
,meas_cd text
,start_dt date
,end_dt date
,registry_coa_stts_type_cd text
,gl_coa_flg text
,coa_num text
,coa_n_id uuid
,crncy_id uuid
,crncy_cd text
,iso_crncy_cd text
,ignore_flag text
,registry_type_cd text
,agr_cred_coa_type_id text
,info_system_id smallint
,gl_coa_id uuid
,eks_coa_id numeric
,host_eks_coa_id text
,coa_name text
,coa_n_name text
,asset_liab_type_id uuid
,prvsn_port_flag text
,registry_type_id uuid
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa IS 'Agreement-account bindings with account metadata.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.agr_id IS 'Agreement identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.prnt_agr_cred_id IS 'Parent agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.sl_coa_id IS 'Subledger account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.meas_cd IS 'Measure code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.start_dt IS 'Period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.end_dt IS 'Period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.registry_coa_stts_type_cd IS 'Registry account status type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.gl_coa_flg IS 'General ledger account flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.coa_num IS 'Account number.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.coa_n_id IS 'Normalized account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.crncy_cd IS 'Currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.iso_crncy_cd IS 'ISO currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.ignore_flag IS 'Row exclusion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.registry_type_cd IS 'Registry type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.agr_cred_coa_type_id IS 'Agreement-account type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.gl_coa_id IS 'General ledger account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.eks_coa_id IS 'EKS account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.host_eks_coa_id IS 'Source EKS account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.coa_name IS 'Account name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.coa_n_name IS 'Normalized account name.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.asset_liab_type_id IS 'Asset/liability type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.prvsn_port_flag IS 'Provision portfolio flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa.registry_type_id IS 'Registry type identifier.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h
(
agr_id					uuid
,h_start_dt			date
,h_end_dt				date
,coa_start_dt			date
,coa_end_dt			date
,info_system_id		smallint
,coa_n_id				uuid
,asset_liab_type_id	uuid
,sl_coa_id				uuid
,coa_num				text
,meas_cd				text
,crncy_id				uuid
,crncy_cd				text
,iso_crncy_cd			text
,ignore_flag			text
,prnt_agr_cred_id		uuid
,agr_cred_coa_type_id	text
,bal_amt_prep        	numeric
,bal_rub_prep		    numeric
,registry_type_cd 		text
,prvsn_port_flag 		text
,registry_type_id       uuid
,sl_coa_end_dt          date
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h IS 'Technical historical balances by account and period.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.agr_id IS 'Agreement identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.h_start_dt IS 'History period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.h_end_dt IS 'History period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.coa_start_dt IS 'Account validity start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.coa_end_dt IS 'Account validity end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.info_system_id IS 'Source information system identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.coa_n_id IS 'Normalized account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.asset_liab_type_id IS 'Asset/liability type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.sl_coa_id IS 'Subledger account identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.coa_num IS 'Account number.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.meas_cd IS 'Measure code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.crncy_id IS 'Currency identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.crncy_cd IS 'Currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.iso_crncy_cd IS 'ISO currency code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.ignore_flag IS 'Row exclusion flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.prnt_agr_cred_id IS 'Parent agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.agr_cred_coa_type_id IS 'Agreement-account type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.bal_amt_prep IS 'Prepared balance amount in source currency.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.bal_rub_prep IS 'Prepared balance amount in RUB.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.registry_type_cd IS 'Registry type code.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.prvsn_port_flag IS 'Provision portfolio flag.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.registry_type_id IS 'Registry type identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h.sl_coa_end_dt IS 'Subledger account end date.';


drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred
(
agr_cred_id uuid
,prnt_agr_cred_id uuid
,info_system_id smallint
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred IS 'Compact agreement-credit table used in local bootstrap mode.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred.agr_cred_id IS 'Agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred.prnt_agr_cred_id IS 'Parent agreement credit identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred.info_system_id IS 'Source information system identifier.';

drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt;
create table if not exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt
(
id uuid,
start_dt date,
end_dt   date,
info_system_id bigint
);
COMMENT ON TABLE s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt IS 'Calculation periods prepared for agreement-account processing.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt.id IS 'Technical row identifier.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt.start_dt IS 'Calculation period start date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt.end_dt IS 'Calculation period end date.';
COMMENT ON COLUMN s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt.info_system_id IS 'Source information system identifier.';



CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.fn_create_obj_test1()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN;
END;
$$;
