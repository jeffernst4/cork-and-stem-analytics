SELECT
    event_id,
    event_name,
    event_type,
    event_category,
    CAST(date || ' ' || start_time AS TIMESTAMP) AS event_start_timestamp,
    CAST(date || ' ' || end_time AS TIMESTAMP) AS event_end_timestamp
FROM {{ source('events', 'event_log') }}
WHERE event_name IS NOT NULL