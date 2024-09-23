WITH
    honeybook_transactions AS (
        SELECT
            project_name AS event_name,
            project_date AS event_date,
            event_type,
            event_category,
            SUM(net_sales) AS total_sales
        FROM {{ ref('stg_honeybook_transactions') }}
        GROUP BY 1, 2, 3, 4
    ),
    shopify_transactions AS (
        SELECT
            product_name,
            DATE(order_timestamp) AS order_date,
            total_sales
        FROM {{ ref('stg_shopify_transactions') }}
        WHERE transaction_category = 'Event'
    ),
    event_transa
    square_transactions AS (
        SELECT *
        FROM {{ ref('stg_square_transactions') }}
        WHERE transaction_category = 'Onsite Event'
    ),
    final AS (
        SELECT
            project_name AS event_name,
            project_date AS event_date,
            COALESCE(event_log.event_type, 'Unknown') AS event_type,
            COALESCE(event_log.event_category, 'Unknown') AS event_category,
            honeybook_events.total_sales
        FROM honeybook_events
        LEFT JOIN event_log
        ON honeybook_events.project_date = DATE(event_log.event_start_timestamp)
        AND honeybook_events.project_name = event_log.event_name
    )

SELECT *
FROM final