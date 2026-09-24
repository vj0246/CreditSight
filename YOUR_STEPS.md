# Your actions: Bank Loan Credit Risk Dashboard

This file is the handoff checklist. Complete Day 1 in order, then send the requested results so the SQL and Power BI model can be tied to your exact CSV. Do not put passwords or credentials in this repository or in chat.

## Current workspace status

- MySQL Server 8.0.42 and Workbench are installed; the `MySQL80` service is running.
- The copied `financial_loan.csv` is present and profiled: 38,576 rows, 38,576 distinct IDs, no missing required fields. Its issue dates disagree with LendingClub's historical source. Do not use its month chart as a historical lending trend.
- LendingClub's official historical archive is present in ignored `data/LoanStats3a.csv.zip`. Source choice is pending: switch to it for accurate issue months, or keep the copied CSV with an explicit date limitation.
- Root database access requires your local password. Run SQL in Workbench; never send the password.
- Power BI Desktop is absent. Installation failed while C: had about 389 MB free. Free several GB before the Desktop build can proceed.

The older Day 1 instructions below remain as a reproducibility guide. Steps 1–3 are already handled on this machine; complete the Workbench import and send query results after choosing the data source.

## Day 1: setup and source verification

1. Install [MySQL Community Server](https://dev.mysql.com/downloads/mysql/) 8.0+ and [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) on Windows. Confirm Workbench connects to your local server. Save the database password in your password manager.
2. Download one exact `financial_loan.csv` source. Suggested file to inspect: [anuragsh03/Bank-Loan-Data-Analysis](https://github.com/anuragsh03/Bank-Loan-Data-Analysis), which lists a CSV and a repository MIT license. Record the URL you actually use. Do not assume that the repository license establishes ownership of the underlying data.
3. Place the CSV in this project root as `financial_loan.csv`. The file is ignored by Git until its provenance and publication rights are clear.
4. In MySQL Workbench, open and run `sql/00_create_database.sql`.
5. In Workbench's Schemas panel, right-click `bank_loan_db` and choose **Table Data Import Wizard**. Select the CSV, create table `financial_loan`, and review all column names and inferred types before finishing. `issue_date` must become `DATE` or `DATETIME`; numeric columns must be numeric. If the wizard cannot parse dates, stop and report the raw date format. Do not guess a conversion format.
6. Run `sql/01_profile_data.sql`, one statement at a time. Check that `row_count = distinct_loan_ids`, required fields have no unexpected nulls, statuses are understood, and dates are valid. Write down raw DTI and interest ranges; do not convert them yet.
7. If profiling passes, run all five statements in `sql/02_basic_queries.sql`. Save the result grids or export each result as CSV. Record exact row count, first and last issue dates, status counts, Grade A/G counts and rates, and highest-volume month.
8. Sign in to [Power BI Service](https://app.powerbi.com/) with a work or education account and note the license shown under your profile. If an administrator controls the account, ask whether **Publish to web** is allowed. The final public-link test happens on Day 6, after a report exists. A normal Share link is not a public recruiter link. Do not publish any data yet.

### Send back after Day 1

- CSV source URL and confirmation that `financial_loan.csv` is in this folder.
- MySQL version and whether import completed.
- Output of profile steps 2–5 from `sql/01_profile_data.sql` (no credentials).
- Any SQL or import error text.
- Whether Power BI Service sign-in works, your license type, and any known Publish to web restriction.

## Day 2: SQL risk analysis

1. After importing the chosen, cleaned source, run `sql/03_cte_grade_risk.sql` and `sql/04_cte_dti_segments.sql` in Workbench.
2. Confirm Grade A/G loan counts and DTI band counts against the source profile. Compare rates only among `Fully Paid` and `Charged Off` loans; `Current` is unresolved.
3. Run `sql/05_cte_monthly_growth.sql` only if the chosen source has verified issue dates. The copied CSV's issue dates cannot support a truthful historical trend.
4. Save the result grids for later SQL-to-DAX reconciliation. Do not write a headline insight until the chosen source and exact counts are fixed.

## Day 3: Power BI model

1. After freeing disk space, install [Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-get-the-desktop) and [Oracle MySQL Connector/NET](https://dev.mysql.com/downloads/connector/net/). Restart Power BI Desktop after installing the connector.
2. In Desktop, choose **Get Data > MySQL database**. Server: `localhost`; database: `bank_loan_db`; mode: **Import**. Sign in with your local database credentials in the app.
3. Choose table `financial_loan`, then **Transform Data**. Keep its query name `financial_loan`; the prepared DAX uses that name. Confirm `issue_date` is Date, `loan_amount` numeric, `dti` and `int_rate` decimal ratios.
   Add a Custom Column named `DTIBand` with this Power Query expression: `if [dti] = null then "Unknown" else if [dti] < 0.10 then "Low: <10%" else if [dti] < 0.20 then "Medium: 10-<20%" else "High: >=20%"`. Set its type to Text.
4. Create a **Blank Query** named `DimDate`; paste the full contents of `powerbi/DimDate.m` into Advanced Editor. Close & Apply.
5. In Model view, connect `DimDate[Date]` (one side) to `financial_loan[issue_date]` (many side), with single-direction filtering. Mark `DimDate` as the date table using its `Date` column.
6. In Data view, select `DimDate[MonthYear]` and set **Sort by column** to `DimDate[YearMonth]`. Verify dates span the chosen source's actual range.

## Day 4: measures and reconciliation

1. Create each of the 12 formulas in `powerbi/measures.dax` as a separate measure on `financial_loan`. Do not paste the whole file into one measure.
2. Format rate and DTI measures as Percentage with two decimals; amount measures as Currency. Avoid `FORMAT()` inside measures because it turns numbers into text.
3. Add temporary cards for `Total Loans`, `Listed Loan Amount`, `Charged Off Loans`, and `Resolved Loans`; compare each with SQL. Add a grade table and compare Grade A/G counts and rates. Add a `MonthYear` table and compare at least two monthly amounts with SQL.
4. Resolve any mismatch before building pages. Check source selection, date types, relationship direction, and status spelling.

## Day 5: report pages

1. **Summary:** four cards (`Total Loans`, `Listed Loan Amount`, `Charged Off Share of Resolved`, `Avg Interest Rate`); a status bar chart (`loan_status` by `Total Loans`); a grade bar chart (`grade` by `Total Loans`); a monthly line chart (`DimDate[MonthYear]` by `Total Loans`). Add a year slicer only if the chosen source contains multiple years.
2. **Risk Analysis:** a matrix with `grade` rows, `DTIBand` columns, and `Resolved Loans` plus `Charged Off Share of Resolved` values; a purpose bar chart; and a grade scatter chart with average DTI, average interest, and sample size. Never put `loan_status` on the matrix columns for the charged-off rate measure.
3. **Monthly Trends:** use `DimDate[MonthYear]` on every time axis, sorted by `YearMonth`. Show monthly amount, a separate YTD view, a MoM growth chart, and a detail table with loan count and amount. Do not put monthly and YTD amounts on the same scale.
4. Use consistent labels and navigation. Keep `Current` visually separate if present. Show sample sizes beside risk rates and explain that the data is historical.
   In **Format > Edit interactions**, stop the status chart from filtering charged-off-rate visuals; selecting a single status would change the meaning of their denominator.

## Day 6: publication and GitHub

1. Check all three pages at normal desktop width, filter every visual, and compare the monthly detail table with SQL.
2. Save the PBIX. Publish it to your Power BI Service workspace. A local MySQL connection needs a standard on-premises gateway for refresh; without one, describe the report as an imported historical snapshot.
3. If the tenant permits it and the dataset can be exposed publicly, create a **Publish to web** link. Test it in an incognito window. Do not use a normal Share link as a public portfolio URL.
4. Create a public GitHub repository with the PBIX, SQL, source-processing scripts, three report screenshots, and a README containing verified metrics and source attribution. Keep source CSV/ZIP and credentials out of Git unless redistribution rights are confirmed.

## Day 7: interview proof

1. Record exact portfolio, grade, DTI, and month figures from the final source. Note sample size beside each rate.
2. Practice a one-minute explanation of the source, SQL checks, date model, 12 measures, and the strongest measured finding.
3. Explain that a charged-off share among resolved loans is an observed historical outcome, not a forward-looking default probability. Discuss differences by grade and DTI as associations, not proof of causation.
4. Verify the PBIX opens, screenshots match it, GitHub is public, and the public link works without sign-in before adding links to a resume.
