-- Day 2: Observed charge-off outcomes by assigned grade.
-- Only Fully Paid and Charged Off loans are in the prepared extract.
USE bank_loan_db;

WITH grade_status AS (
    SELECT
        grade,
        loan_status,
        COUNT(*) AS loan_count,
        SUM(funded_amount) AS funded_amount
    FROM financial_loan
    GROUP BY grade, loan_status
),
grade_summary AS (
    SELECT
        grade,
        SUM(loan_count) AS all_loans,
        SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off')
            THEN loan_count ELSE 0 END) AS resolved_loans,
        SUM(CASE WHEN loan_status = 'Charged Off'
            THEN loan_count ELSE 0 END) AS charged_off_loans,
        SUM(CASE WHEN loan_status = 'Charged Off'
            THEN funded_amount ELSE 0 END) AS funded_amount_charged_off
    FROM grade_status
    GROUP BY grade
)
SELECT
    grade,
    all_loans,
    resolved_loans,
    charged_off_loans,
    all_loans - resolved_loans AS unresolved_or_other_loans,
    ROUND(100.0 * charged_off_loans / NULLIF(resolved_loans, 0), 2)
        AS charged_off_share_of_resolved_pct,
    funded_amount_charged_off
FROM grade_summary
ORDER BY grade;
