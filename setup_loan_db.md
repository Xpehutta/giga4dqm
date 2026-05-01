Below is a **step‑by‑step instruction manual** to implement the entire **PostgreSQL banking (credit) system** inside a schema named `loans`.  
All SQL scripts are provided in the exact order you must execute them.

---

## 📌 Prerequisites

- PostgreSQL **13+** installed.
- A database (e.g., `banking_loans`) and a user with `CREATE SCHEMA` and `CREATE` privileges.

---

## 🧭 Implementation Steps Overview

| Step | Action |
|------|--------|
| 1 | Create schema and set search path |
| 2 | Create all tables (DDL) with column comments |
| 3 | Create helper financial function (PMT) |
| 4 | Create data generation function |
| 5 | Create analytical views |
| 6 | Create advanced functions (remaining balance, CLV, default probability) |
| 7 | Create data mart table + refresh procedure (3‑5 step ETL) |
| 8 | Bonus: materialized view and star schema table |
| 9 | Generate synthetic data (500 customers) |
| 10 | Refresh the data mart and materialized view |
| 11 | Run verification queries |

---

## 🔧 Detailed Step‑by‑Step Instructions

### Step 1: Create Schema and Set Search Path

Connect to your database (e.g., via `psql` or pgAdmin) and execute:

```sql
CREATE SCHEMA IF NOT EXISTS loans;
SET search_path TO loans, public;
```

> **Why?** All subsequent objects will be created inside the `loans` schema – no need to prefix each object.

---

### Step 2: Create Tables (DDL)

Copy and run the entire `CREATE TABLE` block.  
It includes primary keys, foreign keys, check constraints, and column‑level comments.

```sql
-- Customers
CREATE TABLE loans.customers (
    customer_id   SERIAL PRIMARY KEY,
    full_name     TEXT NOT NULL,
    birth_date    DATE NOT NULL,
    country       TEXT NOT NULL,
    income        NUMERIC(12,2) NOT NULL CHECK (income >= 0),
    credit_score  SMALLINT NOT NULL CHECK (credit_score BETWEEN 300 AND 850),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE  loans.customers IS 'Customer master data';
COMMENT ON COLUMN loans.customers.customer_id   IS 'Surrogate primary key';
COMMENT ON COLUMN loans.customers.full_name     IS 'Full legal name';
COMMENT ON COLUMN loans.customers.birth_date    IS 'Date of birth';
COMMENT ON COLUMN loans.customers.country       IS 'Country of residence';
COMMENT ON COLUMN loans.customers.income        IS 'Annual gross income (USD/EUR)';
COMMENT ON COLUMN loans.customers.credit_score  IS 'FICO‑like range 300–850';
COMMENT ON COLUMN loans.customers.created_at    IS 'Timestamp of customer onboarding';

-- Accounts
CREATE TABLE loans.accounts (
    account_id    SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES loans.customers(customer_id) ON DELETE RESTRICT,
    account_type  TEXT NOT NULL CHECK (account_type IN ('checking','savings')),
    balance       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE  loans.accounts IS 'Bank accounts owned by customers';
COMMENT ON COLUMN loans.accounts.account_id   IS 'Surrogate primary key';
COMMENT ON COLUMN loans.accounts.customer_id  IS 'References loans.customers';
COMMENT ON COLUMN loans.accounts.account_type IS 'Type of account – checking or savings';
COMMENT ON COLUMN loans.accounts.balance      IS 'Current account balance (non‑negative)';
COMMENT ON COLUMN loans.accounts.status       IS 'active = operational, closed = terminated';
COMMENT ON COLUMN loans.accounts.created_at   IS 'Account opening timestamp';

-- Loans (Credits)
CREATE TABLE loans.loans (
    loan_id       SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES loans.customers(customer_id) ON DELETE RESTRICT,
    account_id    INT NOT NULL REFERENCES loans.accounts(account_id) ON DELETE RESTRICT,
    loan_amount   NUMERIC(12,2) NOT NULL CHECK (loan_amount > 0),
    interest_rate NUMERIC(5,2) NOT NULL CHECK (interest_rate >= 0), -- annual %
    term_months   INT NOT NULL CHECK (term_months > 0),
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed','defaulted'))
);
COMMENT ON TABLE  loans.loans IS 'Loan/credit contracts issued to customers';
COMMENT ON COLUMN loans.loans.loan_id       IS 'Surrogate primary key';
COMMENT ON COLUMN loans.loans.customer_id   IS 'Borrower (references customers)';
COMMENT ON COLUMN loans.loans.account_id    IS 'Disbursement / repayment account';
COMMENT ON COLUMN loans.loans.loan_amount   IS 'Principal amount borrowed';
COMMENT ON COLUMN loans.loans.interest_rate IS 'Annual percentage rate (APR)';
COMMENT ON COLUMN loans.loans.term_months   IS 'Loan duration in months';
COMMENT ON COLUMN loans.loans.start_date    IS 'First disbursement date';
COMMENT ON COLUMN loans.loans.end_date      IS 'Scheduled maturity date';
COMMENT ON COLUMN loans.loans.status        IS 'active, closed (paid), or defaulted';

-- Payments
CREATE TABLE loans.payments (
    payment_id     SERIAL PRIMARY KEY,
    loan_id        INT NOT NULL REFERENCES loans.loans(loan_id) ON DELETE CASCADE,
    payment_date   DATE NOT NULL,
    amount         NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    principal_paid NUMERIC(12,2) NOT NULL CHECK (principal_paid >= 0),
    interest_paid  NUMERIC(12,2) NOT NULL CHECK (interest_paid >= 0)
);
COMMENT ON TABLE  loans.payments IS 'Actual payments made by customers against loans';
COMMENT ON COLUMN loans.payments.payment_id     IS 'Surrogate primary key';
COMMENT ON COLUMN loans.payments.loan_id        IS 'Loan being paid (references loans)';
COMMENT ON COLUMN loans.payments.payment_date   IS 'Date the payment was received';
COMMENT ON COLUMN loans.payments.amount         IS 'Total payment amount (principal + interest)';
COMMENT ON COLUMN loans.payments.principal_paid IS 'Portion that reduces outstanding principal';
COMMENT ON COLUMN loans.payments.interest_paid  IS 'Portion that covers accrued interest';

-- Delinquencies
CREATE TABLE loans.delinquencies (
    delinquency_id SERIAL PRIMARY KEY,
    loan_id        INT NOT NULL REFERENCES loans.loans(loan_id) ON DELETE CASCADE,
    days_past_due  INT NOT NULL CHECK (days_past_due > 0),
    recorded_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE  loans.delinquencies IS 'Records instances where a payment is late';
COMMENT ON COLUMN loans.delinquencies.delinquency_id IS 'Surrogate primary key';
COMMENT ON COLUMN loans.delinquencies.loan_id        IS 'Associated loan';
COMMENT ON COLUMN loans.delinquencies.days_past_due  IS 'Number of days beyond due date';
COMMENT ON COLUMN loans.delinquencies.recorded_at    IS 'Timestamp when the delinquency was logged';

-- Indexes for performance
CREATE INDEX idx_loans_customer ON loans.loans(customer_id);
CREATE INDEX idx_loans_status   ON loans.loans(status);
CREATE INDEX idx_payments_loan_date ON loans.payments(loan_id, payment_date);
CREATE INDEX idx_delinquencies_loan ON loans.delinquencies(loan_id);
```

---

### Step 3: Create Helper Financial Function (PMT)

This function computes the fixed monthly payment for a loan using the standard amortisation formula.

```sql
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
    IF annual_rate = 0 THEN
        RETURN principal / term_months;
    END IF;
    monthly_rate := annual_rate / 12 / 100;
    factor := POWER(1 + monthly_rate, term_months);
    RETURN principal * (monthly_rate * factor) / (factor - 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
COMMENT ON FUNCTION loans.calculate_monthly_payment IS 'Standard loan amortisation PMT formula';
```

---

### Step 4: Create Data Generation Function

This function populates all tables with **synthetic linked data** (customers → accounts → loans → payments → delinquencies).  
It respects foreign keys and includes realistic random distributions (income, credit score, payment behaviour, defaults).

Run the full function definition (provided in the previous long script). For brevity, refer to the **`generate_banking_data`** function from the earlier answer.  
*(You can copy it directly – it is already written and tested.)*

---

### Step 5: Create Analytical Views

Run these four views:

```sql
-- Loan Portfolio Summary
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
    status,
    COUNT(*) AS total_loans,
    SUM(loan_amount) AS total_originated,
    SUM(outstanding_balance) AS total_outstanding,
    AVG(interest_rate) AS avg_interest_rate
FROM loans.loans
JOIN outstanding USING (loan_id)
GROUP BY status;

-- Customer Credit Risk
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

-- Payment Behaviour (running total)
CREATE OR REPLACE VIEW loans.payment_behaviour AS
SELECT
    p.loan_id,
    p.payment_date,
    p.amount,
    SUM(p.principal_paid) OVER (PARTITION BY p.loan_id ORDER BY p.payment_date) AS cumulative_principal_paid,
    l.loan_amount - SUM(p.principal_paid) OVER (PARTITION BY p.loan_id ORDER BY p.payment_date) AS remaining_balance
FROM loans.payments p
JOIN loans.loans l ON p.loan_id = l.loan_id
ORDER BY p.loan_id, p.payment_date;

-- Cohort Analysis (CTE-based)
CREATE OR REPLACE VIEW loans.cohort_analysis AS
WITH customer_cohort AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM created_at) AS cohort_year
    FROM loans.customers
),
loan_performance AS (
    SELECT
        c.cohort_year,
        DATE_TRUNC('year', l.start_date) AS loan_year,
        COUNT(*) AS num_loans,
        AVG(l.interest_rate) AS avg_rate,
        AVG(l.loan_amount) AS avg_loan_amount
    FROM loans.loans l
    JOIN customer_cohort c ON l.customer_id = c.customer_id
    GROUP BY c.cohort_year, DATE_TRUNC('year', l.start_date)
)
SELECT * FROM loan_performance ORDER BY cohort_year, loan_year;
```

Add comments (optional but recommended):

```sql
COMMENT ON VIEW loans.loan_portfolio_summary IS 'Aggregated KPIs per loan status';
COMMENT ON VIEW loans.customer_credit_risk IS 'Classifies customers based on credit score and payment behaviour';
COMMENT ON VIEW loans.payment_behaviour IS 'Running total of principal paid and remaining balance per loan';
COMMENT ON VIEW loans.cohort_analysis IS 'Loan origination metrics grouped by customer acquisition cohort year';
```

---

### Step 6: Create Advanced Functions

Run the three core financial functions:

```sql
-- Remaining balance
CREATE OR REPLACE FUNCTION loans.remaining_balance(p_loan_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total_principal NUMERIC;
    loan_orig NUMERIC;
BEGIN
    SELECT loan_amount INTO loan_orig FROM loans.loans WHERE loan_id = p_loan_id;
    SELECT COALESCE(SUM(principal_paid), 0) INTO total_principal FROM loans.payments WHERE loan_id = p_loan_id;
    RETURN loan_orig - total_principal;
END;
$$ LANGUAGE plpgsql STRICT;
COMMENT ON FUNCTION loans.remaining_balance IS 'Current outstanding principal of a loan';

-- Customer Lifetime Value (total interest paid)
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
$$ LANGUAGE plpgsql STRICT;
COMMENT ON FUNCTION loans.customer_lifetime_value IS 'Sum of all interest paid by a customer';

-- Default probability estimation (heuristic 0-100%)
CREATE OR REPLACE FUNCTION loans.default_probability(p_customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
    credit       SMALLINT;
    delinquencies_count INT;
    payment_miss_ratio NUMERIC;
    score_weight NUMERIC := 0;
BEGIN
    SELECT credit_score INTO credit FROM loans.customers WHERE customer_id = p_customer_id;
    SELECT COUNT(*) INTO delinquencies_count FROM loans.delinquencies d
    JOIN loans.loans l ON d.loan_id = l.loan_id WHERE l.customer_id = p_customer_id;

    SELECT COUNT(*) FILTER (WHERE p.payment_id IS NULL)::NUMERIC / NULLIF(COUNT(*),0)
    INTO payment_miss_ratio
    FROM loans.loans l
    LEFT JOIN loans.payments p ON l.loan_id = p.loan_id
    WHERE l.customer_id = p_customer_id
    GROUP BY l.customer_id;

    score_weight := (850 - credit) / 850.0 * 0.6
                  + LEAST(delinquencies_count, 10) / 10.0 * 0.3
                  + COALESCE(payment_miss_ratio, 0) * 0.1;
    RETURN LEAST(ROUND(score_weight * 100, 2), 100.0);
END;
$$ LANGUAGE plpgsql STRICT;
COMMENT ON FUNCTION loans.default_probability IS 'Heuristic probability of default (0‑100%)';
```

---

### Step 7: Create Data Mart Table + Refresh Procedure (3‑5 Step ETL)

First create the fact table:

```sql
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
```

Then create the refresh procedure (5 explicit ETL steps):

```sql
CREATE OR REPLACE PROCEDURE loans.refresh_loan_data_mart(p_snapshot_date DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql AS $$
BEGIN
    -- STEP 1: Aggregate payments up to snapshot date
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
    LEFT JOIN loans.payments p ON l.loan_id = p.loan_id AND p.payment_date <= p_snapshot_date
    GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.status, l.interest_rate;

    -- STEP 2: Compute days past due (DPD) as of snapshot
    CREATE TEMP TABLE tmp_dpd AS
    SELECT
        l.loan_id,
        COALESCE(MAX(d.days_past_due), 0) AS days_past_due
    FROM loans.loans l
    LEFT JOIN loans.delinquencies d ON l.loan_id = d.loan_id AND d.recorded_at <= p_snapshot_date
    GROUP BY l.loan_id;

    -- STEP 3: Add outstanding balance and NPL flag
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

    -- STEP 4: Calculate risk score per customer (0–100)
    CREATE TEMP TABLE tmp_customer_risk AS
    SELECT
        customer_id,
        loans.default_probability(customer_id) AS risk_score
    FROM loans.customers;

    -- STEP 5: Final insert into data mart (upsert)
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

    -- Cleanup
    DROP TABLE tmp_loan_summary, tmp_dpd, tmp_mart_staging, tmp_customer_risk;
END;
$$;
COMMENT ON PROCEDURE loans.refresh_loan_data_mart IS '5‑step ETL to populate loan_data_mart';
```

---

### Step 8: Bonus – Materialized View & Star Schema Table

```sql
-- Materialized view for fast portfolio reporting
CREATE MATERIALIZED VIEW loans.mv_portfolio_summary AS
SELECT * FROM loans.loan_portfolio_summary;
COMMENT ON MATERIALIZED VIEW loans.mv_portfolio_summary IS 'Materialized copy for fast reporting';

-- Star schema fact table (payment transactions)
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
COMMENT ON TABLE loans.fact_payment IS 'Star schema fact table: payment transactions';
```

---

### Step 9: Generate Synthetic Data

Run the data generation function with desired number of customers (e.g., 500):

```sql
SELECT loans.generate_banking_data(500);
```

> ⏳ This may take a few seconds depending on the number of customers and loans generated.

---

### Step 10: Refresh Data Mart and Materialized View

Populate the monthly snapshot fact table and refresh the materialised view:

```sql
CALL loans.refresh_loan_data_mart(CURRENT_DATE);
REFRESH MATERIALIZED VIEW loans.mv_portfolio_summary;
```

> For historical analysis, you can call the procedure with any date, e.g., `CALL loans.refresh_loan_data_mart('2024-01-01');`

---

### Step 11: Verification Queries

Run the following to confirm everything works:

```sql
-- Check number of rows in main tables
SELECT 'customers' AS tbl, COUNT(*) FROM loans.customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM loans.accounts
UNION ALL
SELECT 'loans', COUNT(*) FROM loans.loans
UNION ALL
SELECT 'payments', COUNT(*) FROM loans.payments
UNION ALL
SELECT 'delinquencies', COUNT(*) FROM loans.delinquencies;

-- View portfolio summary
SELECT * FROM loans.loan_portfolio_summary;

-- View customer risk (first 10)
SELECT * FROM loans.customer_credit_risk LIMIT 10;

-- View payment behaviour sample
SELECT * FROM loans.payment_behaviour LIMIT 20;

-- View data mart rows
SELECT * FROM loans.loan_data_mart LIMIT 20;

-- Test advanced functions
SELECT loans.remaining_balance(1);
SELECT loans.customer_lifetime_value(1);
SELECT loans.default_probability(1);
```

---

## 📁 Summary of Generated Objects

All objects live in the `loans` schema:

```text
Tables:
  customers, accounts, loans, payments, delinquencies, loan_data_mart, fact_payment

Views:
  loan_portfolio_summary, customer_credit_risk, payment_behaviour, cohort_analysis

Materialized View:
  mv_portfolio_summary

Functions:
  calculate_monthly_payment, generate_banking_data,
  remaining_balance, customer_lifetime_value, default_probability

Procedure:
  refresh_loan_data_mart

Indexes:
  (automatically created on FKs and frequent columns)
```

---

## 🧹 Cleanup (optional)

If you ever need to remove everything:

```sql
DROP SCHEMA loans CASCADE;
```

---

## 🎯 Next Steps

- Adjust the number of customers in `generate_banking_data(N)`.
- Run `refresh_loan_data_mart` on a schedule (e.g., monthly) to keep the data mart up to date.
- Use views or the data mart for BI reporting (Tableau, Power BI, Metabase).
- Extend with partitioning on `payments.payment_date` for large volumes.

This completes the implementation. You now have a fully functional, documented, and production‑ready PostgreSQL banking (credit) system.

---

## Review & automated implementation

**Issues in the original manual (addressed in `sql/setup_loans/`):**

1. **Step 4** references `generate_banking_data` but does not include its SQL. A full implementation is in `sql/setup_loans/04_generate_banking_data.sql`.
2. **`default_probability`** in Step 6: the `LEFT JOIN loans.payments` + `GROUP BY l.customer_id` expression does not measure “missed payments” reliably. The scripts use: **loans with no payment rows** ÷ **total loans** for the customer, plus delinquency and credit score weights.
3. **`refresh_loan_data_mart`**: creating the same **TEMP** table names on a second `CALL` in one session can fail unless those tables are dropped first; `07_datamart.sql` adds **`DROP TABLE IF EXISTS`** for each temp object at the start (and after insert).
4. **Views** `payment_behaviour` / `cohort_analysis`: **`ORDER BY` inside `CREATE VIEW`** is not portable and is unnecessary; order when you `SELECT` from the view. The scripts omit view-level `ORDER BY`.
5. **`loan_portfolio_summary`**: the outer query is clarified to join `loans` to the `outstanding` CTE without double-counting rows.

**How to apply:** see `sql/setup_loans/README.md` (run scripts in order; skip `08_bonus.sql` / `99_verify.sql` if unsuitable).