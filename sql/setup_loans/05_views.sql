-- Step 5: analytical views (ORDER BY removed — sort when querying).

SET search_path TO loans, public;

CREATE OR REPLACE VIEW loans.loan_portfolio_summary AS
WITH outstanding AS (
    SELECT
        l.loan_id,
        l.status,
        l.loan_amount - COALESCE(SUM(p.principal_paid), 0) AS outstanding_balance
    FROM loans.loans l
    LEFT JOIN loans.payments p ON l.loan_id = p.loan_id
    GROUP BY l.loan_id, l.loan_amount, l.status
)
SELECT
    l.status,
    COUNT(*) AS total_loans,
    SUM(l.loan_amount) AS total_originated,
    SUM(o.outstanding_balance) AS total_outstanding,
    AVG(l.interest_rate) AS avg_interest_rate
FROM loans.loans l
JOIN outstanding o ON l.loan_id = o.loan_id
GROUP BY l.status;

CREATE OR REPLACE VIEW loans.customer_credit_risk AS
WITH customer_debt AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.credit_score,
        COUNT(DISTINCT l.loan_id) AS total_loans,
        COALESCE(SUM(l.loan_amount), 0) AS total_debt,
        COALESCE(AVG(d.days_past_due), 0) AS avg_days_past_due
    FROM loans.customers c
    LEFT JOIN loans.loans l ON c.customer_id = l.customer_id
    LEFT JOIN loans.delinquencies d ON l.loan_id = d.loan_id
    GROUP BY c.customer_id, c.full_name, c.credit_score
)
SELECT
    customer_id,
    full_name,
    credit_score,
    total_loans,
    total_debt,
    avg_days_past_due,
    CASE
        WHEN credit_score >= 700 AND avg_days_past_due < 5 THEN 'LOW'
        WHEN credit_score BETWEEN 600 AND 699 OR avg_days_past_due BETWEEN 5 AND 30 THEN 'MEDIUM'
        ELSE 'HIGH'
    END AS risk_category
FROM customer_debt;

CREATE OR REPLACE VIEW loans.payment_behaviour AS
SELECT
    p.loan_id,
    p.payment_date,
    p.amount,
    SUM(p.principal_paid)
        OVER (PARTITION BY p.loan_id ORDER BY p.payment_date) AS cumulative_principal_paid,
    l.loan_amount
        - SUM(p.principal_paid)
            OVER (PARTITION BY p.loan_id ORDER BY p.payment_date) AS remaining_balance
FROM loans.payments p
JOIN loans.loans l ON p.loan_id = l.loan_id;

CREATE OR REPLACE VIEW loans.cohort_analysis AS
WITH customer_cohort AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM created_at)::int AS cohort_year
    FROM loans.customers
),
loan_performance AS (
    SELECT
        c.cohort_year,
        DATE_TRUNC('year', l.start_date)::date AS loan_year,
        COUNT(*) AS num_loans,
        AVG(l.interest_rate) AS avg_rate,
        AVG(l.loan_amount) AS avg_loan_amount
    FROM loans.loans l
    JOIN customer_cohort c ON l.customer_id = c.customer_id
    GROUP BY c.cohort_year, DATE_TRUNC('year', l.start_date)
)
SELECT * FROM loan_performance;

COMMENT ON VIEW loans.loan_portfolio_summary IS 'Aggregated KPIs per loan status';
COMMENT ON VIEW loans.customer_credit_risk IS 'Classifies customers by credit score and delinquency';
COMMENT ON VIEW loans.payment_behaviour IS 'Cumulative principal paid and remaining balance per payment';
COMMENT ON VIEW loans.cohort_analysis IS 'Loan metrics by customer acquisition cohort year';
