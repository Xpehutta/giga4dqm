-- Step 1–2 from setup_loan_db.md: schema + base tables.

CREATE SCHEMA IF NOT EXISTS loans;
SET search_path TO loans, public;

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
COMMENT ON COLUMN loans.customers.credit_score  IS 'FICO-like range 300–850';
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
    interest_rate NUMERIC(5,2) NOT NULL CHECK (interest_rate >= 0),
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
COMMENT ON COLUMN loans.delinquencies.recorded_at    IS 'Timestamp when delinquency was logged';

CREATE INDEX idx_loans_customer ON loans.loans(customer_id);
CREATE INDEX idx_loans_status   ON loans.loans(status);
CREATE INDEX idx_payments_loan_date ON loans.payments(loan_id, payment_date);
CREATE INDEX idx_delinquencies_loan ON loans.delinquencies(loan_id);
