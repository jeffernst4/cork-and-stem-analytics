WITH

    raw_data AS (
        SELECT *
        FROM {{ source('doordash', 'doordash_transactions') }}
    ),

    final AS (
        SELECT
            doordash_order_id,
            doordash_transaction_id,
            transaction_type,
            store_name,
            store_id,
            business_id,
            merchant_store_id,
            TIMESTAMP(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S', timestamp_local_time)) AS order_timestamp,
            final_order_status,
            subtotal,
            currency
        FROM {{ source('doordash', 'doordash_transactions') }}
    )

SELECT *
FROM final
