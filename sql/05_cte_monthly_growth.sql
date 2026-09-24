-- Day 2: Month-over-month change in listed loan amount by issue month.
-- Run only after source issue dates have been verified. The copied 24-column
-- financial_loan.csv fails that check; do not present its output as lending history.
USE bank_loan_db;

WITH monthly_originations AS (
    SELECT
        DATE_FORMAT(issue_date, '%Y-%m') AS issue_month,
        COUNT(*) AS loans_issued,
        SUM(loan_amount) AS listed_loan_amount,
        SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1 ELSE 0 END) AS resolved_loans,
        SUM(CASE WHEN loan_status = 'Charged Off'
            THEN 1 ELSE 0 END) AS charged_off_loans
    FROM financial_loan
    WHERE issue_date IS NOT NULL
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
),
with_prior_month AS (
    SELECT
        issue_month,
        loans_issued,
        listed_loan_amount,
        resolved_loans,
        charged_off_loans,
        LAG(listed_loan_amount) OVER (ORDER BY issue_month)
            AS prior_month_listed_amount
    FROM monthly_originations
)
SELECT
    issue_month,
    loans_issued,
    listed_loan_amount,
    prior_month_listed_amount,
    ROUND(100.0 * (listed_loan_amount - prior_month_listed_amount)
        / NULLIF(prior_month_listed_amount, 0), 2) AS mom_growth_pct,
    resolved_loans,
    charged_off_loans,
    ROUND(100.0 * charged_off_loans / NULLIF(resolved_loans, 0), 2)
        AS observed_charged_off_share_of_resolved_pct
FROM with_prior_month
ORDER BY issue_month;
