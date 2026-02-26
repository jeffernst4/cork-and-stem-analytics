WITH

    shopify_transactions AS (
        SELECT *
        FROM {{ ref('src_shopify_transactions') }}
    ),

    final AS (
        SELECT
            shopify_transactions.*,
            CASE
                WHEN product_type IS NULL THEN 'Unknown'
                WHEN product_type like '%Event%' THEN 'Event'
                ELSE product_type
            END AS transaction_category
        FROM shopify_transactions
    )

SELECT *
FROM final