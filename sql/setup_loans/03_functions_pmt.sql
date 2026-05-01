-- Step 3: PMT helper (setup_loan_db.md).
SET search_path TO loans, public;

CREATE OR REPLACE FUNCTION loans.calculate_monthly_payment(
    principal NUMERIC,
    annual_rate NUMERIC,
    term_months INT
)
RETURNS NUMERIC AS $$
DECLARE
    monthly_rate NUMERIC;
    factor NUMERIC;
BEGIN
    IF principal IS NULL OR term_months IS NULL OR term_months <= 0 THEN
        RETURN NULL;
    END IF;
    IF COALESCE(principal, 0) <= 0 THEN
        RETURN 0;
    END IF;
    IF annual_rate = 0 THEN
        RETURN principal / term_months;
    END IF;
    monthly_rate := annual_rate / 12 / 100;
    factor := POWER(1 + monthly_rate, term_months);
    IF factor = 1 THEN
        RETURN principal / term_months;
    END IF;
    RETURN principal * (monthly_rate * factor) / (factor - 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

COMMENT ON FUNCTION loans.calculate_monthly_payment IS 'Standard loan amortisation PMT formula';
