# Data Pipeline Plan

## Target pipeline

```
Toast   HoneyBook   WineView   Shopify*   DoorDash*
  │         │           │          │          │
  └─────────┴─────┬─────┴──────────┴──────────┘
                  │  Python ingestion scripts (incremental, daily)
                  ▼
BigQuery raw tables (one per source, partitioned by date)
                  │  dbt build (staging → intermediate → marts)
                  ▼
BigQuery mart tables (transactions, customers, trends)
                  │  extract refresh / live connection
                  ▼
Dashboards (Tableau Cloud)

* being phased out: backfill full history once, then remove from the daily run

Orchestrated by one scheduled GitHub Actions workflow:
ingest → dbt build → refresh dashboards
```

## 0. Brainstorm (future insights, no customer PII)

From Toast endpoints (`scripts/explore_toast.py`).

**First Priorities:**
- Orders by revenue center (the categories, basically)
  - Raw tables: `orders`, `revenue_centers`
- Members vs non members check size and share, orders by categories 
  - Raw tables: `orders`, `discounts`, `sales_categories`
- Heatmap of busiest times and days based on orders
  - Raw tables: `orders`

Other ideas (not well formulated):
- **Order dynamics:**
  - Busy times: orders and sales by hour × weekday
  - Party size (`numberOfGuests`), spend per guest, visit length (opened → closed)
  - Channel mix: in-store vs online vs DoorDash; dine-in vs takeout (`dining_options`)
  - Area mix: Bar, Lounge, Patio, Dining Room (`revenue_centers`); patio vs weather (`daily_forecast_data`)
  - Basket: wine/beer vs food vs flowers/retail; food attach rate; flowers × drinks cross-sell
  - Promotions: happy hours (Wed vs Thu–Sun), Wednesday BOGO, Bottle & Board, Slushie Sunday usage and check size
  - Comps, waste, spillage rates
  - Tip % by daypart and party size
- **Customer dynamics:**
  - Members (`Member Discount 20%`, Rewards Card, Loyalty discounts): share of checks/sales, avg check, party size, items, visit times vs non-members
  - Membership sign-ups (`Membership` sales category) over time; check how memberships appear on orders
  - Events: workshops vs experiences vs tastings (`menus`); public vs private vs offsite (`sales_categories`, `dining_options`); seasonality
  - Event-day lift: Bar/Lounge sales on `event_log` dates vs comparable non-event days
- **Employee dynamics:**
  - Sales per server (order server GUID → `jobs`)
  - Sales per labor hour by hour (`time_entries`)
  - Scheduled (`shifts`) vs actual hours vs order volume

## 1. Ingestion

One Python script per source (Toast: `scripts/ingest_toast.py`). Extract and load only; no cleaning. Stores each record as raw JSON in `raw_data_sources`.

Toast raw tables:
- **Daily, by business date:** `orders`, `time_entries`, `shifts`.
  1. Read the last loaded date: `SELECT MAX(business_date) FROM raw.<table>`.
  2. Re-pull from that date through yesterday (orders change after close: tips, voids, refunds).
  3. Delete that date range, then append. Re-runs never create duplicates.
- **Lookups, full replace each run (`WRITE_TRUNCATE`):** `menus`, `revenue_centers`, `dining_options`, `sales_categories`, `discounts`, `jobs`, `employees`, `restaurant` (timezone).

Requirements:
- **Credentials:** GCP service account key and Toast API credentials, stored as GitHub secrets/`.env`.
- **Employees:** contains personal data; keep in a restricted dataset, expose only GUIDs and job links downstream.
- **Retiring sources (Shopify, DoorDash):** export their full history before access ends. Keep the raw tables frozen, and keep them in the dbt unions so historical trends stay intact.

## 2. Cleaning and transformation (dbt)

- **Staging:** flatten raw JSON, rename and type columns, drop voided/deleted records, convert UTC timestamps to local time. Toast: `stg_toast_orders`, `stg_toast_selections` (line items), `stg_toast_payments`, `stg_toast_time_entries`, `stg_toast_shifts`, plus one staging model per lookup.
- **Marts:**
  - **Orders:** daily sales by revenue center, dining option and sales category; item sales; discounts. Add Toast to `daily_sales_summary`.
  - **Employees:** sales per server (order server GUID → `employees` → `jobs`); hours worked (time entries) vs scheduled (shifts) vs sales by hour.
- **Incremental models:** large models use `materialized='incremental'` with a `unique_key` and an `is_incremental()` filter.
- **Tests:** `unique` / `not_null` on order GUIDs and other keys.

## 3. Visualization

- **Tool:**
  - **Tableau Cloud:** paid; one Creator license covers building, publishing and scheduled refreshes.
  - **Looker Studio:** the free alternative; connects natively to BigQuery, keeps sharing private and refreshes automatically.
- **Data source:** dashboards connect only to dbt mart tables. Aggregations happen in dbt, not in the dashboard tool.
- **Tableau connection:** use an extract rather than a live connection. Schedule it a set time after dbt finishes, then later trigger it from the pipeline through the Tableau REST API (`tableauserverclient`).

## 4. Orchestration: GitHub Actions

One daily cron workflow (`.github/workflows/`), steps in order:
1. Run the ingestion scripts.
2. Run `dbt build` (dbt Core).
3. Trigger the Tableau extract refresh.

A failed step stops everything after it, so dashboards never show partial data. GitHub emails you when a run fails.

## 5. Customer data and trends (later)

The same pipeline supports this. It needs new tables and dbt models, not a new architecture.
- **Toast:** customer info is only on orders (`check.customer`) when a guest provides it; check how often it's filled first.
   - need to explore how other sources deal with customer data, maybe Toast is insufficient.
- **Customer matching:** in dbt, match the same customer across sources (by email or phone) into one `dim_customers` table.
- **Changing attributes:** use dbt snapshots to track customer fields that change over time, such as membership status or address.
- **Marts:** customer metrics (lifetime value, visit frequency, recency), cohorts and retention.
- **PII:** keep personal data in a restricted dataset, and expose only hashed IDs or aggregates to dashboards.

# TODOs: 
- [x] set up basic Tableau visualizations with daily transactions that already exist (daily_sales_summary)
- [ ] work on building and testing the pipeline (just with Toast, for now)
   + exploration:
      + correct connection to Toast through the API 
      + what data is available with Toast
      + basic toast client script and understanding of it 
   - brainstorm and plan: 
      + how do the tables tie together -> diagramed in `docs/toast_data_model.md`
      + narrow down to three top insights to do at first 
        -> do first: orders by revenue centers, heatmap of popular times/days, member vs non member check volumes (maybe what they order too)
      - plan out what tables and scripts are needed and how they will be used, what final visuals will they yield 
   - data ingestion scripts and basic cleaning: 
      - incremental updates to big query -> ingestion
      - basic cleaning done in python scripts
   - dbt models for transformations to prepare for Tableau 
   - set up table with Tableau
   - workflow script(s) through GHA -> a cron job of the entire pipeline
   - testing 
   - done criteria: automatic data ingestion, dbt transformations, and updates in Tableau (3 most important for now)
- [ ] expand to other Toast insights
- [ ] expland to other sources
   - clean up final sources (still get confused on which to leave/delete)
   - figure out access (APIs?)
