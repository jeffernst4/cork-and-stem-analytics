WITH

    calendar AS (
        SELECT
            date,
            DATE_TRUNC(date, YEAR) AS year,
            DATE_TRUNC(date, MONTH) AS month,
            EXTRACT(DAY FROM date) AS day,
            FORMAT_DATE('%A', date) AS day_of_week,
            DATE_TRUNC(date - 1, WEEK) + 1 AS week
        FROM
            UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2030-12-31', INTERVAL 1 DAY)) AS date
    )

SELECT *
FROM calendar