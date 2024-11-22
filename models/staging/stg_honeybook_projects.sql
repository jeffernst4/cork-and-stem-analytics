WITH
    honeybook_projects AS (
        SELECT
            company_name,
            project_name,
            project_creation_date,
            booked_date,
            event_date,
            total_project_value - refunded_amount AS net_sales
        FROM {{ ref('src_honeybook_projects') }}
        WHERE is_booked OR total_project_value > 0
    ),
    event_log AS (
        SELECT
            event_id,
            event_name,
            event_type,
            event_category,
            event_date
        FROM {{ ref('src_event_log') }}
    ),
    final AS (
        SELECT
            honeybook_projects.*,
            event_log.event_id,
            event_log.event_type,
            event_log.event_category
        FROM honeybook_projects
            LEFT JOIN event_log
                ON honeybook_projects.event_date = event_log.event_date
                AND honeybook_projects.project_name = event_log.event_name
    )

SELECT *
FROM final