-- Day 2: Compare observed outcomes by DTI band.
-- dti must be a ratio (0.20 = 20%). Check sql/01_profile_data.sql first.
-- These are associations, not causal effects or underwriting recommendations.
USE bank_loan_db;

WITH segmented AS (
    SELECT
        grade,
        loan_status,
        loan_amount,
        CASE
            WHEN dti IS NULL THEN 'Unknown'
            WHEN dti < 0.10 THEN 'Low: <10%'
            WHEN dti < 0.20 THEN 'Medium: 10-<20%'
            ELSE 'High: >=20%'
        END AS dti_band
    FROM financial_loan
),
grade_band_counts AS (
    SELECT
        dti_band,
        grade,
        COUNT(*) AS all_loans,
        SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1 ELSE 0 END) AS resolved_loans,
        SUM(CASE WHEN loan_status = 'Charged Off'
            THEN 1 ELSE 0 END) AS charged_off_loans,
        SUM(loan_amount) AS listed_loan_amount
    FROM segmented
    GROUP BY dti_band, grade
)
SELECT
    dti_band,
    grade,
    all_loans,
    resolved_loans,
    charged_off_loans,
    ROUND(100.0 * charged_off_loans / NULLIF(resolved_loans, 0), 2)
        AS charged_off_share_of_resolved_pct,
    listed_loan_amount
FROM grade_band_counts
ORDER BY FIELD(dti_band, 'Low: <10%', 'Medium: 10-<20%', 'High: >=20%', 'Unknown'), grade;

-- Aggregate counts first; never average grade-level percentages to compare bands.
WITH segmented AS (
    SELECT
        CASE
            WHEN dti IS NULL THEN 'Unknown'
            WHEN dti < 0.10 THEN 'Low: <10%'
            WHEN dti < 0.20 THEN 'Medium: 10-<20%'
            ELSE 'High: >=20%'
        END AS dti_band,
        loan_status
    FROM financial_loan
),
band_counts AS (
    SELECT
        dti_band,
        COUNT(*) AS all_loans,
        SUM(CASE WHEN loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1 ELSE 0 END) AS resolved_loans,
        SUM(CASE WHEN loan_status = 'Charged Off'
            THEN 1 ELSE 0 END) AS charged_off_loans
    FROM segmented
    GROUP BY dti_band
)
SELECT
    dti_band,
    all_loans,
    resolved_loans,
    charged_off_loans,
    ROUND(100.0 * charged_off_loans / NULLIF(resolved_loans, 0), 2)
        AS charged_off_share_of_resolved_pct
FROM band_counts
ORDER BY FIELD(dti_band, 'Low: <10%', 'Medium: 10-<20%', 'High: >=20%', 'Unknown');
