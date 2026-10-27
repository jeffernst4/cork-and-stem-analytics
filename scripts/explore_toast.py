"""Probe the Toast API to see which endpoints your credentials can read and what the data looks like.

Usage: python scripts/explore_toast.py [yyyymmdd]

Uses passed date or yesterday as default. 

For each endpoint it prints OK / the HTTP error, plus an outline of the JSON fields,
and saves the full response to toast_samples/<name>.json for closer inspection.
"""
import json
import os
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

import requests

from toast_client import ToastClient

OUT_DIR = Path("toast_samples")


def outline(value, indent=0, max_depth=4):
    """Print the shape of a JSON value: field names and types, first element of each list."""
    pad = "  " * indent
    if indent >= max_depth:
        return
    if isinstance(value, dict):
        for key, child in value.items():
            kind = type(child).__name__
            if isinstance(child, list):
                kind = f"list[{len(child)}]"
            preview = "" if isinstance(child, (dict, list)) else f" = {str(child)[:40]!r}"
            print(f"{pad}{key}: {kind}{preview}")
            outline(child, indent + 1, max_depth)
    elif isinstance(value, list) and value:
        outline(value[0], indent, max_depth)


def main():
    business_date = sys.argv[1] if len(sys.argv) > 1 else (date.today() - timedelta(days=1)).strftime("%Y%m%d")
    client = ToastClient()

    guid = os.environ["TOAST_RESTAURANT_GUID"]
    day = datetime.strptime(business_date, "%Y%m%d")
    shift_window = {
        "startDate": day.strftime("%Y-%m-%dT00:00:00.000-0000"),
        "endDate": (day + timedelta(days=1)).strftime("%Y-%m-%dT00:00:00.000-0000"),
    }
    endpoints = {
        "restaurant": (f"/restaurants/v1/restaurants/{guid}", None), # timezone and hours, for converting UTC timestamps to local time
        "menus": ("/menus/v2/menus", None), # item GUIDs in orders into names and groups
        "orders": ("/orders/v2/ordersBulk", {"businessDate": business_date, "pageSize": 5}), # core orders dataset, edit pageSize later
        "revenue_centers": ("/config/v2/revenueCenters", None), # sales by area (bar, patio, events, etc)
        "dining_options": ("/config/v2/diningOptions", None), # sales by mode (dine-in, takeout, etc)
        "sales_categories": ("/config/v2/salesCategories", None), # lookup for item category
        "discounts": ("/config/v2/discounts", None), # discount names, amounts, percentages 
        "employees": ("/labor/v1/employees", None), # SENSITIVE: contains personal information, only matters for GUIDs and job link
        "jobs": ("/labor/v1/jobs", None), # information on roles, lookup for time entries
        "time_entries": ("/labor/v1/timeEntries", {"businessDate": business_date}), # employee clock ins for the day
        "shifts": ("/labor/v1/shifts", shift_window), # scheduled shifts, compare with time entries and sales for staffing vs demand
    }

    OUT_DIR.mkdir(exist_ok=True)
    for name, (path, params) in endpoints.items():
        try:
            data = client.get(path, params=params)
        except requests.HTTPError as e:
            print(f"\n=== {name}: HTTP {e.response.status_code} (no access or not available)")
            continue
        count = f"{len(data)} records" if isinstance(data, list) else "1 object"
        print(f"\n=== {name}: OK, {count} -> {OUT_DIR / name}.json")
        outline(data)
        (OUT_DIR / f"{name}.json").write_text(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
