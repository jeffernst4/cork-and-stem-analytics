WITH
    raw_data AS (
        SELECT *
        FROM {{ source('toast', 'toast_items') }}
    ),
    final AS (
        SELECT
            masterid AS master_id,
            parentid AS parent_id,
            itemguid AS item_guid,
            item,
            COALESCE(sales_category, 'No Category') AS sales_category,
            item_tags,
            deferred,
            qty_sold,
            avg_price,
            item_cogs,
            gross_item_amt,
            discount_amt,
            refund_amt,
            void_amt,
            net_item_amt,
            cogs,
            gross_profit,
            gross_margin_pct,
            tax_amt,
            waste_count,
            waste_amt,
            voided_gross_item_amt,
            voided_qty_sold,
            item_qty_incl_voids,
            gross_item_amt_incl_voids
        FROM raw_data
        -- exclude the export's summary/total row
        WHERE item IS NOT NULL
    )

SELECT *
FROM final
