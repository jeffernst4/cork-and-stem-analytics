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
            'Shopify' AS type,
            DATE(order_timestamp) AS date,
            total_sales AS sales
        FROM {{ ref('src_shopify_transactions') }}
    ),
    doordash_transactions AS (
        SELECT
            'DoorDash' AS type,
            DATE(order_placed_timestamp) AS date,
            subtotal AS sales
        FROM {{ ref('src_doordash_transactions') }}
    ),
    honeybook_transactions AS (
        SELECT
            'Honeybook' AS type,
            charge_date AS date,
            net_amount AS sales
        FROM {{ ref('src_honeybook_transactions') }}
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
        FROM honeybook_transactions
    ),
    final AS (
        SELECT
            CASE
                WHEN type IN ('Square - Onsite Event', 'Honeybook') THEN 'Event'
                WHEN type = 'Square - Membership' THEN 'Membership'
                WHEN type = 'Square - General' THEN  'In-Store'
                ELSE type
            END AS transaction_category,
            type AS transaction_type,
            date AS transaction_date,
            DATE_TRUNC(date, WEEK) AS transaction_week,
            DATE_TRUNC(date, MONTH) AS transaction_month, 
            SUM(sales) AS total_sales
        FROM combined_sales
        GROUP BY type, date
    )
    
SELECT *
FROM final