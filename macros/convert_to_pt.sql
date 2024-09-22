{% macro convert_to_pt(timestamp_column) %}
    TIMESTAMP(FORMAT_TIMESTAMP("%F %T", {{ timestamp_column }}, "America/Los_Angeles"))
{% endmacro %}