# Tool Management Module Implementation
## Overview
Complete implementation of tool management system for tracking company tools/equipment, including categorization, renting/lending, tracking usage, and income calculation.
## Database Schema (Version 11)
### Tables to Create
1. **tool_categories** - Predefined categories for tools
2. **tools** - Main tool inventory
3. **tool_extensions** - Attachments/accessories for tools
4. **tool_transactions** - Rent/lend transaction records
5. **transaction_extensions** - Junction table for selected extensions per transaction
### Key Relationships
* tools → tool_categories (many-to-one)
* tool_extensions → tools (many-to-one)
* tool_transactions → tools, people (many-to-one)
* transaction_extensions → tool_transactions, tool_extensions (junction)
* income → tool_transactions (one-to-one for rentals)
## Implementation Steps
### Phase 1: Data Layer
1. Add database tables in `database_helper.dart` (bump to version 11)
2. Create models:
    * `ToolCategoryModel`
    * `ToolModel`
    * `ToolExtensionModel`
    * `ToolTransactionModel`
3. Create `ToolsRepository` with all CRUD operations
### Phase 2: State Management
1. Create `tools_providers.dart` with:
    * `toolCategoriesProvider`
    * `toolsProvider` with filters (category, status)
    * `toolExtensionsProvider`
    * `toolTransactionsProvider`
    * `toolSummaryProvider` (stats/reports)
### Phase 3: UI Screens
1. **ToolsScreen** - Main list with category tabs and status filters
2. **AddEditToolDialog** - Create/edit tool
3. **ToolDetailsScreen** - View tool info, extensions, history
4. **AddExtensionDialog** - Add extension to tool
5. **RentLendScreen** - Create transaction (auto-detect rent/lend)
6. **TransactionLogsScreen** - History with filters and reports
7. **ReturnToolDialog** - Return tool and calculate fees
### Phase 4: Business Logic
1. Auto-detect rent vs lend based on price
2. Calculate total: (tool_price + extensions_price) × days
3. Calculate late fees after due date
4. Create income record on rental return
5. Schedule notifications for due dates
## File Structure
```warp-runnable-command
lib/features/tools/
├── data/
│   ├── tool_category_model.dart
│   ├── tool_model.dart
│   ├── tool_extension_model.dart
│   ├── tool_transaction_model.dart
│   └── tools_repository.dart
├── providers/
│   └── tools_providers.dart
└── presentation/
    ├── tools_screen.dart
    ├── tool_details_screen.dart
    ├── add_edit_tool_dialog.dart
    ├── add_extension_dialog.dart
    ├── rent_lend_screen.dart
    ├── transaction_logs_screen.dart
    └── widgets/
        ├── tool_card.dart
        ├── extension_list_item.dart
        └── transaction_card.dart
```
