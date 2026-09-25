# Your steps: Bank Loan Credit Risk Dashboard

Follow the days in order. Code and source preparation are already in this repository. Steps marked **You** require your signed-in desktop or service session. Never paste MySQL passwords or account credentials into chat or Git.

## Current status

- **Prepared:** MySQL 8.0.42, Workbench, Power BI Desktop, official historical archive, a cleaned 39,786-loan CSV, SQL scripts, a date-table query, 12 DAX measures, and local source checks.
- **Not yet verified:** MySQL import and query results, Power BI model and visuals, PBIX file, screenshots, Service publication, and public GitHub link. C: free space fluctuated from about 255 MB to 2.2 GB during this run; free several GB before working in Desktop. Windows already reported a paging-file error.
- **Source decision:** Use `data/financial_loan_clean.csv`, generated from `data/LoanStats3a.csv.zip`. Ignore the older root `financial_loan.csv`: its 2021 issue dates contradict the original archive.
- **Metric meaning:** `issue_date` is the first day of the source's issue month, not an exact issuance day. Every selected loan has a resolved `Fully Paid` or `Charged Off` status. The charged-off share is an observed outcome, not predicted default risk or realized loss.

## Day 1: load and profile in MySQL

1. **You:** Open MySQL Workbench and connect to `MySQL80` with your existing local credentials. No password needs to be sent to me.
2. **You:** Run `sql/00_create_database.sql`. This creates `bank_loan_db.financial_loan` with explicit types. Do not create another table through the import wizard.
3. **You:** In the Schemas panel, right-click `bank_loan_db`, choose **Table Data Import Wizard**, select `data/financial_loan_clean.csv`, and choose the **existing** `financial_loan` table. Match all 16 CSV columns to their same-named table columns. Confirm the first CSV row is treated as headers. Import once.
4. **You:** Run `sql/01_profile_data.sql` one statement at a time. Expected: `row_count = distinct_record_keys = 39786`; statuses `Fully Paid = 34116`, `Charged Off = 5670`; issue range `2007-06-01` to `2011-12-01`; `dates_not_at_month_start = 0`; `issue_months = 55`; no required missing or nonpositive amounts.
5. **You:** Run `sql/02_basic_queries.sql`. Compare portfolio and status outputs to `python tools/verify_clean_data.py`. Save result grids or screenshots. If any count differs, stop before Power BI and check import mapping or duplicate imports.

## Day 2: run analytical SQL

1. **You:** Run `sql/03_cte_grade_risk.sql`, `sql/04_cte_dti_segments.sql`, and `sql/05_cte_monthly_growth.sql` in that order. Save results.
2. Compare Grade A/G and DTI band counts and rates with the verifier output. Month results show origination cohorts and their eventual outcomes, not the calendar month in which a charge-off occurred.
3. Record two highest/lowest MoM changes only with their prior-month counts; very early months have tiny bases and can create misleading percentage swings.

## Day 3: build the Power BI model

1. **You:** After freeing disk space, install [Oracle MySQL Connector/NET](https://dev.mysql.com/downloads/connector/net/). The verified Oracle 26.7.0 installer is already at `data/mysql-connector-net-26.7.0.msi` (MD5 `ac9249c8957115da437366a55ffab7c1`). Restart Power BI Desktop after installation. Desktop itself is installed.
2. **You:** In Desktop, use **Get Data > MySQL database**. Server `localhost`, database `bank_loan_db`, mode **Import**. Authenticate within Desktop and select `financial_loan > Transform Data`. Keep the table name `financial_loan`.
3. Set `issue_date` to Date; amount, `dti`, and `int_rate` to Decimal Number. Add Power Query custom column `DTIBand` with `if [dti] = null then "Unknown" else if [dti] < 0.10 then "Low: <10%" else if [dti] < 0.20 then "Medium: 10-<20%" else "High: >=20%"` and set it to Text.
4. Create a blank query named `DimDate`, paste the full contents of `powerbi/DimDate.m` in Advanced Editor, then **Close & Apply**.
5. In Model view, relate `DimDate[Date]` (one) to `financial_loan[issue_date]` (many), single-direction. Mark `DimDate` as the date table using `[Date]`. Sort `DimDate[MonthYear]` by `[YearMonth]`.

## Day 4: measures and reconciliation

1. **You:** Create each of the 12 formulas in `powerbi/measures.dax` as a separate measure on `financial_loan`. The `.dax` file is a reference list, not a one-click import.
2. Format `Avg Interest Rate`, `Avg DTI`, `Charged Off Share of Resolved`, and `MoM Growth` as Percentage (two decimals). Format funded and received measures as USD currency. Leave counts as whole numbers.
3. Put `Total Loans`, `Total Funded`, `Total Received`, and `Charged Off Loans` on temporary cards. Expected: 39,786; $436,003,725; $486,688,031.90; 5,670. Compare Grade A/G and at least two month values against saved SQL. Resolve any mismatch before making pages.

## Day 5: create three report pages

1. **Summary:** cards for `Total Loans`, `Total Funded`, `Charged Off Share of Resolved`, and `Avg Interest Rate`; status and grade bar charts; monthly loan-count line chart. Add a Year slicer. Chart titles should say **issue month** or **origination**, never **charge-off month**.
2. **Risk Analysis:** matrix with `grade` rows, `DTIBand` columns, and `Resolved Loans` plus `Charged Off Share of Resolved` values; purpose bar chart; grade scatter using `Avg DTI`, `Avg Interest Rate`, and `Total Loans` as bubble size. Display counts beside every rate. Small Grade G sample: 318 loans.
3. **Monthly Trends:** use `DimDate[MonthYear]` on every time axis. Show monthly `Total Funded`, `YTD Funded` in a separate visual, `MoM Growth`, and a detail table with `Total Loans` and `Total Funded`. Do not mix monthly and cumulative amounts on one unlabelled scale.
4. Use **Format > Edit interactions** to check chart selection behavior. A slicer should filter all intended visuals; status selections should not silently change the rate denominator. Add page navigation only after the three pages and filters work.

## Day 6: publish only after validation

1. **You:** Save `bank_loan_dashboard.pbix` in the project root and export one screenshot per page into `screenshots/`. Open the PBIX again and recheck the four Day 4 totals.
2. **You:** Sign in to Power BI Service with your work or education account. Publish to **My Workspace** if your license and tenant allow it. This MySQL Import model is a historical snapshot; scheduled refresh from localhost needs a standard on-premises gateway.
3. **You:** Check whether public reuse of this historical source is permitted before using **Publish to web**. That feature exposes underlying model data to anyone, not just chart images. A normal Share link usually is not an anonymous recruiter link. Test any public link in incognito.
4. **You:** Create a public GitHub repo and push the tracked project files plus the validated PBIX/screenshots if publication is permitted. The raw ZIP, clean CSV, old copied CSV, and credentials are ignored. Add the verified Power BI link to `README.md` only after it works anonymously.

## Day 7: interview proof

1. Memorize exact counts with denominators: 39,786 loans; 5,670 charged off (14.25%); Grade A 602/10,085 (5.97%); Grade G 101/318 (31.76%); high DTI 1,217/7,529 (16.16%); low DTI 1,637/13,219 (12.38%).
2. Explain why the copied source was rejected, why month-year dates were normalized, why only resolved statuses were selected, and how SQL totals were reconciled to DAX.
3. Do not claim DTI causes charge-off, Grade G is underpriced, or that funded amount equals loss. These data support descriptive association only. State cohort size and limitations in the pitch.

### What to send me after Day 1

Send the non-sensitive output of the row-count/status/date checks, any import or SQL error text, and whether Power BI Desktop can connect to MySQL. No password or screenshots containing credentials.
