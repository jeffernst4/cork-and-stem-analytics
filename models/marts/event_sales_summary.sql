WITH
    honeybook_transactions AS (
        SELECT
            NULL AS event_id,
            project_name AS event_name,
            project_date AS event_date,
            event_type,
            event_category,
            SUM(net_sales) AS sales
        FROM {{ ref('stg_honeybook_transactions') }}
        GROUP BY 1, 2, 3, 4, 5
    ),
    shopify_eventS AS (
        SELECT
            event_id,
            event_name,
            COALESCE(event_date, SAFE_CAST(order_timestamp AS DATE)) AS event_date,
            event_type,
            event_category,
            SUM(total_event_sales) AS sales
        FROM {{ ref('shopify_events') }}
        GROUP BY 1, 2, 3, 4, 5
    ),
    square_transactions AS (
        SELECT
            event_id,
            event_name,
            SAFE_CAST(transaction_timestamp AS DATE) AS event_date,
            event_type,
            event_category,
            SUM(net_sales) AS sales
        FROM {{ ref('stg_square_transactions') }}
        WHERE transaction_category = 'Onsite Event'
        GROUP BY 1, 2, 3, 4, 5
    ),
    final AS (
        SELECT *
        FROM honeybook_transactions
        UNION ALL
        SELECT *
        FROM shopify_events
        UNION ALL
        SELECT *
        FROM square_transactions
    )

SELECT *
FROM final