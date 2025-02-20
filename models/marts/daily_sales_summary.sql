WITH
    square_transactions AS (
        SELECT
            CONCAT('Square - ', transaction_category) AS type,
            DATE(transaction_timestamp) AS date,
            net_sales AS sales
        FROM {{ ref('stg_square_transactions') }}
    ),
    shopify_transactions AS (
        SELECT
            CONCAT('Shopify - ', transaction_category) AS type,
            date,
            total_sales AS sales
        FROM {{ ref('stg_shopify_transactions') }}
    ),
    doordash_transactions AS (
        SELECT
            'DoorDash' AS type,
            DATE(pickup_timestamp) AS date,
            subtotal AS sales
        FROM {{ ref('src_doordash_transactions') }}
    ),
    honeybook_projects AS (
        SELECT
            'Honeybook' AS type,
            event_date AS date,
            net_sales AS sales
        FROM {{ ref('stg_honeybook_projects') }}
    ),
    combined_sales AS (
        SELECT *
        FROM square_transactions
        UNION ALL
        SELECT *
        FROM shopify_transactions
        UNION ALL
        SELECT *
        FROM doordash_transactions
        UNION ALL
        SELECT *
        FROM honeybook_projects
    ),
    final AS (
        SELECT
            CASE
                WHEN type IN ('Square - Onsite Event', 'Shopify - Event', 'Honeybook') THEN 'Event'
                WHEN type = 'Square - Membership' THEN 'Membership'
                WHEN type = 'Square - General' THEN  'In-Store'
                WHEN type LIKE 'Shopify%' THEN 'Online'
                ELSE type
            END AS transaction_category,
            type AS transaction_type,
            date AS transaction_date,
            DATE_TRUNC(date - 1, WEEK) + 1 AS transaction_week,
            DATE_TRUNC(date, MONTH) AS transaction_month, 
            SUM(sales) AS total_sales
        FROM combined_sales
        GROUP BY type, date
    )
    
SELECT *
FROM final