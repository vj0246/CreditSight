# Bank Loan Credit Risk Dashboard

Historical loan analysis project using MySQL, Power BI, SQL CTEs, and DAX. The report is intended to compare origination volume and observed repayment outcomes by credit grade, debt-to-income band, and issue month.

## Current status

Source validation and SQL/model code are prepared. The Power BI report and public link are not yet built. The copied 24-column CSV has unreliable issue dates, so its monthly trend must not be presented as historical fact. A verified historical source choice is pending. See [YOUR_STEPS.md](YOUR_STEPS.md) for the exact handoff steps.

## Sources

- Copied 24-column CSV: [anuragsh03/Bank-Loan-Data-Analysis](https://github.com/anuragsh03/Bank-Loan-Data-Analysis), 38,576 rows. Stored locally as ignored `financial_loan.csv`.
- Original historical archive: [LendingClub LoanStats3a.csv.zip](https://resources.lendingclub.com/LoanStats3a.csv.zip), 42,535 loan rows spanning June 2007 to December 2011. Stored locally under ignored `data/`.

The copied CSV's issue date disagrees with the historical archive for a matching loan record. No public report should treat those copied dates as verified origination dates. Source files stay out of Git pending a decision on provenance and redistribution.

## Metric definitions

- **Loan count:** one row per loan in the prepared reporting table.
- **Listed loan amount:** sum of `loan_amount`. This is neither outstanding balance nor realized loss.
- **Resolved loans:** `Fully Paid` plus `Charged Off`.
- **Observed charged-off share of resolved:** charged-off loan count divided by resolved loan count. This is a historical outcome comparison, not a predicted default probability.
- **Current loans:** unresolved; excluded from the resolved denominator when present.
- **Month-over-month growth:** change in listed loan amount by verified issue month.

## Repository map

- `sql/00_create_database.sql`: database setup
- `sql/01_profile_data.sql`: source checks
- `sql/02_basic_queries.sql`: baseline reconciliation queries
- `sql/03_cte_grade_risk.sql`, `sql/04_cte_dti_segments.sql`, `sql/05_cte_monthly_growth.sql`: layered analysis
- `powerbi/DimDate.m`: date dimension query
- `powerbi/measures.dax`: 12 report measures
- `tools/`: reproducible source profiling scripts
- `YOUR_STEPS.md`: actions needed on the Windows machine

## Run locally

Use MySQL Workbench to run the SQL scripts in filename order after importing the selected, cleaned source as `bank_loan_db.financial_loan`. Validate its dates and decimal rate units before running monthly analysis or building visuals. Keep database credentials in Workbench and Power BI credential stores.
