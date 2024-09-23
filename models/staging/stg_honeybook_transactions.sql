WITH
    honeybook_transactions AS (
        SELECT
            transaction_id,
            company_name,
            project_name,
            project_date,
            vendor_info,
            client_info,
            invoice,
            status,
            payment_name,
            payment_method,
            net_amount - refunded_amount AS net_sales
        FROM {{ ref('src_honeybook_transactions') }}
    ),
    event_log AS (
        SELECT
            event_id,
            event_name,
            event_type,
            event_category,
            event_start_timestamp,
            event_end_timestamp
        FROM {{ ref('src_event_log') }}
    ),
    final AS (
        SELECT
            honeybook_transactions.*,
            event_log.event_id,
            event_log.event_type,
            event_log.event_category
        FROM honeybook_transactions
        LEFT JOIN event_log
        ON honeybook_transactions.project_date = DATE(event_log.event_start_timestamp)
        AND honeybook_transactions.project_name = event_log.event_name
    )

SELECT *
FROM final