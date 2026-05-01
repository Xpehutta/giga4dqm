 --drop function if exists s_grnplm_as_t_didsd_nnn_db_tmd.sp_collect_stat(dbase_name text, tbl_name text);

create or replace function s_grnplm_as_t_didsd_nnn_db_tmd.sp_collect_stat(dbase_name text, tbl_name text, p_colm text default null)
 returns void
 language plpgsql
 security definer
as $func$ 
<<lmain>>
declare sql_query text default '';
begin

 if coalesce(p_colm, '') <> ''
 then p_colm = ' ('||p_colm||')';
 end if;
 
 sql_query='analyze '||dbase_name||'.'||tbl_name|| coalesce(p_colm,'');
 execute sql_query;

end lmain;
 $func$
 