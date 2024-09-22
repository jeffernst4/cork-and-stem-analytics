WITH
    raw_data AS (
        SELECT
            `#` as transaction_id,
            `Company Name` as company_name,
            `Project Name` as project_name,
            PARSE_DATE('%b %d, %Y', `Project Date`) AS project_date,
            `Vendor Info` as vendor_info,
            `Client Info` as client_info,
            `Invoice` as invoice,
            `Status` as status,
            `Payment Name` as payment_name,
            `Payment Method` as payment_method,
            `Refunded Amount` as refunded_amount,
            `Dispute Cover` as dispute_cover,
            `Tax` as tax,
            `Tax 2` as tax_2,
            `Tax 3` as tax_3,
            `Late fee` as late_fee,
            `Total Amount Paid` as total_amount_paid,
            `Loan Repayment` as loan_repayment,
            `Net Amount` as net_amount,
            `Instant Deposit Fee` as instant_deposit_fee,
            `Instant Deposit Fee Rate` as instant_deposit_fee_rate,
            `Transaction Fee` as transaction_fee,
            `Fee Rate` as fee_rate,
            PARSE_DATE('%b %d, %Y', `Due Date`) AS due_date,
            PARSE_DATE('%b %d, %Y', `Charge Date`) AS charge_date,
            `Tax Rate` as tax_rate,
            `Tax Rate 2` as tax_rate_2,
            `Tax Rate 3` as tax_rate_3,
            `Taxable Amount` as taxable_amount,
            `Taxable Amount 2` as taxable_amount_2,
            `Taxable Amount 3` as taxable_amount_3,
            `Non Taxable Amount` as non_taxable_amount,
            `Gratuity` as gratuity,
            `Total Discount for Invoice` as total_discount_for_invoice,
            `Relative Discount` as relative_discount,
            `Disputed Net Amount` as disputed_net_amount,
            `Dispute Fee` as dispute_fee,
            PARSE_DATE('%b %d, %Y', `Disputed Date`) AS disputed_date
        FROM {{ source('honeybook', 'honeybook_transactions') }}
    )

SELECT *
FROM raw_data
WHERE company_name <> 'Total'