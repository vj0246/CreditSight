# Bank Loan Credit Risk Dashboard

Purpose: Build a seven-day loan-outcome portfolio report with MySQL validation, a refreshable cloud-file Power BI model, and a public aggregate-only companion site. Keep every metric traceable to source fields and SQL checks.

## Stack

- MySQL 8.0+ and MySQL Workbench
- Python 3.10 for local source profiling scripts
- Power BI Desktop, current Windows release, and work/school OneDrive or SharePoint for gateway-free cloud-file refresh
- Companion site: Vinext, React, TypeScript, Sites hosting
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
- Run `python tools/export_companion_data.py`, then `npm run build`, `npm run lint`, and `node --test tests/rendered-html.test.mjs` in `companion-site/` for the public snapshot.
- Create the Power BI loan query from `powerbi/FactLoans_SharePoint.m`; Service refresh still needs signed-in verification.
- Database SQL requires a local Workbench login; no unattended database credentials are stored.

## Directory map

- `sql/`: database setup, data profiling, and analytical queries
- `tools/`: source profiling scripts
- `data/`: ignored source archive and generated CSV
- `powerbi/`: Power Query and DAX source for the user-built PBIX
- `companion-site/`: separately versioned public site with aggregate-only JSON; its nested Git repository is for Sites hosting
- `YOUR_STEPS.md`: user actions and checkpoints by day
- `financial_loan.csv`: local source data, excluded from Git pending provenance review

## Environment variables

- None. Keep MySQL credentials in Workbench and Microsoft credentials in Power BI credential storage.

## Known gotchas

- Prepared data contains only `Fully Paid` and `Charged Off` outcomes; original archive has other statuses that are excluded.
- Prepared DTI and interest are decimal ratios; original archive stores percentage-point values.
- `loan_amount` is listed principal; `funded_amount` is funded principal, not outstanding exposure or loss.
- The copied 24-column CSV's 2021 issue dates disagree with LendingClub's original 2007-2011 archive; do not use its monthly trend as historical fact.
- Power BI Desktop is installed; the user reported clearing disk space. Confirm free space before report work.
- Oracle Connector/NET installation failed with Windows error 1925 (needs admin rights). It is not needed for the chosen SharePoint-file Power BI source.
- Use Table Data Import Wizard for CSV, not Server Data Import.
- A local MySQL source requires a standard gateway for Power BI Service refresh; the chosen no-cost cloud-file path avoids it. MySQL remains the independent validation layer, not the published model source.
- The companion site is a fixed historical aggregate snapshot and does not refresh when the OneDrive CSV changes.
