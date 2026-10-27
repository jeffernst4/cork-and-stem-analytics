# Toast data model

Built from `toast_samples/*.json` (sample of 5 orders).

## Diagram

```mermaid
erDiagram
    ORDERS ||--|{ CHECKS : "checks[]"
    CHECKS ||--|{ SELECTIONS : "selections[]"
    SELECTIONS ||--o{ SELECTIONS : "modifiers[]"
    CHECKS ||--o{ PAYMENTS : "payments[]"
    CHECKS ||--o{ APPLIED_DISCOUNTS : "appliedDiscounts[]"
    SELECTIONS ||--o{ APPLIED_DISCOUNTS : "appliedDiscounts[]"

    REVENUE_CENTERS ||--o{ ORDERS : revenueCenter
    DINING_OPTIONS ||--o{ ORDERS : diningOption
    EMPLOYEES ||--o{ ORDERS : server
    EMPLOYEES ||--o{ PAYMENTS : server
    MENU_ITEMS ||--o{ SELECTIONS : item
    MENU_GROUPS ||--o{ SELECTIONS : itemGroup
    SALES_CATEGORIES ||--o{ SELECTIONS : salesCategory
    SALES_CATEGORIES ||--o{ MENU_ITEMS : salesCategory
    DISCOUNTS ||--o{ APPLIED_DISCOUNTS : discount

    MENUS ||--|{ MENU_GROUPS : "menuGroups[]"
    MENU_GROUPS ||--o{ MENU_GROUPS : "menuGroups[] (e.g. Wine > Reds)"
    MENU_GROUPS ||--o{ MENU_ITEMS : "menuItems[]"

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
    CHECKS {
        string guid PK
        float amount
        float totalAmount
        float taxAmount
        string paymentStatus
        json customer "PII, 1 of 5 checks"
        json appliedLoyaltyInfo "1 of 5 checks"
    }
    SELECTIONS {
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
    PAYMENTS {
        string guid PK
        string orderGuid
        string checkGuid
        string type "CREDIT, CASH, ..."
        float amount
        float tipAmount
        string server_guid FK
    }
    APPLIED_DISCOUNTS {
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
    MENU_GROUPS {
        string guid PK
        string name
    }
    MENU_ITEMS {
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
- `ORDERS ||--|{ CHECKS`: one order has one or more checks; each check belongs to exactly one order.
- `REVENUE_CENTERS ||--o{ ORDERS`: one revenue center has zero or more orders; each order points to one revenue center.
- `EMPLOYEES }o--o{ JOBS`: many-to-many; an employee can hold several jobs, and a job can belong to several employees.

The label on a line is the JSON field that links the tables. Labels ending in `[]` are arrays nested inside the parent JSON. Other labels are GUID references to a lookup table.

## Notes from the sample
- Orders → checks → selections → modifiers are nested arrays inside one order JSON; dbt will flatten each level into its own staging model.
- Modifiers have the same structure as selections.
- Members: `Member Discount 20%` appears on selections' `appliedDiscounts`. Check-level `appliedDiscounts` were empty in this sample.
- Tips live on payments, not checks.
- Menu groups nest (Wine > Whites/Rosé/Reds/...).

