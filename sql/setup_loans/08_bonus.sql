-- Step 8 bonus: materialized view + star fact table.

SET search_path TO loans, public;

DROP MATERIALIZED VIEW IF EXISTS loans.mv_portfolio_summary;

CREATE MATERIALIZED VIEW loans.mv_portfolio_summary AS
SELECT * FROM loans.loan_portfolio_summary;

COMMENT ON MATERIALIZED VIEW loans.mv_portfolio_summary IS 'Materialized copy for fast reporting';

DROP TABLE IF EXISTS loans.fact_payment CASCADE;

CREATE TABLE loans.fact_payment AS
SELECT
    p.payment_id,
    p.loan_id,
    l.customer_id,
    p.payment_date,
    p.amount,
    p.principal_paid,
    p.interest_paid
FROM loans.payments p
JOIN loans.loans l ON p.loan_id = l.loan_id;

COMMENT ON TABLE loans.fact_payment IS 'Star-schema style fact table: payments';
