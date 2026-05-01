-- Step 7: data mart table + refresh procedure (temp tables dropped first for idempotency).

SET search_path TO loans, public;

DROP TABLE IF EXISTS loans.loan_data_mart;

CREATE TABLE loans.loan_data_mart (
    snapshot_date       DATE,
    customer_id         INT,
    loan_id             INT,
    outstanding_balance NUMERIC,
    days_past_due       INT,
    is_npl              BOOLEAN,
    interest_paid_ytd   NUMERIC,
    risk_score          NUMERIC,
    PRIMARY KEY (snapshot_date, loan_id)
);

COMMENT ON TABLE loans.loan_data_mart IS 'Monthly snapshot fact table for loan portfolio analytics';

CREATE OR REPLACE PROCEDURE loans.refresh_loan_data_mart(p_snapshot_date DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql AS $$
BEGIN
    DROP TABLE IF EXISTS tmp_loan_summary;
    DROP TABLE IF EXISTS tmp_dpd;
    DROP TABLE IF EXISTS tmp_mart_staging;
    DROP TABLE IF EXISTS tmp_customer_risk;

    CREATE TEMP TABLE tmp_loan_summary AS
    SELECT
        l.loan_id,
        l.customer_id,
        l.loan_amount,
        l.status,
        l.interest_rate,
        COALESCE(SUM(p.principal_paid), 0) AS total_principal_paid,
        COALESCE(SUM(p.interest_paid), 0) AS total_interest_paid,
        MAX(p.payment_date) AS last_payment_date
    FROM loans.loans l
    LEFT JOIN loans.payments p
        ON l.loan_id = p.loan_id AND p.payment_date <= p_snapshot_date
    GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.status, l.interest_rate;

    CREATE TEMP TABLE tmp_dpd AS
    SELECT
        l.loan_id,
        COALESCE(MAX(d.days_past_due), 0) AS days_past_due
    FROM loans.loans l
    LEFT JOIN loans.delinquencies d
        ON l.loan_id = d.loan_id AND d.recorded_at::date <= p_snapshot_date
    GROUP BY l.loan_id;

    CREATE TEMP TABLE tmp_mart_staging AS
    SELECT
        p_snapshot_date AS snapshot_date,
        s.customer_id,
        s.loan_id,
        (s.loan_amount - s.total_principal_paid) AS outstanding_balance,
        d.days_past_due,
        CASE
            WHEN s.status = 'defaulted' THEN TRUE
            WHEN d.days_past_due >= 90 THEN TRUE
            ELSE FALSE
        END AS is_npl,
        s.total_interest_paid AS interest_paid_ytd
    FROM tmp_loan_summary s
    JOIN tmp_dpd d ON s.loan_id = d.loan_id;

    CREATE TEMP TABLE tmp_customer_risk AS
    SELECT
        customer_id,
        loans.default_probability(customer_id) AS risk_score
    FROM loans.customers;

    INSERT INTO loans.loan_data_mart
    SELECT
        st.snapshot_date,
        st.customer_id,
        st.loan_id,
        st.outstanding_balance,
        st.days_past_due,
        st.is_npl,
        st.interest_paid_ytd,
        r.risk_score
    FROM tmp_mart_staging st
    JOIN tmp_customer_risk r ON st.customer_id = r.customer_id
    ON CONFLICT (snapshot_date, loan_id) DO UPDATE SET
        outstanding_balance = EXCLUDED.outstanding_balance,
        days_past_due = EXCLUDED.days_past_due,
        is_npl = EXCLUDED.is_npl,
        interest_paid_ytd = EXCLUDED.interest_paid_ytd,
        risk_score = EXCLUDED.risk_score;

    DROP TABLE IF EXISTS tmp_loan_summary, tmp_dpd, tmp_mart_staging, tmp_customer_risk;
END;
$$;

COMMENT ON PROCEDURE loans.refresh_loan_data_mart IS '5‑step ETL to populate loan_data_mart';
