
CREATE OR REPLACE FUNCTION s_grnplm_as_t_didsd_nnn_db_tmd.sp_dm_ent_ld_d_agr_cred_coa_period_calc_dt(IN in_workflow_run_id BIGINT, out return_int_return_code int4)
RETURNS int4
language plpgsql
as
--do
$$
#variable_conflict use_variable  
		DECLARE in_LOAD_ENTITY_NAME			 text		DEFAULT 'd_agr_cred_coa_period_calc_dt';
		DECLARE LOAD_ENTITY_NAME			 text		DEFAULT 'd_agr_cred_coa_period';
		DECLARE SQL_QUERY 					 text 	;
        DECLARE ARC_DATE text; AGRA_L_ARC_DATE       text    ;  
       			MESSAGE_TEXT text DEFAULT '';
       vlog s_grnplm_as_t_didsd_nnn_db_tmd.tp_dm_log array;
       declare v_proc text default 'sp_dm_ent_ld_d_agr_cred_coa_period_calc_dt';
       declare v_error_msg text;
       declare v_full_error_msg text;
	   declare tmp_result_code int default 0;
begin

begin
  return_int_return_code = 0;

sql_query = 'drop table if exists s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt_'||in_workflow_run_id::text||';
create table s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt_'||in_workflow_run_id::text||' (like s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt) distributed by(id);';
execute sql_query;

SQL_QUERY = 'insert into s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_period_calc_dt_'||in_workflow_run_id::text||'
(id ,
start_dt ,
end_dt   ,
info_system_id
)
with  dt_pre as
(select
id,
start_dt
from (
select agr_cred_id as id,
optn_dt as start_dt
from s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn_'||in_workflow_run_id::text||'
where optn_dt <> date ''9999-12-31''
union all
select agr_id,
h_start_dt start_dt
from s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||in_workflow_run_id::text||'
union all
select agr_id,
h_end_dt + 1 end_dt
from s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||in_workflow_run_id::text||'
where 1=1
and coa_end_dt <> date ''9999-12-31''
) dt
join (select agr_id from s_grnplm_as_t_didsd_nnn_db_tmd.d_tech_tbl_coa_bal_h_'||in_workflow_run_id::text||' group by agr_id) flt
on dt.id = flt.agr_id
group by id,start_dt),
prnt_dt as -- синхронизируем даты по  всем траншам
(select coalesce(crd.prnt_agr_cred_id,crd.agr_cred_id) as prnt_agr_cred_id, -- upd DMD-3602 у аккредитовов не заполнен родитель
start_dt
from dt_pre dt
join s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||in_workflow_run_id::text||' crd
on dt.id =  crd.agr_cred_id
group by coalesce(crd.prnt_agr_cred_id,crd.agr_cred_id),start_dt),
/*
 * синхронизируем точки расчета (start_dt) между КЛ, привязанными к одному счету - делаем это с целью оптимизации, для того, чтобы  избежать такого тиражирования по всем счетам
 * Кейс когда у разных договоров верхнего уровня могут быть разные точки приходит из s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_optn
 * все остальные инициаторы для таких договоров сопадают
 */
prnt_dt4share as
(select coalesce(t1.prnt_agr_cred_id,t1.agr_id) as prnt_agr_cred_id,
t1.sl_coa_id
from s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' t1
join (select sl_coa_id
from s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_coa_'||in_workflow_run_id::text||' p
where p.meas_cd like (''AGRA_L%'')
group by sl_coa_id having max(coalesce(p.prnt_agr_cred_id, p.agr_id)::text) <> min(coalesce(p.prnt_agr_cred_id,p.agr_id)::text)
) t2
on t1.sl_coa_id = t2.sl_coa_id
group by coalesce(t1.prnt_agr_cred_id,t1.agr_id),
t1.sl_coa_id
),
prnt_dt4share_2 as
(WITH RECURSIVE connected_groups AS (
-- Начальные точки: все уникальные agr_id
SELECT prnt_agr_cred_id , prnt_agr_cred_id as group_id
FROM prnt_dt4share
UNION
-- Рекурсивная часть: находим связи через coa_id
SELECT t.prnt_agr_cred_id, cg.group_id
FROM connected_groups cg
JOIN prnt_dt4share t1 ON cg.prnt_agr_cred_id = t1.prnt_agr_cred_id
JOIN prnt_dt4share t ON t1.sl_coa_id = t.sl_coa_id
WHERE t.prnt_agr_cred_id <> cg.prnt_agr_cred_id -- избегаем самосвязей
)
select prnt_agr_cred_id,group_id
from
(select prnt_agr_cred_id, group_id, min(group_id::text) over (partition by sum_prnt_agr_cred_id_bigint)::uuid as min_group_id
from
(
select  prnt_agr_cred_id ,
group_id,
sum(abs(uuid_hash(prnt_agr_cred_id))) over (partition by group_id) as sum_prnt_agr_cred_id_bigint
from
(SELECT
prnt_agr_cred_id ,
group_id,
abs(uuid_hash(prnt_agr_cred_id))
FROM connected_groups
group by prnt_agr_cred_id , group_id) t
) t
) t
where min_group_id = group_id) ,

prnt_dt4share_with_group as
(select t1.prnt_agr_cred_id, t1.start_dt, t2.group_id
from prnt_dt t1
join prnt_dt4share_2 t2
on t1.prnt_agr_cred_id = t2.prnt_agr_cred_id ),

dt_shared_by_group as
( select t1.prnt_agr_cred_id ,
t2.start_dt -- получим все точки по группе
from prnt_dt4share_with_group t1
join prnt_dt4share_with_group t2
on t1.group_id = t2.group_id
group by t1.prnt_agr_cred_id ,
t2.start_dt -- получим все точки по группе
)

select  crd.agr_cred_id as id,
start_dt,
coalesce (max (start_dt) over (partition by crd.agr_cred_id order by start_dt rows between 1 following and 1 following) - 1, date ''9999-12-31'') as end_dt,
max(crd.info_system_id) as info_system_id
from  (select prnt_agr_cred_id,
start_dt
from
(select prnt_agr_cred_id,
start_dt
from prnt_dt
union all
select prnt_agr_cred_id,
start_dt
from dt_shared_by_group) t
group by prnt_agr_cred_id,start_dt) prnt_dt
join s_grnplm_as_t_didsd_nnn_db_tmd.d_agr_cred_'||in_workflow_run_id::text||' crd
on prnt_dt.prnt_agr_cred_id =  coalesce(crd.prnt_agr_cred_id,crd.agr_cred_id)
group by crd.agr_cred_id, start_dt;';


vlog =  s_grnplm_as_t_didsd_nnn_db_tmd.sp_execute_run  (in_workflow_run_id , tmp_result_code, SQL_QUERY, v_proc , vlog,true,true);


    vlog = s_grnplm_as_t_didsd_nnn_db_tmd.add_arr_log(in_workflow_run_id, v_proc, 'E_INF', 'End calc SP_DM_ENT_LD_d_agr_cred_coa_period_calc_dt', vlog);


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
EXECUTE ON ANY;

      


