-- Day 1: Run after importing the CSV as bank_loan_db.financial_loan.
-- Record the output before interpreting any rate or date.
USE bank_loan_db;

-- 1. Confirm column names and inferred MySQL types.
DESCRIBE financial_loan;

-- 2. Check source grain, missing keys, and fields needed for analysis.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT id) AS distinct_loan_ids,
    SUM(id IS NULL) AS missing_ids,
    SUM(issue_date IS NULL) AS missing_issue_dates,
    SUM(loan_status IS NULL OR TRIM(loan_status) = '') AS missing_statuses,
    SUM(loan_amount IS NULL OR loan_amount <= 0) AS missing_or_nonpositive_amounts,
    SUM(dti IS NULL) AS missing_dti,
    SUM(int_rate IS NULL) AS missing_interest_rate
FROM financial_loan;

-- 3. Confirm every status; never classify an unexpected value as charged off.
SELECT loan_status, COUNT(*) AS loan_count
FROM financial_loan
GROUP BY loan_status
ORDER BY loan_count DESC;

-- 4. Inspect date range. Min/max are meaningful only when issue_date is DATE/DATETIME.
SELECT MIN(issue_date) AS first_issue_date,
       MAX(issue_date) AS last_issue_date
FROM financial_loan;

-- 5. Inspect raw units before displaying percentages or setting DTI bands.
SELECT MIN(dti) AS min_dti, ROUND(AVG(dti), 4) AS avg_dti,
       MAX(dti) AS max_dti,
       MIN(int_rate) AS min_interest_rate,
       ROUND(AVG(int_rate), 4) AS avg_interest_rate,
       MAX(int_rate) AS max_interest_rate
FROM financial_loan;

-- 6. Inspect actual rows to check date parsing and numeric values.
SELECT id, issue_date, loan_status, loan_amount, dti, int_rate,
       grade, purpose
FROM financial_loan
ORDER BY id
LIMIT 20;

-- 7. Detect suspicious concentration of issue days before using monthly trends.
SELECT DAY(issue_date) AS issue_day_of_month,
       COUNT(*) AS loan_count
FROM financial_loan
GROUP BY DAY(issue_date)
ORDER BY loan_count DESC;
