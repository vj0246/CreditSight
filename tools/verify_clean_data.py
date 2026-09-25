"""Validate the curated snapshot and print SQL/DAX reconciliation targets."""

import csv
from collections import Counter, defaultdict
from decimal import Decimal
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[1] / "data" / "financial_loan_clean.csv"
rows = list(csv.DictReader(SOURCE.open(newline="", encoding="utf-8")))
keys = {row["loan_record_key"] for row in rows}
statuses = Counter(row["loan_status"] for row in rows)
assert len(rows) == len(keys) == 39786, "Unexpected row count or duplicate key"
assert statuses == {"Fully Paid": 34116, "Charged Off": 5670}, statuses
assert all(row["issue_date"].endswith("-01") for row in rows)
assert all(Decimal(row["funded_amount"]) > 0 for row in rows)
assert all(Decimal("0") <= Decimal(row["dti"]) <= Decimal("1") for row in rows)
assert all(Decimal("0") <= Decimal(row["int_rate"]) <= Decimal("1") for row in rows)

funded = sum(Decimal(row["funded_amount"]) for row in rows)
listed = sum(Decimal(row["loan_amount"]) for row in rows)
received = sum(Decimal(row["total_payment"]) for row in rows)
grade = defaultdict(lambda: [0, 0])
band = defaultdict(lambda: [0, 0])
monthly = defaultdict(lambda: [0, Decimal("0")])
purposes = defaultdict(lambda: [0, 0])

for row in rows:
    bad = row["loan_status"] == "Charged Off"
    dti = Decimal(row["dti"])
    dti_band = "Low: <10%" if dti < Decimal("0.10") else (
        "Medium: 10-<20%" if dti < Decimal("0.20") else "High: >=20%"
    )
    grade[row["grade"]][0] += 1
    grade[row["grade"]][1] += bad
    band[dti_band][0] += 1
    band[dti_band][1] += bad
    month = row["issue_date"][:7]
    monthly[month][0] += 1
    monthly[month][1] += Decimal(row["funded_amount"])
    purposes[row["purpose"]][0] += 1
    purposes[row["purpose"]][1] += bad


def rate(counts: list[int]) -> str:
    return f"{100 * counts[1] / counts[0]:.2f}%"


print(f"Loans: {len(rows):,}; charged off: {statuses['Charged Off']:,} ({rate([len(rows), statuses['Charged Off']])})")
print(f"Listed: ${listed:,.2f}; funded: ${funded:,.2f}; received: ${received:,.2f}")
print(f"Avg interest: {100 * sum(Decimal(row['int_rate']) for row in rows) / len(rows):.2f}%")
print(f"Avg DTI: {100 * sum(Decimal(row['dti']) for row in rows) / len(rows):.2f}%")
for label in ("A", "G"):
    print(f"Grade {label}: {grade[label][0]:,} loans; {grade[label][1]:,} charged off ({rate(grade[label])})")
for label in ("Low: <10%", "Medium: 10-<20%", "High: >=20%"):
    print(f"DTI {label}: {band[label][0]:,} loans; {band[label][1]:,} charged off ({rate(band[label])})")

peak_month = max(monthly, key=lambda month: monthly[month][1])
print(f"Peak funded issue month: {peak_month}; ${monthly[peak_month][1]:,.2f}; {monthly[peak_month][0]:,} loans")
print(f"Issue months: {len(monthly)}; first: {min(monthly)}; last: {max(monthly)}")
months = sorted(monthly)
changes = [
    (month, 100 * (monthly[month][1] / monthly[prior][1] - 1), monthly[prior][0])
    for prior, month in zip(months, months[1:])
]
for label, item in (("Highest", max(changes, key=lambda change: change[1])),
                    ("Lowest", min(changes, key=lambda change: change[1]))):
    print(f"{label} MoM funded change: {item[0]}; {item[1]:+.2f}%; prior month {item[2]:,} loans")
stable_base = [change for change in changes if change[2] >= 100 and monthly[change[0]][0] >= 100]
for label, item in (("Highest", max(stable_base, key=lambda change: change[1])),
                    ("Lowest", min(stable_base, key=lambda change: change[1]))):
    print(f"{label} MoM with >=100 loans in both months: {item[0]}; {item[1]:+.2f}%")
peak_purpose = max(purposes, key=lambda purpose: purposes[purpose][0])
print(f"Top purpose by count: {peak_purpose}; {purposes[peak_purpose][0]:,} loans")
