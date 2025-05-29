WITH

    honeybook_projects AS (
        SELECT
            CAST(NULL AS STRING) AS event_id,
            project_name AS event_name,
            event_date,
            event_location,
            event_type,
            event_category,
            net_sales AS sales
        FROM {{ ref('stg_honeybook_projects') }}
    ),

    shopify_events AS (
        SELECT
            event_id,
            event_name,
            COALESCE(event_date, order_date) AS event_date,
            event_location,
            event_type,
            event_category,
            total_event_sales AS sales
        FROM {{ ref('shopify_events') }}
    ),

    square_transactions AS (
        SELECT
            event_id,
            event_name,
            SAFE_CAST(transaction_timestamp AS DATE) AS event_date,
            event_location,
            event_type,
            event_category,
            net_sales AS sales
        FROM {{ ref('stg_square_transactions') }}
        WHERE transaction_category = 'Onsite Event'
    ),

    combined_sales AS (
        SELECT *
        FROM honeybook_projects
        UNION ALL
        SELECT *
        FROM shopify_events
        UNION ALL
        SELECT *
        FROM square_transactions
    ),
    
    final AS (
        SELECT
            event_id,
            event_name,
            event_date,
            DATE_TRUNC(event_date - 1, WEEK) + 1 AS event_week,
            DATE_TRUNC(event_date, MONTH) AS event_month,
            COALESCE(event_location, 'Uncategorized') AS event_location,
            COALESCE(event_type, 'Uncategorized') AS event_type,
            COALESCE(event_category, 'Uncategorized') AS event_category,
            SUM(sales) AS total_sales
        FROM combined_sales
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
    )

SELECT *
FROM final