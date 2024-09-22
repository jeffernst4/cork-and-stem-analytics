WITH
    raw_data AS (
        SELECT
            `Date` AS date,
            `Time` AS time,
            CASE 
                WHEN `Time Zone` = 'Pacific Time (US & Canada)' THEN 'America/Los_Angeles'
                -- Add other mappings as needed
                ELSE 'America/Los_Angeles'
            END AS timezone,
            `Category` AS item_category,
            `Item` AS item,
            `Qty` AS quantity,
            `Price Point Name` AS price_point_name,
            `SKU` AS sku,
            `Modifiers Applied` AS modifiers_applied,
            `Gross Sales` AS gross_sales,
            `Discounts` AS discounts,
            `Net Sales` AS net_sales,
            `Tax` AS tax,
            `Transaction ID` AS transaction_id,
            `Payment ID` AS payment_id,
            `Device Name` AS device_name,
            `Notes` AS notes,
            `Details` AS details,
            `Event Type` AS transaction_type,
            `Location` AS location,
            `Dining Option` AS dining_option,
            `Customer ID` AS customer_id,
            `Customer Name` AS customer_name,
            `Customer Reference ID` AS customer_reference_id,
            `Unit` AS unit,
            `Count` AS count,
            `Itemization Type` AS itemization_type,
            `Fulfillment Note` AS fulfillment_note,
            `Token` AS token
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
        FROM raw_data
    )

SELECT *
FROM final
