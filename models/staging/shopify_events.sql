WITH
    shopify_transactions AS (
        SELECT
            order_id,
            sale_id,
            order_timestamp,
            product_name,
            transaction_category,
            total_sales
        FROM {{ ref('stg_shopify_transactions') }}
    ),
    evey_attendees AS (
        SELECT
            attendee_id,
            event_id,
            order_id
        FROM {{ ref('src_evey_attendees') }}
    ),
    event_log AS (
        SELECT
            event_id,
            event_name,
            event_type,
            event_category,
            event_date,
            event_start_timestamp
        FROM {{ ref('src_event_log') }}
    ),
    shopify_event_orders AS (
        SELECT
            order_id,
            order_timestamp,
            SUM(total_sales) AS total_sales
        FROM shopify_transactions
        WHERE transaction_category = 'Event'
        GROUP BY 1, 2
    ),
    evey_orders AS (
        SELECT
            order_id,
            event_id,
            COUNT(*) AS attendee_count,
            SUM(COUNT(*)) OVER (PARTITION BY order_id) AS order_attendee_count,
            COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY order_id) AS attendee_order_proportion
        FROM evey_attendees
        GROUP BY 1, 2
    ),
    final AS (
        SELECT
            shopify_event_orders.order_id,
            shopify_event_orders.order_timestamp,
            evey_orders.event_id,
            event_log.event_name,
            event_log.event_date,
            event_log.event_type,
            event_log.event_category,
            evey_orders.attendee_count,
            evey_orders.order_attendee_count,
            shopify_event_orders.total_sales * COALESCE(evey_orders.attendee_order_proportion, 1) AS total_event_sales
        FROM shopify_event_orders
            LEFT JOIN evey_orders
                ON shopify_event_orders.order_id = evey_orders.order_id
            LEFT JOIN event_log
                ON evey_orders.event_id = event_log.event_id
    )

SELECT *
FROM final
