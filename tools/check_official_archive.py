"""Inspect LendingClub's archived 2007-2011 tape without extracting it."""

import csv
import io
import json
import zipfile
from collections import Counter
from datetime import datetime
from pathlib import Path


archive = Path(__file__).resolve().parents[1] / "data" / "LoanStats3a.csv.zip"
statuses = Counter()
issue_years = Counter()
issue_months = Counter()
blank_ids = 0
rows = 0
min_dti = float("inf")
max_dti = float("-inf")
min_rate = float("inf")
max_rate = float("-inf")

with zipfile.ZipFile(archive) as bundle:
    with bundle.open("LoanStats3a.csv") as raw:
        text = io.TextIOWrapper(raw, encoding="utf-8-sig", newline="")
        next(text)  # LendingClub's note above the CSV header.
        reader = csv.DictReader(text)
        fields = set(reader.fieldnames or [])
        required = {"id", "issue_d", "loan_status", "loan_amnt", "funded_amnt", "int_rate", "dti"}
        if not required <= fields:
            raise ValueError(f"Missing columns: {sorted(required - fields)}")

        for row in reader:
            if not row["issue_d"]:
                continue  # Footer rows are not loan records.
            rows += 1
            blank_ids += not bool(row["id"])
            statuses[row["loan_status"]] += 1
            issue_years[row["issue_d"][-4:]] += 1
            issue_months[row["issue_d"]] += 1
            dti = float(row["dti"])
            rate = float(row["int_rate"].strip().rstrip("%"))
            min_dti, max_dti = min(min_dti, dti), max(max_dti, dti)
            min_rate, max_rate = min(min_rate, rate), max(max_rate, rate)

print(json.dumps({
    "rows": rows,
    "blank_ids": blank_ids,
    "statuses": dict(statuses),
    "issue_years": dict(sorted(issue_years.items())),
    "month_count": len(issue_months),
    "first_month": min(issue_months, key=lambda value: datetime.strptime(value, "%b-%Y")),
    "raw_dti_range_pct": [min_dti, max_dti],
    "raw_interest_rate_range_pct": [min_rate, max_rate],
}, indent=2))
