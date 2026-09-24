"""Check source CSV assumptions before MySQL import and Power BI modeling."""

import csv
import json
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


source = Path(__file__).resolve().parents[1] / "financial_loan.csv"
required = {"id", "issue_date", "loan_status", "grade", "purpose", "loan_amount", "dti", "int_rate"}
statuses = Counter()
grades = defaultdict(Counter)
monthly = defaultdict(lambda: {"loans": 0, "amount": 0})
dti_segments = defaultdict(Counter)
purposes = Counter()
ids = set()
dates = []
issue_days = Counter()
missing = Counter()
minmax = {key: [float("inf"), float("-inf")] for key in ("dti", "int_rate")}
row_count = 0
loan_amount_total = 0

with source.open(newline="", encoding="cp1252") as file:
    reader = csv.DictReader(file)
    absent = required - set(reader.fieldnames or [])
    if absent:
        raise ValueError(f"Required CSV columns missing: {sorted(absent)}")

    for row in reader:
        row_count += 1
        for key in required:
            if not row[key].strip():
                missing[key] += 1
        ids.add(row["id"])
        status = row["loan_status"].strip()
        grade = row["grade"].strip()
        purpose = row["purpose"].strip()
        issue_date = datetime.strptime(row["issue_date"].strip(), "%d-%m-%Y").date()
        dti = float(row["dti"])
        interest = float(row["int_rate"])
        amount = int(row["loan_amount"])

        statuses[status] += 1
        grades[grade][status] += 1
        purposes[purpose] += 1
        dates.append(issue_date)
        issue_days[issue_date.day] += 1
        month = issue_date.strftime("%Y-%m")
        monthly[month]["loans"] += 1
        monthly[month]["amount"] += amount
        loan_amount_total += amount
        segment = "low" if dti < 0.10 else "medium" if dti < 0.20 else "high"
        dti_segments[segment][status] += 1
        for key, value in (("dti", dti), ("int_rate", interest)):
            minmax[key][0] = min(minmax[key][0], value)
            minmax[key][1] = max(minmax[key][1], value)

resolved = statuses["Fully Paid"] + statuses["Charged Off"]
summary = {
    "rows": row_count,
    "distinct_ids": len(ids),
    "missing_required": dict(missing),
    "date_range": [min(dates).isoformat(), max(dates).isoformat()],
    "issue_day_counts": dict(sorted(issue_days.items())),
    "date_quality_warning": (
        "Issue dates concentrate on one day; verify against the original source before trend analysis."
        if max(issue_days.values()) / row_count > 0.40 else None
    ),
    "statuses": dict(statuses),
    "raw_ranges": minmax,
    "loan_amount_total": loan_amount_total,
    "charged_off_share_resolved_pct": round(100 * statuses["Charged Off"] / resolved, 2),
    "grades": {
        grade: {
            "all": sum(counts.values()),
            "resolved": counts["Fully Paid"] + counts["Charged Off"],
            "charged_off": counts["Charged Off"],
        }
        for grade, counts in sorted(grades.items())
    },
    "dti_segments": {segment: dict(counts) for segment, counts in sorted(dti_segments.items())},
    "monthly": dict(sorted(monthly.items())),
    "top_purposes_by_count": purposes.most_common(5),
}
print(json.dumps(summary, indent=2))
