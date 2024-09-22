SELECT
    event_id,
    event_name,
    event_type,
    event_category,
    TIMESTAMP(CONCAT(date, ' ', start_time)) AS event_start_timestamp,
    TIMESTAMP(CONCAT(date, ' ', end_time)) AS event_end_timestamp  
FROM {{ source('events', 'event_log') }}
WHERE event_name IS NOT NULL