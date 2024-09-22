WITH
    square_transactions AS (
        SELECT
            CASE
                WHEN is_membership THEN 'Square - Membership'
                WHEN is_during_onsite_event THEN 'Square - Onsite Event'
                ELSE 'Square - General'
                END AS type,
            DATE(transaction_timestamp) AS date,
            DATE_TRUNC(DATE(transaction_timestamp), WEEK) AS week,
            net_sales AS sales
        FROM {{ ref('stg_square_transactions') }}
    ),
    shopify_transactions AS (
        SELECT
            'Shopify' AS type,
            DATE(order_timestamp) AS date,
            DATE_TRUNC(DATE(order_timestamp), WEEK) AS week,
            total_sales AS sales
        FROM {{ ref('src_shopify_transactions') }}
    ),
    combined_sales AS (
        SELECT *
        FROM square_transactions
        UNION ALL
        SELECT *
        FROM shopify_transactions
    ),
    final AS (
        SELECT
            type AS transaction_type,
            date AS transaction_date,
            week AS transaction_week,
            SUM(sales) AS total_sales
        FROM combined_sales
        GROUP BY 1, 2, 3
    )
    

SELECT *
FROM final