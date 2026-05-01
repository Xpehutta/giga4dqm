drop FUNCTION IF EXISTS s_grnplm_as_t_didsd_nnn_db_tmd.sp_dm_ent_ld_d_agr_cred_coa_period_prep_main_debts_separate(BIGINT,bigint);
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_dm_ent_ld_d_agr_cred_coa_period_prep_main_debts_separate(IN in_workflow_run_id BIGINT,in in_data_wf int8, out return_int_return_code int4)
RETURNS int4
language plpgsql
as
--do
$$
#variable_conflict use_variable  
		DECLARE in_LOAD_ENTITY_NAME			 text		DEFAULT 'd_agr_cred_coa_period_prep_main_debts';
		DECLARE LOAD_ENTITY_NAME			 text		DEFAULT 'd_agr_cred_coa_period';
		DECLARE SQL_QUERY 					 text 	;
        DECLARE ARC_DATE text; AGRA_L_ARC_DATE       text    ;  
       			MESSAGE_TEXT text DEFAULT '';
       vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
       declare v_proc text default 'sp_dm_ent_ld_d_agr_cred_coa_period_prep_main_debts';
       declare v_error_msg text;
       declare v_full_error_msg text;
	   declare tmp_result_code int default 0;
begin

begin
  return_int_return_code = 0;
      vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'START', 'workflow_run_id='||in_workflow_run_id, vlog);

sql_query = 'create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts);';
vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, sql_query, v_proc , vlog);

       SQL_QUERY = 'insert into s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_main_debts_'||in_workflow_run_id::text||' (prnt_agr_cred_id,agr_cred_id,coa_id,coa_num,coa_n_id,agr_coa_role_id,coa_to_agrmnt_role_cd,agr_cred_coa_type_id,meas_cd,start_dt,end_dt,crncy_id,crncy_cd,iso_crncy_cd,corr_own_meas_amt,corr_own_meas_rub,bal_amt,bal_rub,prvsn_port_flag,lowest_flag,calc_rub,agr_cred_type_cd,info_system_id)
				select 
					 prnt_agr_cred_id
					,agr_cred_id
					,coa_id
					,coa_num
					,coa_n_id
					,agr_coa_role_id
					,coa_to_agrmnt_role_cd
					,agr_cred_coa_type_id
					,meas_cd
					,start_dt
					,end_dt
					,crncy_id
					,crncy_cd
					,iso_crncy_cd
					,corr_own_meas_amt
					,corr_own_meas_rub
					,bal_amt
					,bal_rub
					,prvsn_port_flag
					,lowest_flag
					,calc_rub
					,agr_cred_type_cd
					,info_system_id
					from (	
					select t.* 
						  ,coalesce (own_meas_amt, 0) + case when rn = 1 then coalesce (bal_amt, 0) - sum (own_meas_amt) over (partition by start_dt, coa_id) else 0 end as corr_own_meas_amt
						  , coalesce (own_meas_rub, 0) + case when rn = 1 then coalesce (bal_rub, 0) - sum (own_meas_rub) over (partition by start_dt, coa_id) else 0 end as corr_own_meas_rub								
					 from 
						(select  
								agr_cred_id, 
								start_dt,
								end_dt, 
								meas_cd, 
								coa_id , 
								bal_amt, 
								bal_rub,   
								coa_to_agrmnt_role_cd,
								agr_cred_coa_type_id,
								calc_weight,
								iso_crncy_cd,
								coa_num,
								crncy_id,
								t.crncy_cd,
								agr_coa_role_id,
								coa_n_id,
								meas_weight_even, 
								meas_weight_byevt, 
								prnt_agr_cred_id,
								coalesce(meas_weight_byevt, meas_weight_even, 1.0000000000) as meas_weight,
								coalesce(meas_weight_byevt, meas_weight_even, 1.0000000000) * bal_amt as own_meas_amt,
								coalesce(meas_weight_byevt, meas_weight_even, 1.0000000000) * bal_rub as own_meas_rub,
								case when calc_rub_pre < 0 then 0 else calc_rub_pre end as calc_rub,
								row_number () over (partition by start_dt, coa_id order by (coalesce(meas_weight_byevt, meas_weight_even, 1.0000000000) * bal_amt) desc, meas_cd, agr_cred_id) as rn,
								prvsn_port_flag,
								lowest_flag,
								agr_cred_type_cd,
								t.info_system_id 	
						from (
								/*Старт распределения основных задолженностей*/
									select
                                       	 agr_cred_id
                                       	,start_dt
                                       	,end_dt
                                       	,crncy_id
                                       	,t.crncy_cd
                                       	,meas_cd
                                       	,coa_num
                                       	,coa_n_id
                                       	,agr_coa_role_id
                                       	,coa_to_agrmnt_role_cd
                                       	,agr_cred_coa_type_id
                                       	,coa_id
                                       	,iso_crncy_cd
                                       	,bal_amt
                                       	,bal_rub
                                       	,own_calc_rub
                                       	,calc_weight
                                       	,prnt_agr_cred_id
                                       	,case when ignore_flag = ''Y'' /* для meas_cd из настройки исключим из распределения закрытые транши */
                                       	         or (agr_cred_close_dt < start_dt and agr_cred_type_cd = ''4'' and st.set_value is not null)
                                       	      then 0.0
                                       			else 1.0000000000 / nullif(sum(
                                       			case	when ignore_flag = ''Y''
                                       	          /* так же не будем учитывать такие транши при расчете весов  */
                                       			or
                                       	          (agr_cred_close_dt < start_dt and agr_cred_type_cd = ''4'' and st.set_value is not null ) then 0 else 1 end)
                                       	           over (partition by start_dt, coa_id), 0)::numeric
                                       	 end as meas_weight_even
                                       	,
                            		   own_calc_rub_prep * calc_weight / nullif(sum(own_calc_rub_prep * calc_weight) over (partition by start_dt, coa_id), 0) as meas_weight_byevt
                            		,calc_rub - case when ignore_flag = ''Y'' then coalesce(own_calc_rub, 0) else 0 end as calc_rub_pre
                            		,prvsn_port_flag
                            		,lowest_flag
                            		,agr_cred_type_cd
                            		,t.info_system_id
                            		,t.agr_cred_close_dt -- новое поле  из d_agr_cred_coa_period_prep_bal
                            	from s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_prep_bal_'||in_data_wf::text||' t
                            	left
                            	join s_grnplm_as_t_didsd_nnn_db_tmd.d_settings st
                            	  on st.set_code = ''exclude_close_tranche''
                            	 and t.meas_cd = st.set_value
                            	 and st.src_tbl = ''d_agr_cred_coa_period_prep_main_debts''
							) t
						) t
					) t
					;';

	vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, SQL_QUERY, v_proc , vlog,true,true);


    vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'E_INF', 'End calc SP_DM_ENT_LD_D_AGR_CRED_COA_PERIOD_PREP_MAIN_DEBTS', vlog);


exception when others then

get stacked diagnostics
v_error_msg = pg_exception_context;

v_full_error_msg = 'FAIL : '||v_proc||' : '||substr((cast(clock_timestamp() as text)), 1, 22) ||chr(10)
||' ErrorState:=' || sqlstate
|| ' ErrorCode:=' || sqlerrm ||chr(10)
|| ' result_code=' || cast(tmp_result_code as text) ||chr(10)
|| ' SqlQuery:=' || current_query() ||chr(10)
|| ' pg_exception_context:=' ||v_error_msg;

vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'FAIL', v_full_error_msg, vlog);
return_int_return_code = -1;

--raise notice '%', result_s;
end;

perform s_grnplm_as_t_didsd_nnn_db_tmd.save_prc_log(vlog);
END;
$$
