"""Create a small, typed loan extract from LendingClub's historical archive."""

import csv
import hashlib
import io
import zipfile
from collections import Counter
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "LoanStats3a.csv.zip"
TARGET = ROOT / "data" / "financial_loan_clean.csv"
STATUSES = {"Fully Paid", "Charged Off"}
FIELDS = [
    "loan_record_key", "issue_date", "loan_status", "grade", "sub_grade",
    "purpose", "home_ownership", "annual_income", "dti", "int_rate",
    "loan_amount", "funded_amount", "total_payment", "term", "emp_length",
    "address_state",
]


def money(value: str) -> str:
    return str(Decimal(value).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


counts = Counter()
months = set()
with zipfile.ZipFile(SOURCE) as bundle:
    with bundle.open("LoanStats3a.csv") as raw, TARGET.open(
        "w", newline="", encoding="utf-8"
    ) as destination:
        source = io.TextIOWrapper(raw, encoding="utf-8-sig", newline="")
        next(source)  # Archive note above its CSV header.
        reader = csv.DictReader(source)
        writer = csv.DictWriter(destination, fieldnames=FIELDS)
        writer.writeheader()

        for source_row_number, loan in enumerate(reader, start=1):
            status = (loan.get("loan_status") or "").strip()
            if status not in STATUSES:
                counts["excluded_other_status"] += bool(status)
                continue

            issue_date = datetime.strptime(loan["issue_d"], "%b-%Y").date()
            dti = Decimal(loan["dti"]) / 100
            interest = Decimal(loan["int_rate"].strip().rstrip("%")) / 100
            if not (0 <= dti <= 1 and 0 <= interest <= 1):
                raise ValueError(f"Invalid ratio at source row {source_row_number}")

            annual_income = loan["annual_inc"].strip()
            writer.writerow({
                "loan_record_key": source_row_number,
                "issue_date": issue_date.replace(day=1).isoformat(),
                "loan_status": status,
                "grade": loan["grade"].strip(),
                "sub_grade": loan["sub_grade"].strip(),
                "purpose": loan["purpose"].strip(),
                "home_ownership": loan["home_ownership"].strip(),
                "annual_income": money(annual_income) if annual_income else "",
                "dti": str(dti),
                "int_rate": str(interest),
                "loan_amount": money(loan["loan_amnt"]),
                "funded_amount": money(loan["funded_amnt"]),
                "total_payment": money(loan["total_pymnt"]),
                "term": loan["term"].strip(),
                "emp_length": loan["emp_length"].strip(),
                "address_state": loan["addr_state"].strip(),
            })
            counts[status] += 1
            counts["missing_annual_income"] += not bool(annual_income)
            months.add(issue_date.strftime("%Y-%m"))

print(f"Wrote {TARGET.name}: {sum(counts[status] for status in STATUSES):,} loans")
print(f"Status counts: {dict(counts)}")
print(f"Issue months: {min(months)} through {max(months)} ({len(months)} months)")
print(f"Source SHA256: {hashlib.sha256(SOURCE.read_bytes()).hexdigest()}")
