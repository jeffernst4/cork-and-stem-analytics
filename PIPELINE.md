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

## 1. Visualization (top priority)

- **Tool:**
  - **Tableau Cloud:** paid; one Creator license covers building, publishing and scheduled refreshes.
  - **Looker Studio:** the free alternative; connects natively to BigQuery, keeps sharing private and refreshes automatically.
- **Data source:** dashboards connect only to dbt mart tables. Aggregations happen in dbt, not in the dashboard tool.
- **Tableau connection:** use an extract rather than a live connection. Schedule it a set time after dbt finishes, then later trigger it from the pipeline through the Tableau REST API (`tableauserverclient`).
- For now, will go with Tableau and a basic transactions aggregate graphs from daily transactions of each source

## 2. Ingestion

Each source gets one Python script that:
1. Reads the last loaded date: `SELECT MAX(date) FROM raw.<table>`.
2. Pulls only newer records from the source.
3. Does some basic cleaning (matching up column names, standardizing column names, removing NULL rows)
4. Loads them with `google-cloud-bigquery` using `WRITE_APPEND`.

Requirements:
- **Idempotent loads:** re-pulling a day must not create duplicates. Either load into a staging table and `MERGE` on the transaction ID, or append and deduplicate in dbt.
- **Partitioning:** partition raw tables by transaction date and cluster them on common filter columns.
- **Incremental dbt models:** large models use `materialized='incremental'` with a `unique_key` and an `is_incremental()` filter.
- **Credentials:** a GCP service account key, stored as a GitHub secret.
- **Source access:** confirm whether each source has an API. If one doesn't, schedule a CSV export to a Cloud Storage bucket or Drive folder, and have the script load new files from there.
- **Retiring sources (Shopify, DoorDash):** export their full history before access ends. Keep the raw tables frozen, and keep them in the dbt unions so historical trends stay intact.

## 3. Customer data and trends (later)

The same pipeline supports this. It needs new tables and dbt models, not a new architecture.
- **Ingestion:** pull customer, line-item and booking tables from each source, in addition to transactions.
- **Customer matching:** in dbt, match the same customer across sources (by email or phone) into one `dim_customers` table.
- **Changing attributes:** use dbt snapshots to track customer fields that change over time, such as membership status or address.
- **Marts:** customer metrics (lifetime value, visit frequency, recency), cohorts and retention, and product/time trends.
- **PII:** keep personal data in a restricted dataset, and expose only hashed IDs or aggregates to dashboards.

## 4. Orchestration: GitHub Actions

dbt Cloud can't run the Python ingestion scripts, so GitHub Actions is the single scheduler. One daily cron workflow:
1. Runs the ingestion scripts.
2. Runs dbt, either by running `dbt build` (dbt Core) in the workflow or by triggering the dbt Cloud job through its API.
3. Triggers the Tableau extract refresh (Looker Studio alternative needs no step).

Steps run in order, and a failed step stops everything after it, so dashboards never show partial data. GitHub emails you when a run fails.

# Order of work: 
- [ ] set up basic Tableau visualizations with daily transactions 
- [ ] data ingestion workflow (need to have API access to sources, possibly)
- [ ] work on building and testing the pipeline
   - ingestion scripts 
   - workflow scripts (GHA)
   - testing 
   - done criteria: automatic data ingestion, dbt transformations, and updates in Tableau
- [ ] expland from simple transaction trends to user/customer insights
