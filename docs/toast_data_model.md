# Toast data model

Built from `toast_samples/*.json` (sample of 5 orders).

## Diagram

```mermaid
erDiagram
    ORDERS ||..|{ orders_checks : "checks[]"
    orders_checks ||..|{ orders_selections : "selections[]"
    orders_selections ||..o{ orders_selections : "modifiers[]"
    orders_checks ||..o{ orders_payments : "payments[]"
    orders_checks ||..o{ orders_applied_discounts : "appliedDiscounts[]"
    orders_selections ||..o{ orders_applied_discounts : "appliedDiscounts[]"

    REVENUE_CENTERS ||--o{ ORDERS : revenueCenter
    DINING_OPTIONS ||--o{ ORDERS : diningOption
    EMPLOYEES ||--o{ ORDERS : server
    EMPLOYEES ||--o{ orders_payments : server
    menus_menu_items ||--o{ orders_selections : item
    menus_menu_groups ||--o{ orders_selections : itemGroup
    SALES_CATEGORIES ||--o{ orders_selections : salesCategory
    SALES_CATEGORIES ||--o{ menus_menu_items : salesCategory
    DISCOUNTS ||--o{ orders_applied_discounts : discount

    MENUS ||..|{ menus_menu_groups : "menuGroups[]"
    menus_menu_groups ||..o{ menus_menu_groups : "menuGroups[] (e.g. Wine > Reds)"
    menus_menu_groups ||..o{ menus_menu_items : "menuItems[]"

    EMPLOYEES }o--o{ JOBS : jobReferences
    EMPLOYEES ||--o{ TIME_ENTRIES : employeeReference
    JOBS ||--o{ TIME_ENTRIES : jobReference
    SHIFTS ||--o{ TIME_ENTRIES : shiftReference
    EMPLOYEES ||--o{ SHIFTS : employeeReference
    JOBS ||--o{ SHIFTS : jobReference

    ORDERS {
        string guid PK
        date businessDate
        timestamp openedDate
        timestamp closedDate
        int duration
        int numberOfGuests
        string source "In Store, Catering"
        string revenueCenter_guid FK
        string diningOption_guid FK
        string server_guid FK
        string table_guid
        bool voided
    }
    orders_checks {
        string guid PK
        float amount
        float totalAmount
        float taxAmount
        string paymentStatus
        json customer "PII, 1 of 5 checks"
        json appliedLoyaltyInfo "1 of 5 checks"
    }
    orders_selections {
        string guid PK
        string displayName
        int quantity
        float preDiscountPrice
        float price
        string item_guid FK
        string itemGroup_guid FK
        string salesCategory_guid FK
        bool voided
    }
    orders_payments {
        string guid PK
        string orderGuid
        string checkGuid
        string type "CREDIT, CASH, ..."
        float amount
        float tipAmount
        string server_guid FK
    }
    orders_applied_discounts {
        string guid PK
        string name "e.g. Member Discount 20%"
        float discountAmount
        string discount_guid FK
    }
    DISCOUNTS {
        string guid PK
        string name
        string type
        float amount
        float percentage
    }
    REVENUE_CENTERS {
        string guid PK
        string name "Bar, Patio, Lounge, ..."
    }
    DINING_OPTIONS {
        string guid PK
        string name
        string behavior "DINE_IN, TAKE_OUT, DELIVERY"
    }
    SALES_CATEGORIES {
        string guid PK
        string name "Wine, Food, Membership, ..."
    }
    MENUS {
        string guid PK
        string name "Food, Drinks, Retail, Events, ..."
    }
    menus_menu_groups {
        string guid PK
        string name
    }
    menus_menu_items {
        string guid PK
        string name
        float price
        string salesCategory_guid FK
    }
    EMPLOYEES {
        string guid PK
        json name_email_phone "PII, do not expose"
    }
    JOBS {
        string guid PK
        string title
        bool tipped
    }
    TIME_ENTRIES {
        string guid PK
        date businessDate
        timestamp inDate
        timestamp outDate
        float regularHours
        float overtimeHours
        float nonCashSales
        float nonCashTips
    }
    SHIFTS {
        string guid PK
        timestamp inDate
        timestamp outDate
    }
```

## Arrow types

Each end of a line shows how many rows can sit on that side.

| Symbol | Meaning |
|---|---|
| `\|\|` | exactly one |
| `o\|` | zero or one |
| `\|{` | one or more |
| `o{` | zero or more |

Examples:
- `ORDERS ||..|{ orders_checks`: one order has one or more checks; each check belongs to exactly one order.
- `REVENUE_CENTERS ||--o{ ORDERS`: one revenue center has zero or more orders; each order points to one revenue center.
- `EMPLOYEES }o--o{ JOBS`: many-to-many; an employee can hold several jobs, and a job can belong to several employees.

The label on a line is the JSON field that links the tables.
- **UPPERCASE** entities are raw tables in BigQuery. **lowercase** entities (`orders_checks`, `menus_menu_items`, ...) are nested inside the raw table named before the first `_`, not separate tables; dbt staging flattens them.
- **Dashed lines** (`..`, labels ending in `[]`): an array nested inside the parent JSON.
- **Solid lines** (`--`): a GUID reference to a lookup table.

## Notes from the sample
- Orders → checks → selections → modifiers are nested arrays inside one order JSON; dbt will flatten each level into its own staging model.
- Modifiers have the same structure as selections.
- Members: `Member Discount 20%` appears on selections' `appliedDiscounts`. Check-level `appliedDiscounts` were empty in this sample.
- Tips live on payments, not checks.
- Menu groups nest (Wine > Whites/Rosé/Reds/...).

