WITH
    raw_data AS (
        SELECT
            `Order ID` AS order_id,
            `Store Name` AS store_name,
            `Store ID` AS store_id,
            `Business ID` AS business_id,
            `Merchant Supplied ID` AS merchant_supplied_id,
            `Street Address` AS street_address,
            `City and State` AS city_and_state,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%m/%d/%Y', `Order Placed Date`), ' ', `Order Placed Time`)) AS order_placed_timestamp,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%m/%d/%Y', `Pickup Date`), ' ', `Pickup Time`)) AS pickup_timestamp,
            TIMESTAMP(CONCAT(SAFE.PARSE_DATE('%m/%d/%Y', `Delivery Date`), ' ', `Delivery Time`)) AS delivery_timestamp,
            `Was Cancelled` AS is_cancelled,
            `Was Pickup` AS is_pickup,
            `Was Dashpass` AS is_dashpass,
            `Subtotal` AS subtotal,
            `Order Protocol` AS order_protocol,
            `POS Error Status` AS pos_error_status,
            `POS Provider` AS pos_provider,
            `Is Missing or Incorrect` AS is_missing_or_incorrect,
            `Error Charge` AS error_charge,
            `Commission` AS commission,
            `Rating` AS rating,
            `Total Item Count` AS total_item_count,
            `Is Group Order` AS is_group_order,
            `Currency` AS currency
        FROM {{ source('doordash', 'doordash_transactions') }}
    )

SELECT *
FROM raw_data
