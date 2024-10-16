WITH
    raw_data AS (
        SELECT *
        FROM {{ source('honeybook', 'honeybook_projects') }}
    ),
    final AS (
        SELECT
            company_name,
            project_name,
            is_booked,
            project_owner,
            project_type,
            lead_source,
            {{ convert_to_pt('project_creation_date') }} AS project_creation_date,
            {{ convert_to_pt('booked_date') }} AS booked_date,
            CAST(project_date AS DATE) AS event_date,
            total_project_value,
            tax,
            total_paid,
            gratuity,
            refunded_amount
        FROM raw_data
    )

SELECT *
FROM final