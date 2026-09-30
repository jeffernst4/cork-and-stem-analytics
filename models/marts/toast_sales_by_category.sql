WITH

    toast_items AS (
        SELECT
            sales_category,
            qty_sold,
            net_item_amt
        FROM {{ ref('src_toast_items') }}
    ),

    final AS (
        SELECT
            sales_category,
            SUM(qty_sold) AS total_qty_sold,
            SUM(net_item_amt) AS total_net_sales
        FROM toast_items
        GROUP BY sales_category
    )

SELECT *
FROM final
ORDER BY total_net_sales DESC
