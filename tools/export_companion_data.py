"""Export aggregate-only historical loan data for the companion dashboard."""

import csv
import json
from collections import defaultdict
from decimal import Decimal
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "financial_loan_clean.csv"
TARGET = ROOT / "companion-site" / "app" / "loan-aggregates.json"


def empty_metrics() -> dict[str, int]:
    return {
        "loans": 0,
        "chargedOff": 0,
        "fundedCents": 0,
        "chargedOffFundedCents": 0,
        "receivedCents": 0,
        "interestBasisPointSum": 0,
        "dtiBasisPointSum": 0,
    }


def empty_period() -> dict:
    return {
        "summary": empty_metrics(),
        "grades": defaultdict(empty_metrics),
        "dtiBands": defaultdict(empty_metrics),
        "purposes": defaultdict(empty_metrics),
        "months": defaultdict(empty_metrics),
    }


def cents(value: str) -> int:
    return int(Decimal(value) * 100)


def add(metrics: dict[str, int], row: dict[str, str]) -> None:
    charged_off = row["loan_status"] == "Charged Off"
    funded = cents(row["funded_amount"])
    metrics["loans"] += 1
    metrics["chargedOff"] += charged_off
    metrics["fundedCents"] += funded
    metrics["chargedOffFundedCents"] += funded if charged_off else 0
    metrics["receivedCents"] += cents(row["total_payment"])
    metrics["interestBasisPointSum"] += int(Decimal(row["int_rate"]) * 10000)
    metrics["dtiBasisPointSum"] += int(Decimal(row["dti"]) * 10000)


periods = defaultdict(empty_period)
with SOURCE.open(newline="", encoding="utf-8") as source:
    for row in csv.DictReader(source):
        year = row["issue_date"][:4]
        month = row["issue_date"][:7]
        dti = Decimal(row["dti"])
        band = "<10%" if dti < Decimal("0.10") else (
            "10–<20%" if dti < Decimal("0.20") else ">=20%"
        )
        for key in ("all", year):
            period = periods[key]
            for metrics in (
                period["summary"],
                period["grades"][row["grade"]],
                period["dtiBands"][band],
                period["purposes"][row["purpose"]],
                period["months"][month],
            ):
                add(metrics, row)

assert periods["all"]["summary"]["loans"] == 39786
assert periods["all"]["summary"]["chargedOff"] == 5670
assert periods["all"]["summary"]["fundedCents"] == 43600372500
for period in periods.values():
    total = period["summary"]
    for dimension in ("grades", "dtiBands", "purposes", "months"):
        assert sum(item["loans"] for item in period[dimension].values()) == total["loans"]
        assert sum(item["fundedCents"] for item in period[dimension].values()) == total["fundedCents"]

TARGET.write_text(
    json.dumps({"periods": periods}, ensure_ascii=False, sort_keys=True, separators=(",", ":")),
    encoding="utf-8",
)
print(f"Exported {TARGET.name}: {TARGET.stat().st_size:,} bytes; no loan-level rows")
