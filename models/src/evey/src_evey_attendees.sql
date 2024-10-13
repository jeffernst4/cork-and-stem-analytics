WITH
    raw_data AS (
        SELECT
            id,
            event_number,
            event_title,
            order_id,
            order_name
            email,
            phone,
            first_name,
            last_name
        FROM {{ source('evey', 'evey_attendees') }}
    )

SELECT *
FROM raw_data
