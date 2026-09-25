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
- Run `python tools/prepare_official_data.py` and `python tools/verify_clean_data.py`.
- Import `data/financial_loan_clean.csv` into the existing `bank_loan_db.financial_loan` table with Workbench Table Data Import Wizard.
- Run `sql/01_profile_data.sql`; inspect data types, nulls, statuses, units, and dates.
- Run `sql/02_basic_queries.sql` after profile checks pass; save results for Power BI reconciliation.
- Run `python tools/profile_source.py` only to inspect the rejected copied CSV.
- Run `python tools/check_official_archive.py` to inspect the original archive.
- Database SQL requires a local Workbench login; no unattended database credentials are stored.

## Directory map

- `sql/`: database setup, data profiling, and analytical queries
- `tools/`: source profiling scripts
- `data/`: ignored source archive and generated CSV
- `YOUR_STEPS.md`: user actions and checkpoints by day
- `financial_loan.csv`: local source data, excluded from Git pending provenance review

## Environment variables

- None. Keep MySQL credentials in Workbench and Power BI credential stores.

## Known gotchas

- Prepared data contains only `Fully Paid` and `Charged Off` outcomes; original archive has other statuses that are excluded.
- Prepared DTI and interest are decimal ratios; original archive stores percentage-point values.
- `loan_amount` is listed principal; `funded_amount` is funded principal, not outstanding exposure or loss.
- The copied 24-column CSV's 2021 issue dates disagree with LendingClub's original 2007-2011 archive; do not use its monthly trend as historical fact.
- Power BI Desktop is installed, but C: has about 255 MB free and Windows reported a paging-file error; free several GB before connector installation or report work.
- Oracle Connector/NET installer is downloaded and checksum-verified, not installed. Authenticated Workbench import remains to verify.
- Use Table Data Import Wizard for CSV, not Server Data Import.
- A local MySQL source requires a standard gateway for Power BI Service refresh.
