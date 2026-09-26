# Your steps: Bank Loan Credit Risk Dashboard

Use this as a working checklist, not as a script to paste into MySQL. Complete days in order. Each step says what to do, why it matters, and what result to check. Never send a password or put credentials in this repository.

## Where the project stands

- You reported completing Days 1 and 2, including matching grade results. Local MySQL output remains user-reported; the prepared CSV was independently rechecked on September 26, 2026.
- Code already prepared: MySQL schema, five baseline queries, three CTE analyses, a Power Query date table, 12 DAX measures, and a CSV verifier.
- Not yet built or verified: the Power BI model, three report pages, PBIX, screenshots, Power BI Service link, and scheduled refresh. The saved `abc.pbix` is only 16 KB and has not been validated as a report.
- The [Vercel dashboard](https://bank-loan-dashboard-site.vercel.app/) is public and serves the latest verified aggregate snapshot. [Dashboard source](https://github.com/vj0246/bank-loan-dashboard-site) and [SQL/Power BI source](https://github.com/vj0246/CreditSight) are on GitHub. The website is not a Power BI report and does not refresh when the cloud CSV changes.
- You chose no-cost cloud refresh and confirmed work/school Microsoft 365 access. Power BI will read the OneDrive/SharePoint CSV; local MySQL remains the analysis and validation layer. Do not claim the published model queries MySQL.
- Use `data/financial_loan_clean.csv`, not the older root `financial_loan.csv`. The older file has unreliable 2021 issue dates. The cleaned file contains 39,786 resolved loans issued from June 2007 through December 2011.
- `issue_date` uses the first day of each issue **month** because the source has no exact issue day. `Charged Off` is an observed outcome, not a predicted default or a dollar loss.

## Day 1: put trustworthy data into MySQL

### 1. Connect to the local server

**Do:** Open MySQL Workbench and connect to the local `MySQL80` server using your own credentials.

**Why:** Workbench is the interface for running the project SQL against your local MySQL server. The CSV alone is not a database.

**Check:** A SQL editor opens and the Schemas panel is visible. Do not send your password to anyone.

### 2. Create the database and typed table

**Do:** In Workbench, choose **File > Open SQL Script**, open `sql/00_create_database.sql`, select the script, and execute it. Do not type the filename into the SQL editor.

**Why:** The script creates `bank_loan_db.financial_loan` with explicit Date, Decimal, and text types. This avoids the import wizard guessing a wrong type, such as treating `issue_date` as text.

**Check:** Refresh Schemas and expand `bank_loan_db > Tables`. You should see `financial_loan`. If not, run `SHOW TABLES FROM bank_loan_db;` and confirm the full script executed.

### 3. Import the prepared CSV into that table

**Do:** Right-click the **`financial_loan` table**, choose **Table Data Import Wizard**, and select `data/financial_loan_clean.csv`. On the destination screen choose the existing table. Map the 16 CSV fields to same-named columns; treat the first row as headers. Import once.

**Why:** This loads the curated historical records into the typed table. Creating a second table would leave later SQL pointed at the wrong data.

**Check:** Run `SELECT COUNT(*) FROM bank_loan_db.financial_loan;`. Expected: `39786`. If it is `0` or smaller, the import failed or skipped rows. Do not import a second time until you understand the cause.

### 4. Profile the imported table

**Do:** Open `sql/01_profile_data.sql` in Workbench and run its seven statements. Read each result grid.

**Why:** A successful wizard message does not prove that the values, types, and dates survived import. Profiling catches nulls, wrong types, missing rows, and unexpected status labels.

**Check:** `row_count = distinct_record_keys = 39786`; `Fully Paid = 34116`; `Charged Off = 5670`; first/last issue dates `2007-06-01` and `2011-12-01`; `dates_not_at_month_start = 0`; `issue_months = 55`; required-field error counts are zero. `dti` and `int_rate` should be decimal ratios, so a value around `0.12` means 12%, not 0.12%.

### 5. Establish baseline SQL results and reconcile them

**Do:** Open `sql/02_basic_queries.sql` and run its five `SELECT` statements. Separately run `python tools/verify_clean_data.py` from this project folder in a terminal. Compare the outputs and save the SQL result grids or screenshots.

**Why:** This is the independent cross-check for the entire dashboard. The Python verifier reads the prepared CSV; SQL reads what MySQL imported. If they match, the import preserved the data. On Day 4, compare the Power BI measures with these SQL results. Power BI reads a cloud copy of the same CSV for refresh, while MySQL validates its business logic. This is not an extra import step.

**What each query answers:**

| Query | Business question | Key check |
|---|---|---|
| 1. Portfolio overview | How many loans and how much money? | 39,786 loans; $436,003,725 funded; $486,688,031.90 received; average interest 12.03%; average DTI 13.32% |
| 2. Status mix | How many fully paid versus charged off? | 34,116 fully paid; 5,670 charged off |
| 3. Grade comparison | Does observed outcome vary by assigned grade? | Grade A: 602/10,085 = 5.97%; Grade G: 101/318 = 31.76% |
| 4. Issue-month trend | When was origination volume highest? | 55 issue months; December 2011 funded $31,007,025 |
| 5. Purpose breakdown | Why did borrowers take loans? | `debt_consolidation` has 18,676 loans in the CSV |

**Check:** All counts and amounts match the verifier. Small display-rounding differences are acceptable for rates, but not row counts or funded totals. If anything differs, stop before Day 2 and inspect import mapping, skipped rows, and source file choice. If you already ran all of Day 1, this comparison is the only part worth revisiting.

**Day 1 exit condition:** MySQL profile and five baseline results match the verifier. Keep the outputs for Day 4.

## Day 2: answer risk questions with CTEs

### 1. Grade outcome analysis

**Do:** Run `sql/03_cte_grade_risk.sql` and save its result.

**Why:** The first CTE counts loans by grade and status; the next turns those counts into a grade-level charged-off share. This separates the logic into inspectable steps.

**Check:** Grade A is 602 charged off out of 10,085; Grade G is 101 out of 318. Always show the denominator. A 31.76% rate based on 318 loans carries more sampling uncertainty than one based on 10,085.

### 2. DTI segment analysis

**Do:** Run `sql/04_cte_dti_segments.sql`. Look at both the grade-by-DTI result and the overall DTI-band result.

**Why:** DTI groups let you compare borrowers with different debt burdens. The second result aggregates raw counts before calculating rates; averaging the grade-level percentages would be mathematically wrong.

**Check:** Low DTI (<10%): 1,637/13,219 = 12.38%. High DTI (>=20%): 1,217/7,529 = 16.16%. This is about 1.30 times higher, not the roughly 3 times suggested by the original plan. It is an association, not a causal effect.

### 3. Monthly growth analysis

**Do:** Run `sql/05_cte_monthly_growth.sql` and save the result. Locate the prior-month amount and MoM growth columns.

**Why:** `LAG()` places the previous month's funded amount beside the current month so growth can be calculated. The first month has no previous month, so its growth is blank.

**Check:** Compare monthly funded amounts to Day 1 query 4. Do not present the largest raw growth rate without its base: July 2007 is +2,189.33% because June had only one loan. The rows describe loans **issued** in each month and their eventual outcomes, not charge-offs that happened during that calendar month.

**Day 2 exit condition:** Three CTE scripts run, results saved, and headline rates match Day 1 and the CSV verifier.

## Day 3: build the Power BI data model, not visuals yet

### 1. Put the source file in your work/school cloud storage

**Do:** Sign in to OneDrive for work or school or SharePoint with the same account that opens Power BI Service. Upload `data/financial_loan_clean.csv` to a folder you control. Keep the filename unchanged. Do not make the raw file publicly accessible. Copy the **site URL** from your browser, not a file-sharing link. For OneDrive for Business it ends at the personal site path before `/Documents`; for SharePoint it ends at `/sites/<site-name>`.

**Why:** The published model must read a cloud file without your laptop or a gateway. A local file path, even inside a synced OneDrive folder on C:, still points Power BI to your laptop.

**Check:** Open the CSV in the OneDrive/SharePoint browser and confirm the first row has 16 columns. Keep only one file with the exact name `financial_loan_clean.csv` on that site, because the query deliberately fails if it finds duplicates.

### 2. Connect Power BI to the cloud file

**Do:** Make sure C: has several GB free, then open Power BI Desktop. In **Transform data > Power Query**, create a **Text** parameter named `SharePointSiteUrl` with the site URL from Step 1. Create a **Blank Query**, rename it `financial_loan`, open **Advanced Editor**, and replace the query with the complete code in `powerbi/FactLoans_SharePoint.m`. When prompted, use **Organizational account** with your work/school sign-in. Set privacy level to Organizational if prompted.

**Why:** `SharePoint.Files` retrieves the CSV from the cloud. The query verifies it found exactly one file, types all 16 source fields, and creates the DTI bands used in SQL. Oracle MySQL Connector/NET is not needed for this cloud-file route.

**Check:** The `financial_loan` preview contains 39,786 rows, 17 columns including `DTIBand`, and issue dates from 2007 to 2011. If the query finds zero or multiple files, check the site URL and duplicate filenames before editing the M code.

### 3. Confirm the financial types

**Do:** Inspect `issue_date`, `funded_amount`, `total_payment`, `dti`, and `int_rate` in Power Query. The M query sets their types; do not multiply DTI or interest values again.

**Why:** Date relationships and DAX fail or mislead if values remain text or a 12% ratio is treated as 0.12%.

**Check:** `issue_date` has a Date icon; `dti` and `int_rate` values around `0.12` mean 12%; `DTIBand` labels match Day 2 SQL.

### 4. Add the date table

**Do:** Create a Blank Query named `DimDate`. Open Advanced Editor, replace its contents with the full code in `powerbi/DimDate.m`, then choose **Close & Apply**.

**Why:** One row per calendar date gives Power BI a continuous date axis and supports previous-month and year-to-date measures. Using only the loan table would omit days and make time calculations fragile.

**Check:** `DimDate` appears as a separate table with dates spanning 2007 through 2011.

### 5. Create the relationship and sort order

**Do:** In Model view, relate `DimDate[Date]` (one side) to `financial_loan[issue_date]` (many side), single-direction. Mark `DimDate` as the date table using `[Date]`. Sort `DimDate[MonthYear]` by `[YearMonth]`.

**Why:** The relationship makes a date slicer filter the loans. Sorting prevents month labels from appearing alphabetically.

**Check:** The relationship shows `1` on `DimDate` and `*` on `financial_loan`; `MonthYear` appears chronologically.

**Day 3 exit condition:** Cloud-connected loan query, two-table model, active one-to-many relationship, correct types, no report visuals yet.

## Day 4: create measures and prove their numbers

### 1. Add the 12 DAX measures

**Do:** In Desktop, create each formula from `powerbi/measures.dax` as an individual measure on `financial_loan`. Do not paste the entire file as one measure.

**Why:** Measures recalculate when the user changes a slicer. `CALCULATE` handles outcome filters, and `DIVIDE` avoids invalid division when a filtered group has no loans.

**Check:** You see 12 calculator-icon measures. Format `Avg Interest Rate`, `Avg DTI`, `Charged Off Share of Resolved`, and `MoM Growth` as percentages with two decimals; funded and received amounts as USD; counts as whole numbers.

### 2. Reconcile Power BI with SQL

**Do:** Add temporary cards for `Total Loans`, `Total Funded`, `Total Received`, and `Charged Off Loans`; add a grade table and a two-month detail table.

**Why:** This completes the independent chain from Day 1: CSV verifier, MySQL query, and Power BI measure must show the same answer before charts make the result look convincing.

**Check:** Cards show 39,786; $436,003,725; $486,688,031.90; and 5,670. Grade A/G counts and at least two monthly funded values match saved SQL. First issue month MoM growth may be blank by design.

**Day 4 exit condition:** All 12 measures exist, and key numbers match SQL without unexplained differences.

## Day 5: turn verified measures into three report pages

Before placing visuals, import `powerbi/theme.json` from **View > Themes > Browse for themes** (or the Theme pane's **Import theme** action). Use a navy canvas and light text across all three pages. Blue represents funded volume; red represents charged-off outcomes. The theme sets defaults, but check each visual's contrast and assign the status colors explicitly.

### 1. Summary page

**Do:** Add cards for loan count, funded amount, charged-off share, and average interest. Add status and grade bar charts, an issue-month loan-count line chart, and a Year slicer.

**Why:** This page answers portfolio size, outcome mix, grade distribution, and origination trend at a glance.

**Check:** The Year slicer filters intended charts. Title the line chart **Loans issued by month**, not **Defaults by month**.

### 2. Risk Analysis page

**Do:** Add a matrix with `grade` rows, `DTIBand` columns, and `Resolved Loans` plus `Charged Off Share of Resolved` values. Add a purpose bar chart and grade scatter using average DTI, average interest, and loan count as bubble size.

**Why:** A percentage without sample size can mislead. The matrix lets a viewer inspect both the observed rate and the number of loans behind it.

**Check:** Grade G shows only 318 loans before filters. Do not place `loan_status` as matrix columns for the charged-off share: a single-status column changes the question being asked.

### 3. Monthly Trends page and interactions

**Do:** Use `DimDate[MonthYear]` on all time axes. Show monthly funded amount, a separate YTD-funded view, MoM growth, and a monthly detail table. Use **Format > Edit interactions** to test cross-filtering; add page navigation after visuals work.

**Why:** Monthly and cumulative amounts have different scales, so separate views are easier to read. The detail table lets you compare chart points against Day 1 and Day 2 SQL.

**Check:** Month labels are chronological. December 2011 funded amount is $31,007,025 before filters. Every displayed rate has a clear denominator, and selections do not silently change its meaning.

**Day 5 exit condition:** Three usable pages, working slicers/navigation, and no unexplained visual totals.

## Day 6: package and publish the project

### 1. Save and test the PBIX

**Do:** Save `bank_loan_dashboard.pbix` in the project root. Export one screenshot per page to `screenshots/`. Close and reopen the PBIX, then recheck the four Day 4 card values.

**Why:** Reopening checks that the file is a real deliverable, not just an unsaved Desktop session. Screenshots give recruiters a preview even if the Service link is restricted.

**Check:** All three pages load with no broken visuals.

### 2. Publish and configure cloud refresh

**Do:** Sign in with your work/school account and use Desktop's **Publish** action to upload to **My workspace**. In Power BI Service, open the **semantic model settings**. Under **Data source credentials**, sign in to the SharePoint/OneDrive source with **Organizational account** and confirm no gateway is selected. Configure **Scheduled refresh** once daily. Click **Refresh now**, then inspect **Refresh history**.

**Why:** The Service can fetch an updated cloud CSV without your laptop. Publishing the PBIX alone is not proof of automatic refresh; a schedule and valid cloud credentials are required. This historical file does not change by itself, so successful refreshes normally return the same 39,786 loans.

**Check:** Refresh history shows a successful cloud-source refresh. Turn your laptop off before a later scheduled refresh to prove it is independent. A free Power BI license can schedule refresh in My workspace, but cannot generally share that report with other users. If a gateway is demanded, the query may still reference a local file path; revisit Day 3 Step 2. If scheduling is unavailable, inspect tenant and license settings rather than claiming refresh works.

### 3. Decide whether the link may be public

**Do:** Check source redistribution rights and your organization's Power BI tenant rules before **Publish to web**. If permitted, generate the public link and test it in an incognito window. Do not substitute a normal signed-in **Share** link for a recruiter-facing public URL.

**Why:** Publish to web allows anonymous viewing and can expose the model's underlying records, not only the visible charts. A tenant administrator may disable it.

**Check:** Incognito opens the report without login. If public publishing is unavailable or not permitted, use screenshots and a private walkthrough; do not claim there is a public live link.

### 4. Publish the project code

**Do:** Keep the existing [analysis repository](https://github.com/vj0246/CreditSight) and [Vercel dashboard repository](https://github.com/vj0246/bank-loan-dashboard-site) current. Add validated screenshots after the PBIX exists. Include the PBIX only if the embedded data can be redistributed. Keep raw CSV/ZIP files, the installer, and credentials out of Git.

**Why:** GitHub proves your reasoning and reproducible work; Power BI Service provides the interactive report. They serve different purposes.

**Check:** Open both repositories, the Vercel site, and any public Power BI report link in an incognito window. The Vercel snapshot is separate from the planned refreshable Power BI report. Add a Power BI link to the resume only after it works without sign-in.

**Day 6 exit condition:** PBIX opens, screenshots match it, and every link you advertise works for its intended audience.

## Day 7: prepare an honest interview walkthrough

### 1. Know the measured numbers

**Do:** Memorize the count and denominator with each rate: 5,670/39,786 overall (14.25%); Grade A 602/10,085 (5.97%); Grade G 101/318 (31.76%); high DTI 1,217/7,529 (16.16%); low DTI 1,637/13,219 (12.38%).

**Why:** The denominator tells the interviewer whether a headline percentage is supported by many loans or a small group.

**Check:** You can reproduce each number from a SQL query and point to the matching Power BI measure or visual.

### 2. Rehearse the method and limitations

**Do:** Explain the source correction, typed MySQL import, Day 1 reconciliation, CTE logic, date relationship, DAX validation, and one business-relevant association in about one minute.

**Why:** The strongest portfolio signal is defensible reasoning, not the number of charts.

**Check:** Say **observed charged-off share**, not predictive default probability. Do not claim DTI causes charge-off, Grade G is underpriced, or funded amount equals realized loss. The outcome date is unavailable, so the trend page is about origination cohorts.

**Day 7 exit condition:** You can open the report, explain any displayed number, and state its limitations without reading a script.

## Submit now versus complete later

**Submit now:** [Vercel dashboard](https://bank-loan-dashboard-site.vercel.app/) and [SQL/analysis repository](https://github.com/vj0246/CreditSight). Optionally add the [dashboard source repository](https://github.com/vj0246/bank-loan-dashboard-site). Describe this as a historical SQL/Python analysis with an interactive, aggregate-only web dashboard. Do not list Power BI as a completed project tool yet.

**Still required for the original Power BI plan:** Send non-sensitive Day 1 `row_count`, status counts, and query 1 if independent MySQL reconciliation is needed. Confirm the prepared CSV is on your work/school OneDrive or SharePoint. Complete Days 3 through 6 in signed-in Power BI Desktop and Service, save a working three-page PBIX, validate measures against SQL, publish, and verify refresh history. No PBIX, Service refresh schedule, or public Power BI link can be claimed until those checks pass. Do not send credentials.
