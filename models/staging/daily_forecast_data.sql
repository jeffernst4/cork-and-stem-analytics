WITH

    calendar AS (
        SELECT
            date,
            year,
            month,
            day,
            day_of_week,
            week
        FROM {{ ref('dim_calendar') }}
    ),

    daily_sales_summary AS (
        SELECT
            CASE
                WHEN transaction_category IN ('DoorDash', 'Online')
                    THEN 'Online'
                WHEN transaction_category = 'Membership'
                    THEN 'Membership'
                WHEN transaction_type LIKE '%Wedding%'
                    OR transaction_type = 'Honeybook - Other'
                    THEN 'Floral Events'
                WHEN transaction_type = 'Square - General'
                    THEN 'In-Store'
                WHEN transaction_type = 'Shopify - Event'
                    THEN 'Workshops'
                WHEN transaction_type LIKE 'Honeybook%'
                    OR transaction_type = 'Square - Onsite Event'
                    THEN 'General Events'
                ELSE 'Other'
            END AS forecast_category,
            transaction_date,
            SUM(total_sales) as total_sales
        FROM {{ ref('daily_sales_summary') }}
        GROUP BY 1, 2
    ),

    forecast_categories AS (
        SELECT
            DISTINCT forecast_category
        FROM daily_sales_summary
    ),

    final AS (
        SELECT
            calendar.date,
            calendar.day_of_week,
            calendar.month,
            forecast_categories.forecast_category,
            COALESCE(daily_sales_summary.total_sales, 0) AS total_sales
        FROM calendar
        CROSS JOIN forecast_categories
        LEFT JOIN daily_sales_summary
            ON calendar.date = daily_sales_summary.transaction_date
            AND forecast_categories.forecast_category = daily_sales_summary.forecast_category
    )

SELECT *
FROM final