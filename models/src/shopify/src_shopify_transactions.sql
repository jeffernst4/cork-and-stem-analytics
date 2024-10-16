WITH
    raw_data AS (
        SELECT
            order_id,
            sale_id,
            date,
            product_type,
            product_title AS product_name,
            total_sales
        FROM {{ source('shopify', 'shopify_transactions') }}
    )

SELECT *
FROM raw_data