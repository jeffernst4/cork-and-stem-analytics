WITH
    raw_data AS (
        SELECT *
        FROM {{ source('square', 'square_transactions') }}
    ),
    main AS (
        SELECT
            date,
            time,
            CASE 
                WHEN time_zone = 'Pacific Time (US & Canada)' THEN 'America/Los_Angeles'
                -- Add other mappings as needed
                ELSE 'America/Los_Angeles'
            END AS timezone,
            category AS item_category,
            item,
            qty AS quantity,
            price_point_name,
            sku,
            modifiers_applied,
            gross_sales,
            discounts,
            net_sales,
            tax,
            transaction_id,
            payment_id,
            device_name,
            notes,
            details,
            event_type AS transaction_type,
            location,
            dining_option,
            customer_id,
            customer_name,
            customer_reference_id,
            unit,
            count,
            itemization_type,
            fulfillment_note,
            token
        FROM {{ source('square', 'square_transactions') }}
    ),
    final AS (
        SELECT
            {{ convert_to_pt("TIMESTAMP(CONCAT(date, ' ', time), timezone)") }} AS transaction_timestamp,
            item_category,
            item,
            quantity,
            price_point_name,
            sku,
            modifiers_applied,
            {{ convert_sales_to_float('gross_sales') }} AS gross_sales,
            {{ convert_sales_to_float('discounts') }} AS discounts,
            {{ convert_sales_to_float('net_sales') }} AS net_sales,
            {{ convert_sales_to_float('tax') }} AS tax,
            transaction_id,
            payment_id,
            device_name,
            notes,
            details,
            transaction_type,
            location,
            dining_option,
            customer_id,
            customer_name,
            customer_reference_id,
            unit,
            count,
            itemization_type,
            fulfillment_note,
            token
        FROM main
    )

SELECT *
FROM final
