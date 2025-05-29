WITH

    raw_data AS (
        SELECT *
        FROM {{ source('events', 'event_log') }}
    ),

    final AS (
        SELECT
            event_id,
            event_name,
            event_location,
            event_type,
            event_category,
            date AS event_date,
            TIMESTAMP(CONCAT(date, ' ', start_time)) AS event_start_timestamp,
            TIMESTAMP(CONCAT(date, ' ', end_time)) AS event_end_timestamp  
        FROM raw_data
        WHERE event_name IS NOT NULL
    )

SELECT *
FROM final