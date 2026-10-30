"""Load Toast data into BigQuery.

Usage:
  python3 scripts/ingest_toast.py                      # orders from last loaded date through yesterday, plus all lookups
  python3 scripts/ingest_toast.py --start 2026-01-01   # first run / backfill
  python3 scripts/ingest_toast.py --dry-run            # pull only, write to toast_samples/ instead of BigQuery
  python3 scripts/ingest_toast.py --no-lookup          # orders only, leave lookup tables as they are

Orders load incrementally by business date. Lookup tables are small and fully replaced each run.
Each record is stored as one row with its raw JSON (BigQuery JSON type); dbt does the flattening.
"""
import argparse
import json
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from google.cloud import bigquery

from toast_client import ToastClient

DATASET = "cork-and-stem-analytics.raw_data_sources"
ORDERS_TABLE_ID = f"{DATASET}.toast_orders"
ORDERS_SCHEMA = [
    bigquery.SchemaField("business_date", "DATE"),
    bigquery.SchemaField("order_guid", "STRING"),
    bigquery.SchemaField("order_json", "JSON"),
    bigquery.SchemaField("loaded_at", "TIMESTAMP"),
]

# Lookup name -> API path. Each loads into raw_data_sources.toast_<name>.
LOOKUPS = {
    "sales_categories": "/config/v2/salesCategories",
    "discounts": "/config/v2/discounts",
}
LOOKUP_SCHEMA = [
    bigquery.SchemaField("guid", "STRING"),
    bigquery.SchemaField("record_json", "JSON"),
    bigquery.SchemaField("loaded_at", "TIMESTAMP"),
]
DRY_RUN_DIR = Path("toast_samples")


def write_dry_run(name, rows):
    DRY_RUN_DIR.mkdir(exist_ok=True)
    out = DRY_RUN_DIR / f"{name}_dry_run.json"
    out.write_text(json.dumps(rows, indent=2))
    print(f"Dry run: wrote {len(rows)} rows to {out}")


def load_lookups(bq, toast, loaded_at):
    """Fully replace each lookup table with the current API response."""
    for name, path in LOOKUPS.items():
        rows = [
            {"guid": r["guid"], "record_json": r, "loaded_at": loaded_at}
            for r in toast.get(path)
        ]
        if bq is None:
            write_dry_run(name, rows)
            continue
        table_id = f"{DATASET}.toast_{name}"
        job_config = bigquery.LoadJobConfig(schema=LOOKUP_SCHEMA, write_disposition="WRITE_TRUNCATE")
        bq.load_table_from_json(rows, table_id, job_config=job_config).result()
        print(f"Loaded {len(rows)} rows into {table_id}")


def ensure_orders_table(bq):
    table = bigquery.Table(ORDERS_TABLE_ID, schema=ORDERS_SCHEMA)
    table.time_partitioning = bigquery.TimePartitioning(field="business_date")
    bq.create_table(table, exists_ok=True)


def last_loaded_date(bq):
    rows = list(bq.query(f"SELECT MAX(business_date) AS d FROM `{ORDERS_TABLE_ID}`").result())
    return rows[0].d


def load_orders(bq, toast, loaded_at, start, end):
    """Replace orders for business dates start..end."""
    if bq:
        ensure_orders_table(bq)

    # Re-pull the last loaded day too: orders can still change after close (tips, voids, refunds).
    start = start or (bq and last_loaded_date(bq)) or end
    if start > end:
        print("Orders: nothing to load.")
        return

    rows = []
    day = start
    while day <= end:
        orders = toast.get_orders(day.strftime("%Y%m%d"))
        print(f"{day}: {len(orders)} orders")
        rows += [
            {
                "business_date": day.isoformat(),
                "order_guid": o["guid"],
                "order_json": o,
                "loaded_at": loaded_at,
            }
            for o in orders
        ]
        day += timedelta(days=1)

    if bq is None:
        write_dry_run("orders", rows)
        return

    # Idempotent: replace the date range instead of appending duplicates.
    bq.query(
        f"DELETE FROM `{ORDERS_TABLE_ID}` WHERE business_date BETWEEN @start AND @end",
        job_config=bigquery.QueryJobConfig(query_parameters=[
            bigquery.ScalarQueryParameter("start", "DATE", start),
            bigquery.ScalarQueryParameter("end", "DATE", end),
        ]),
    ).result()
    if rows:
        job_config = bigquery.LoadJobConfig(schema=ORDERS_SCHEMA, write_disposition="WRITE_APPEND")
        bq.load_table_from_json(rows, ORDERS_TABLE_ID, job_config=job_config).result()
    print(f"Loaded {len(rows)} orders for {start} to {end} into {ORDERS_TABLE_ID}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--start", type=date.fromisoformat, help="first business date to load (YYYY-MM-DD)")
    parser.add_argument("--end", type=date.fromisoformat, default=date.today() - timedelta(days=1))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-lookup", action="store_true", help="skip replacing the lookup tables")
    args = parser.parse_args()

    bq = None if args.dry_run else bigquery.Client()
    toast = ToastClient()
    loaded_at = datetime.now(timezone.utc).isoformat()

    if not args.no_lookup:
        load_lookups(bq, toast, loaded_at)
    load_orders(bq, toast, loaded_at, args.start, args.end)


if __name__ == "__main__":
    main()
