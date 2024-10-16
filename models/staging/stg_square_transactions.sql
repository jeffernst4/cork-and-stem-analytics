WITH
    square_transactions AS (
        SELECT *
        FROM {{ ref('src_square_transactions') }}
    ),
    onsite_events AS (
        SELECT
            event_id,
            event_name,
            DATE(event_start_timestamp) AS event_date,
            event_type,
            event_category,
            event_start_timestamp,
            event_end_timestamp
        FROM {{ ref('src_event_log') }}
        WHERE event_type = 'Onsite Event'
    ),
    final AS (
        SELECT
            square_transactions.*,
            CASE
                WHEN item like '%Submatic%' OR item_category = 'Membership' THEN 'Membership'
                WHEN onsite_events.event_name IS NOT NULL OR item_category = 'Private Event' THEN 'Onsite Event'
                ELSE 'General'
            END AS transaction_category,
            onsite_events.event_id,
            onsite_events.event_name,
            onsite_events.event_date,
            onsite_events.event_type,
            onsite_events.event_category
        FROM square_transactions
            LEFT JOIN onsite_events
                ON square_transactions.transaction_timestamp BETWEEN onsite_events.event_start_timestamp AND onsite_events.event_end_timestamp
    )

SELECT *
FROM final