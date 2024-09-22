WITH
    square_transactions AS (
        SELECT *
        FROM {{ ref('src_square_transactions') }}
    ),
    onsite_events AS (
        SELECT
            event_id,
            event_name,
            event_type,
            event_category,
            event_start_timestamp,
            event_end_timestamp
        FROM {{ ref('src_event_log') }}
        WHERE event_type = 'Onsite Event'
    ),
    square_transaction_details AS (
        SELECT
            square_transactions.*,
            item like '%Submatic%' OR item_category = 'Membership' AS is_membership,
            onsite_events.event_id IS NOT NULL AS is_during_onsite_event,
            onsite_events.event_id,
            onsite_events.event_name,
            onsite_events.event_category
        FROM square_transactions
        LEFT JOIN onsite_events
        ON square_transactions.transaction_timestamp BETWEEN onsite_events.event_start_timestamp AND onsite_events.event_end_timestamp
    ),
    final AS (
        SELECT
            *,
            CASE
                WHEN is_membership THEN 'Membership'
                WHEN is_during_onsite_event THEN 'Onsite Event'
                ELSE 'General'
            END AS transaction_category
        FROM square_transaction_details
    )

SELECT *
FROM final