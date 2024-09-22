{% macro convert_sales_to_float(sales_column) %}
    CAST(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        {{ sales_column }}, '(', '-'
                    ), ')', ''
                ), '$', ''
            ), ',', ''
        ) AS FLOAT64
    )
{% endmacro %}