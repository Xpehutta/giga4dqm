-- Step 11: smoke checks (read-only).

SET search_path TO loans, public;

SELECT 'customers' AS tbl, COUNT(*)::bigint FROM loans.customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM loans.accounts
UNION ALL
SELECT 'loans', COUNT(*) FROM loans.loans
UNION ALL
SELECT 'payments', COUNT(*) FROM loans.payments
UNION ALL
SELECT 'delinquencies', COUNT(*) FROM loans.delinquencies;

SELECT * FROM loans.loan_portfolio_summary;

SELECT * FROM loans.customer_credit_risk LIMIT 10;

SELECT * FROM loans.payment_behaviour ORDER BY loan_id, payment_date LIMIT 20;

SELECT COUNT(*) AS loan_data_mart_rows FROM loans.loan_data_mart;

SELECT loans.remaining_balance(1) AS rem_1;
SELECT loans.customer_lifetime_value(1) AS clv_1;
SELECT loans.default_probability(1) AS def_1;
