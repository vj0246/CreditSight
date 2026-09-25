# Bank Loan Credit Risk Dashboard

Historical LendingClub loan origination and observed outcome analysis using MySQL 8, SQL CTEs, Power BI, Power Query, and DAX. The repository contains reproducible data preparation, SQL, and report formulas. A [public interactive companion dashboard](https://bank-loan-ledger-vj.neev-jain244.chatgpt.site) is live using verified aggregates only. **The Power BI PBIX and Service report are not built yet.** See [YOUR_STEPS.md](YOUR_STEPS.md) for signed-in actions.

## Source and scope

The source is LendingClub's [LoanStats3a historical archive](https://resources.lendingclub.com/LoanStats3a.csv.zip), SHA-256 `6f93fc97f0ad26718ed66c6199931ac6204ce80d7c14da0215b529b0891f12be`. `tools/prepare_official_data.py` selects 39,786 `Fully Paid` or `Charged Off` loans from 42,535 source records. It excludes 2,749 records with other credit-policy statuses, converts percentage fields to decimal ratios, and maps issue month to its first day for date-table use. The archive's public loan ID is blank, so `loan_record_key` is the stable row number in this archive snapshot, not a real loan ID.

An earlier 24-column copy (`financial_loan.csv`) is retained locally but rejected for time analysis: its 2021 issue dates disagree with the corresponding original 2007–2011 archive records. Neither source file nor generated data is committed. The selected cohort is historical and non-random; its observed outcomes should not be presented as current portfolio performance or forward-looking default probability.

## Verified local figures

These values come from `python tools/verify_clean_data.py` on the prepared CSV. Reconcile them with MySQL and DAX before using them in a public report.

| Measure | Value |
|---|---:|
| Resolved loans | 39,786 |
| Charged-off loans / resolved | 5,670 / 39,786 = 14.25% |
| Funded amount | $436,003,725.00 |
| Total received (`total_pymnt`) | $486,688,031.90 |
| Average interest / DTI | 12.03% / 13.32% |
| Grade A observed charge-off share | 602 / 10,085 = 5.97% |
| Grade G observed charge-off share | 101 / 318 = 31.76% |
| DTI <10% | 1,637 / 13,219 = 12.38% |
| DTI >=20% | 1,217 / 7,529 = 16.16% |
| Peak funded issue month | December 2011, $31,007,025 across 2,267 loans |

High-DTI share is about 1.30 times low-DTI share, not the 2.5–3.5 times claimed by the initial project outline. This is an unadjusted association; grade, vintage, and other factors may confound it. `funded_amount` is original funded principal, **not** outstanding balance or credit loss. Monthly outcome rates group loans by origination month, not the month in which charge-off happened.

## Reproduce

1. Place the archive at `data/LoanStats3a.csv.zip` and run `python tools/prepare_official_data.py` followed by `python tools/verify_clean_data.py`.
2. In MySQL Workbench, run `sql/00_create_database.sql`; import `data/financial_loan_clean.csv` into its existing table via **Table Data Import Wizard**.
3. Run `sql/01_profile_data.sql`, then `sql/02_basic_queries.sql` and `sql/03`–`05` CTE scripts. Compare against the verified local figures.
4. Upload the prepared CSV to work/school OneDrive or SharePoint. In Power BI Desktop, create `financial_loan` from `powerbi/FactLoans_SharePoint.m`, then create `DimDate` from `powerbi/DimDate.m`, the one-to-many date relationship, and the 12 formulas in `powerbi/measures.dax` as individual measures. MySQL is the independent SQL validation layer; Power BI reads the cloud CSV for refresh.
5. Build Summary, Risk Analysis, and Monthly Trends pages per [YOUR_STEPS.md](YOUR_STEPS.md). Save the PBIX and screenshots only after SQL-to-DAX checks pass.

## Publication status

The [companion dashboard](https://bank-loan-ledger-vj.neev-jain244.chatgpt.site) is public and interactive but is a fixed historical snapshot; it does not update automatically when the cloud CSV changes. No Power BI Service link or GitHub remote has been verified. The planned no-cost Power BI connection uses work/school OneDrive or SharePoint and must pass a Service refresh-history check before automatic refresh is claimed. **Publish to web can expose underlying model data publicly**, so confirm redistribution rights and tenant permission first.
