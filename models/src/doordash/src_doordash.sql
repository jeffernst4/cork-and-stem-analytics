SELECT
    year,
    price,
    review_score,
    mpg,
    key_features,
    value_score
FROM {{ source('doordash', 'doordash_sales_data') }}