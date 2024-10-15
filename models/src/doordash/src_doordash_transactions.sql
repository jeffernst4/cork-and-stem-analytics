WITH
    raw_data AS (
        SELECT *
        FROM {{ source('doordash', 'doordash_transactions') }}
    ),
    final AS (
        SELECT
            order_id,
            store_name,
            store_id,
            business_id,
            merchant_supplied_id,
            street_address,
            city_and_state,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%Y-%m-%d', order_placed_date), ' ', order_placed_time)) AS order_placed_timestamp,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%Y-%m-%d', pickup_date), ' ', pickup_time)) AS pickup_timestamp,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%Y-%m-%d', delivery_date), ' ', delivery_time)) AS delivery_timestamp,
            is_cancelled,
            is_pickup,
            is_dashpass,
            subtotal,
            order_protocol,
            pos_error_status,
            pos_provider,
            is_missing_or_incorrect,
            error_charge,
            commission,
            rating,
            total_item_count,
            is_group_order,
            currency
        FROM {{ source('doordash', 'doordash_transactions') }}
    )

SELECT *
FROM final
