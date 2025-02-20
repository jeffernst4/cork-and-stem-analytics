WITH
    square_transactions AS (
        SELECT
            DATE(transaction_timestamp) AS transaction_date,
            item,
            item_category,
            net_sales
        FROM {{ ref('stg_square_transactions') }}
        WHERE transaction_category = 'General'
    ),
    final AS (
        SELECT
            transaction_date,
            DATE_TRUNC(transaction_date - 1, WEEK) + 1 AS transaction_week,
            DATE_TRUNC(transaction_date, MONTH) AS transaction_month, 
            item_category,
            SUM(net_sales) AS total_sales
        FROM square_transactions
        GROUP BY transaction_date, item_category
    )

SELECT *
FROM final