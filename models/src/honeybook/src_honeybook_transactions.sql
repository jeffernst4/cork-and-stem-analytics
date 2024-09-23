WITH
    raw_data AS (
        SELECT
            `#` AS transaction_id,
            `Company Name` AS company_name,
            `Project Name` AS project_name,
            PARSE_DATE('%b %d, %Y', `Project Date`) AS project_date,
            `Vendor Info` AS vendor_info,
            `Client Info` AS client_info,
            `Invoice` AS invoice,
            `Status` AS status,
            `Payment Name` AS payment_name,
            `Payment Method` AS payment_method,
            `Refunded Amount` AS refunded_amount,
            `Dispute Cover` AS dispute_cover,
            `Tax` AS tax,
            `Tax 2` AS tax_2,
            `Tax 3` AS tax_3,
            `Late fee` AS late_fee,
            `Total Amount Paid` AS total_amount_paid,
            `Loan Repayment` AS loan_repayment,
            `Net Amount` AS net_amount,
            `Instant Deposit Fee` AS instant_deposit_fee,
            `Instant Deposit Fee Rate` AS instant_deposit_fee_rate,
            `Transaction Fee` AS transaction_fee,
            `Fee Rate` AS fee_rate,
            PARSE_DATE('%b %d, %Y', `Due Date`) AS due_date,
            PARSE_DATE('%b %d, %Y', `Charge Date`) AS charge_date,
            `Tax Rate` AS tax_rate,
            `Tax Rate 2` AS tax_rate_2,
            `Tax Rate 3` AS tax_rate_3,
            `Taxable Amount` AS taxable_amount,
            `Taxable Amount 2` AS taxable_amount_2,
            `Taxable Amount 3` AS taxable_amount_3,
            `Non Taxable Amount` AS non_taxable_amount,
            `Gratuity` AS gratuity,
            `Total Discount for Invoice` AS total_discount_for_invoice,
            `Relative Discount` AS relative_discount,
            `Disputed Net Amount` AS disputed_net_amount,
            `Dispute Fee` AS dispute_fee,
            PARSE_DATE('%b %d, %Y', `Disputed Date`) AS disputed_date
        FROM {{ source('honeybook', 'honeybook_transactions') }}
    )

SELECT *
FROM raw_data
WHERE company_name <> 'Total'