/*
  запуск третьего тестового сценария с разным количеством записей в таблицах
  В качестве тестового запроса используется запрос вычисление точек расчета
  Функия fn_run_test выполняет все необходимые действия: генерация данных и вызов процедуры расчета витрины
  логирование происходит через в таблицу etl_bkmart_log, в том числе логирование времени выполнения и планов запросов расчета витрины
*/

--truncate table s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log;
-- тест 100000 записей, 50 траншей на одной родительской записи, 10000 размер батча для вставки, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test3(100000,50,10000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;

-- тест 1000000 записей, 50 траншей на одной родительской записи, 10000 размер батча для вставки, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test3 (1000000,100,1000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;

-- тест 10000000 записей, 50 траншей на одной родительской записи, 10000 размер батча для вставки, 0 номер параллельного запуска 0..n
select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test3 (10000000,100,10000);
select * from s_grnplm_as_t_didsd_nnn_db_tmd.etl_bkmart_log order by run_tm;