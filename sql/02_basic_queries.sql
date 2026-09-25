-- Day 1: Run only after sql/01_profile_data.sql confirms expected types.
-- Curated rates are decimal ratios; amounts are USD.
USE bank_loan_db;

-- 1. Portfolio overview: one row must represent one loan.
SELECT COUNT(*) AS loan_count,
       SUM(loan_amount) AS total_listed_loan_amount,
       SUM(funded_amount) AS total_funded_amount,
       SUM(total_payment) AS total_received,
       ROUND(AVG(int_rate) * 100, 2) AS avg_interest_rate_pct,
       ROUND(AVG(dti) * 100, 2) AS avg_dti_pct
FROM financial_loan;

-- 2. Observed status mix. This extract contains only resolved loans.
SELECT loan_status,
       COUNT(*) AS loan_count,
       SUM(funded_amount) AS funded_amount,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM financial_loan), 2)
           AS share_of_all_loans_pct
FROM financial_loan
GROUP BY loan_status
ORDER BY loan_count DESC;

-- 3. Grade-level outcome comparison, among resolved statuses only.
SELECT grade,
       COUNT(*) AS all_loans,
       SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off') THEN 1 ELSE 0 END)
           AS resolved_loans,
       SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
           AS charged_off_loans,
       ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
           / NULLIF(SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off') THEN 1 ELSE 0 END), 0), 2)
           AS charged_off_share_of_resolved_pct
FROM financial_loan
GROUP BY grade
ORDER BY grade;

-- 4. Monthly origination trend. issue_date must be a parsed date.
SELECT DATE_FORMAT(issue_date, '%Y-%m') AS issue_month,
       COUNT(*) AS loans_issued,
       SUM(funded_amount) AS funded_amount
FROM financial_loan
GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
ORDER BY issue_month;

-- 5. Loan purpose: volume and eventual observed charge-off count.
SELECT purpose,
       COUNT(*) AS loan_count,
       SUM(funded_amount) AS funded_amount,
       SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
           AS charged_off_loans
FROM financial_loan
GROUP BY purpose
ORDER BY funded_amount DESC;
