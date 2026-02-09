# Nathemni Database Schema (SQLite)

The following schema covers all features including Tasks, Expenses, People, Tools, Car Management, and Meals.

## Core Tables

### users
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | Local unique ID |
| server_id | INTEGER UNIQUE | ID from the remote server |
| name | TEXT | User's full name |
| email | TEXT | User's email address |
| phone | TEXT | User's phone number |
| language | TEXT | Preferred language (default: 'ar') |
| is_active | INTEGER | 1 for active, 0 for inactive |
| created_at | TEXT | ISO8601 timestamp |

### categories
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| name_ar | TEXT | Arabic name |
| name_en | TEXT | English name |
| type | TEXT | Category type (e.g., task, expense) |
| icon | TEXT | Icon name |
| color | TEXT | Hex color code |
| user_id | INTEGER | FK to users(id) |

## Tasks & Expenses

### tasks
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| category_id | INTEGER | FK to categories(id) |
| title | TEXT | Task title |
| description | TEXT | Task details |
| priority | TEXT | low, medium, high |
| status | TEXT | pending, completed |
| due_date | TEXT | Date string |
| due_time | TEXT | Time string |

### expenses
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| category_id | INTEGER | FK to categories(id) |
| amount | REAL | Transaction amount |
| currency | TEXT | Currency code (e.g., LYD) |
| expense_date | TEXT | Date string |
| payment_method | TEXT | cash, bank, etc. |

## People & Tools

### people
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| name | TEXT | Full name |
| type | TEXT | family, friend, work, etc. |

### tool_categories
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| name_ar | TEXT | Arabic name |

### tools
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| category_id | INTEGER | FK to tool_categories(id) |
| parent_id | INTEGER | FK to tools(id) for extensions |
| name | TEXT | Tool name |
| status | TEXT | available, lent, rented, maintenance |

### tool_transactions
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| tool_id | INTEGER | FK to tools(id) |
| person_id | INTEGER | FK to people(id) |
| type | TEXT | lend, rent |
| borrow_date | TEXT | Start date |
| expected_return_date | TEXT | Due date |
| status | TEXT | active, returned |

## Car Management

### cars
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| name | TEXT | Car nickname |
| plate_number | TEXT | |

### car_oil_changes / car_documents
*Detailed tables for tracking maintenance and paperwork expiry.*

## Notifications
### notifications
| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY | |
| user_id | INTEGER | FK to users(id) |
| title | TEXT | |
| body | TEXT | |
| type | TEXT | tool_due, doc_expiry, etc. |
| scheduled_at | TEXT | ISO8601 timestamp |
