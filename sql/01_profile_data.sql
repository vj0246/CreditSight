-- Day 1: Run after importing data/financial_loan_clean.csv.
-- Record the output before interpreting any rate or date.
USE bank_loan_db;

-- 1. Confirm column names and inferred MySQL types.
DESCRIBE financial_loan;

-- 2. Check source grain, missing keys, and fields needed for analysis.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT loan_record_key) AS distinct_record_keys,
    SUM(issue_date IS NULL) AS missing_issue_dates,
    SUM(loan_status IS NULL OR TRIM(loan_status) = '') AS missing_statuses,
    SUM(loan_amount IS NULL OR loan_amount <= 0) AS missing_or_nonpositive_listed_amounts,
    SUM(funded_amount IS NULL OR funded_amount <= 0) AS missing_or_nonpositive_funded_amounts,
    SUM(dti IS NULL) AS missing_dti,
    SUM(int_rate IS NULL) AS missing_interest_rate
FROM financial_loan;

-- 3. Confirm every status; never classify an unexpected value as charged off.
SELECT loan_status, COUNT(*) AS loan_count
FROM financial_loan
GROUP BY loan_status
ORDER BY loan_count DESC;

-- 4. Issue dates represent month start in the original archive.
SELECT MIN(issue_date) AS first_issue_date,
       MAX(issue_date) AS last_issue_date
FROM financial_loan;

-- 5. Curated dti and int_rate are decimal ratios.
SELECT MIN(dti) AS min_dti, ROUND(AVG(dti), 4) AS avg_dti,
       MAX(dti) AS max_dti,
       MIN(int_rate) AS min_interest_rate,
       ROUND(AVG(int_rate), 4) AS avg_interest_rate,
       MAX(int_rate) AS max_interest_rate
FROM financial_loan;

-- 6. Inspect actual rows to check date parsing and numeric values.
SELECT loan_record_key, issue_date, loan_status, loan_amount,
       funded_amount, dti, int_rate,
       grade, purpose
FROM financial_loan
ORDER BY loan_record_key
LIMIT 20;

-- 7. Source supplies issue month only; the curated date must be month start.
SELECT SUM(DAY(issue_date) <> 1) AS dates_not_at_month_start,
       COUNT(DISTINCT DATE_FORMAT(issue_date, '%Y-%m')) AS issue_months
FROM financial_loan;
