WITH
    raw_data AS (
        SELECT *
        FROM {{ source('evey', 'evey_attendees') }}
    ),
    final AS (
        SELECT
            attendee_id,
            event_number AS event_id,
            event_title,
            order_id,
            order_name
            email,
            phone,
            first_name,
            last_name,
            {{ convert_to_pt("PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S %z', purchased_at)") }} AS purchase_timestamp,
            {{ convert_to_pt('TIMESTAMP(eticket_sent_at)') }} AS ticket_sent_timestamp
        FROM raw_data
    )

SELECT *
FROM final
