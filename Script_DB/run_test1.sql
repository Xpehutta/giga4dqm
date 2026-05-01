/*
  запуск первого тестового сценария с разным количеством записей в таблицах
  В качестве тестового запроса используется запрос отбора проводок для витрины placc
  Функия fn_run_test выполняет все необходимые действия: генерация данных и вызов процедуры расчета витрины
  логирование происходит через в таблицу etl_bkmart_log, в том числе логирование времени выполнения и планов запросов расчета витрины
*/

--truncate table s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log;
-- тест 10000 счетов, 1000 000 проводок, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1 (1000000,2000000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;

-- тест 30000 счетов, 10 000 000 проводок, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1 (30000,10000000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;

-- тест 30000 счетов, 100 000 000 проводок, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1 (30000,100000000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;


DROP TABLE if exists s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune;
CREATE TABLE s_grnplm_as_t_didsd_nnn_db_tmd.t_str_pilot_tune(	
test_num text,
workflow_run_id int8 NULL
);