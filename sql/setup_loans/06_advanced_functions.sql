-- Step 6: advanced functions (default_probability corrected vs. setup_loan_db.md).

SET search_path TO loans, public;

CREATE OR REPLACE FUNCTION loans.remaining_balance(p_loan_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total_principal NUMERIC;
    loan_orig NUMERIC;
BEGIN
    SELECT loan_amount INTO loan_orig FROM loans.loans WHERE loan_id = p_loan_id;
    IF loan_orig IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT COALESCE(SUM(principal_paid), 0) INTO total_principal
    FROM loans.payments WHERE loan_id = p_loan_id;
    RETURN loan_orig - total_principal;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION loans.remaining_balance IS 'Current outstanding principal of a loan';

CREATE OR REPLACE FUNCTION loans.customer_lifetime_value(p_customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total_interest NUMERIC;
BEGIN
    SELECT COALESCE(SUM(p.interest_paid), 0) INTO total_interest
    FROM loans.loans l
    JOIN loans.payments p ON l.loan_id = p.loan_id
    WHERE l.customer_id = p_customer_id;
    RETURN total_interest;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION loans.customer_lifetime_value IS 'Sum of all interest paid by a customer';

CREATE OR REPLACE FUNCTION loans.default_probability(p_customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
    credit              SMALLINT;
    delinquencies_count INT;
    loans_cnt           INT;
    unpaid_loans        INT;
    payment_miss_ratio  NUMERIC;
    score_weight        NUMERIC := 0;
BEGIN
    SELECT credit_score INTO credit
    FROM loans.customers
    WHERE customer_id = p_customer_id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT COUNT(*) INTO delinquencies_count
    FROM loans.delinquencies d
    JOIN loans.loans l ON d.loan_id = l.loan_id
    WHERE l.customer_id = p_customer_id;

    SELECT COUNT(DISTINCT l.loan_id) INTO loans_cnt
    FROM loans.loans l
    WHERE l.customer_id = p_customer_id;

    IF loans_cnt IS NULL OR loans_cnt = 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*) INTO unpaid_loans
    FROM loans.loans l
    WHERE l.customer_id = p_customer_id
      AND NOT EXISTS (
          SELECT 1 FROM loans.payments p WHERE p.loan_id = l.loan_id
      );

    payment_miss_ratio := unpaid_loans::numeric / loans_cnt::numeric;

    score_weight := (850 - credit) / 850.0 * 0.6
                  + LEAST(delinquencies_count, 10) / 10.0 * 0.3
                  + COALESCE(payment_miss_ratio, 0) * 0.1;
    RETURN LEAST(ROUND(score_weight * 100, 2), 100.0);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION loans.default_probability IS 'Heuristic probability of default (0–100%)';
