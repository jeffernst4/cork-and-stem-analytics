WITH
    shopify_transactions AS (
        SELECT *
        FROM {{ ref('src_shopify_transactions') }}
    ),
    event_log AS (
        SELECT
            event_id,
            event_name,
            event_type,
            event_category,
            DATE(event_start_timestamp) AS event_date,
            event_start_timestamp
        FROM {{ ref('src_event_log') }}
    ),
    final AS (
        SELECT
            shopify_transactions.*,
            CASE
                WHEN product_type IS NULL THEN 'Unknown'
                WHEN product_type like '%Event%' THEN 'Event'
                ELSE product_type
            END AS transaction_category,
            event_log.event_id,
            event_log.event_date,
            event_log.event_type,
            event_log.event_category
        FROM shopify_transactions
        LEFT JOIN event_log
        ON DATE(shopify_transactions.order_timestamp) BETWEEN DATE_ADD(event_log.event_date, INTERVAL -90 DAY) AND event_log.event_date
        AND shopify_transactions.product_name = event_log.event_name
        QUALIFY ROW_NUMBER() OVER (PARTITION BY shopify_transactions.sale_id ORDER BY event_log.event_start_timestamp ASC) = 1
        --- CHANGE THIS TO USE THE attendee list from the order  and then match to event id in eveent log
    )

SELECT *
FROM final