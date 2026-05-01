-- Step 4: missing from setup_loan_db.md — synthetic data generator.

SET search_path TO loans, public;

CREATE OR REPLACE FUNCTION loans.generate_banking_data(p_num_customers INT)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    r_loan           RECORD;
    m                INT;
    monthly_total    NUMERIC;
    principal_remaining NUMERIC;
    interest_portion NUMERIC;
    principal_part   NUMERIC;
    pay_dt           DATE;
    r_m              NUMERIC;
BEGIN
    IF p_num_customers IS NULL OR p_num_customers < 1 THEN
        RAISE EXCEPTION 'p_num_customers must be >= 1';
    END IF;

    IF to_regclass('loans.fact_payment') IS NOT NULL THEN
        TRUNCATE TABLE loans.fact_payment RESTART IDENTITY;
    END IF;
    IF to_regclass('loans.loan_data_mart') IS NOT NULL THEN
        TRUNCATE TABLE loans.loan_data_mart RESTART IDENTITY;
    END IF;

    TRUNCATE TABLE loans.delinquencies, loans.payments, loans.loans, loans.accounts,
        loans.customers
    RESTART IDENTITY CASCADE;

    INSERT INTO loans.customers (full_name, birth_date, country, income, credit_score)
    SELECT
        format('Customer %s %s', g, upper(substr(md5(g::text), 1, 6))),
        (
            DATE '1960-01-01'
            + make_interval(
                days => (7 * g + (random() * 8000)::int) % 23000
            )
        )::date,
        (ARRAY['US', 'UK', 'DE', 'FR', 'ES', 'IT', 'NL'])[1 + ((g * 13) % 7)],
        ROUND((32000 + random() * 130000)::numeric, 2)::numeric(12, 2),
        (
            GREATEST(301, LEAST(850, (430 + floor(random() * 420))::int))
        )::smallint
    FROM generate_series(1, p_num_customers) AS g;

    INSERT INTO loans.accounts (customer_id, account_type, balance, status)
    SELECT
        c.customer_id,
        'checking',
        ROUND((random() * 25000)::numeric, 2)::numeric(12, 2),
        'active'
    FROM loans.customers c;

    INSERT INTO loans.accounts (customer_id, account_type, balance, status)
    SELECT
        c.customer_id,
        'savings',
        ROUND((random() * 90000)::numeric, 2)::numeric(12, 2),
        'active'
    FROM loans.customers c
    WHERE (c.customer_id % 3) = 0;

    INSERT INTO loans.loans (
        customer_id,
        account_id,
        loan_amount,
        interest_rate,
        term_months,
        start_date,
        end_date,
        status
    )
    SELECT
        s.customer_id,
        s.account_id,
        s.loan_amt,
        s.apr,
        s.n_months,
        s.start_dt,
        (s.start_dt + (s.n_months || ' months')::interval)::date,
        CASE
            WHEN s.r < 0.90 THEN 'active'
            WHEN s.r < 0.96 THEN 'closed'
            ELSE 'defaulted'
        END
    FROM (
        SELECT
            c.customer_id,
            aa.account_id,
            ROUND((8000 + random() * 185000)::numeric, 2)::numeric(12, 2) AS loan_amt,
            ROUND((3.5 + random() * 17)::numeric, 2)::numeric(5, 2) AS apr,
            (12 + floor(random() * 72))::int AS n_months,
            (DATE '2019-01-01' + ((random() * 1700)::int))::date AS start_dt,
            random() AS r
        FROM loans.customers c
        INNER JOIN LATERAL (
            SELECT account_id
            FROM loans.accounts a
            WHERE a.customer_id = c.customer_id
            ORDER BY random()
            LIMIT 1
        ) AS aa ON TRUE
        WHERE random() < 0.93
    ) AS s;

    FOR r_loan IN
        SELECT loan_id, loan_amount, interest_rate, term_months, start_date, status
        FROM loans.loans
    LOOP
        IF r_loan.loan_amount <= 0 THEN
            CONTINUE;
        END IF;

        monthly_total := loans.calculate_monthly_payment(
            r_loan.loan_amount,
            r_loan.interest_rate,
            r_loan.term_months
        );
        IF monthly_total IS NULL OR monthly_total <= 0 THEN
            monthly_total := r_loan.loan_amount / GREATEST(r_loan.term_months, 1);
        END IF;

        principal_remaining := r_loan.loan_amount;
        r_m := COALESCE(r_loan.interest_rate / 12.0 / 100.0, 0);

        FOR m IN 1..LEAST(r_loan.term_months, 360)
        LOOP
            EXIT WHEN principal_remaining <= 0.009;
            pay_dt := (r_loan.start_date + ((m - 1) || ' months')::interval)::date;
            interest_portion := ROUND(principal_remaining * r_m, 2);
            IF interest_portion > monthly_total THEN
                interest_portion := monthly_total - 0.01;
            END IF;
            principal_part := ROUND(monthly_total - interest_portion, 2);
            IF principal_part > principal_remaining THEN
                principal_part := ROUND(principal_remaining, 2);
                interest_portion := ROUND(monthly_total - principal_part, 2);
                IF interest_portion < 0 THEN
                    interest_portion := 0;
                    principal_part := ROUND(principal_remaining, 2);
                END IF;
            END IF;

            INSERT INTO loans.payments (
                loan_id,
                payment_date,
                amount,
                principal_paid,
                interest_paid
            )
            VALUES (
                r_loan.loan_id,
                pay_dt,
                principal_part + interest_portion,
                principal_part,
                interest_portion
            );

            principal_remaining := principal_remaining - principal_part;
            EXIT WHEN principal_remaining <= 0.009;
        END LOOP;

        IF r_loan.status = 'defaulted' AND principal_remaining > 100 THEN
            INSERT INTO loans.delinquencies (loan_id, days_past_due, recorded_at)
            VALUES (
                r_loan.loan_id,
                GREATEST(31, (random() * 140)::int + 1),
                TIMESTAMPTZ '2022-01-01' + make_interval(days => (random() * 600)::int)
            );
        ELSIF random() < 0.12 THEN
            INSERT INTO loans.delinquencies (loan_id, days_past_due, recorded_at)
            VALUES (
                r_loan.loan_id,
                (1 + (random() * 45)::int),
                TIMESTAMPTZ '2021-06-01' + make_interval(days => (random() * 900)::int)
            );
        END IF;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION loans.generate_banking_data IS
    'Populate customers/accounts/loans/payments/delinquencies with synthetic linked data.';
