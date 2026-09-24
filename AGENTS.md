# Bank Loan Credit Risk Dashboard

Purpose: Build a seven-day MySQL-to-Power BI portfolio report on loan origination and observed charge-off outcomes. Keep every reported metric traceable to source fields and SQL checks.

## Stack

- MySQL 8.0+ and MySQL Workbench
- Python 3.10 for local source profiling scripts
- Power BI Desktop, current Windows release, with Oracle MySQL Connector/NET
- SQL dialect: MySQL 8.0+
- Git and GitHub for versioned SQL and report artifacts

## Run and verify

- Run `sql/00_create_database.sql` in MySQL Workbench.
- Import `financial_loan.csv` with Workbench Table Data Import Wizard as `bank_loan_db.financial_loan`.
- Run `sql/01_profile_data.sql`; inspect data types, nulls, statuses, units, and dates.
- Run `sql/02_basic_queries.sql` after profile checks pass; save results for Power BI reconciliation.
- Run `python tools/profile_source.py` to reproduce the copied CSV quality checks.
- Run `python tools/check_official_archive.py` to inspect the official historical archive.
- Database SQL requires a local Workbench login; no unattended database credentials are stored.

## Directory map

- `sql/`: database setup, data profiling, and analytical queries
- `tools/`: source profiling scripts
- `data/`: ignored source archives
- `YOUR_STEPS.md`: user actions and checkpoints by day
- `financial_loan.csv`: local source data, excluded from Git pending provenance review

## Environment variables

- None. Keep MySQL credentials in Workbench and Power BI credential stores.

## Known gotchas

- `Current` loans are unresolved outcomes, not successful repayments.
- Confirm DTI and interest units from actual rows before converting to percentages.
- `loan_amount` may represent original amount, not outstanding exposure or loss.
- The copied 24-column CSV's 2021 issue dates disagree with LendingClub's original 2007-2011 archive; do not use its monthly trend as historical fact.
- C: currently lacks space for Power BI Desktop; installation requires user-managed cleanup.
- Use Table Data Import Wizard for CSV, not Server Data Import.
- A local MySQL source requires a standard gateway for Power BI Service refresh.
