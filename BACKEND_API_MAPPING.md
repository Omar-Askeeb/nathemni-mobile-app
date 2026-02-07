# Backend API Mapping

This document maps the Laravel backend API endpoints to the Flutter mobile app implementation.

## ✅ Verified Backend Structure

### API Base
- **Base URL:** `https://nathemni.ly/api/v1`
- **Authentication:** Laravel Sanctum (Bearer token)
- **Response Format:**
  ```json
  {
    "success": true/false,
    "message": "...",
    "data": {...},
    "errors": {...}  // validation errors (422)
  }
  ```

---

## 🔐 Authentication Endpoints

| Endpoint | Method | Status | Flutter Implementation |
|----------|--------|--------|----------------------|
| `/register` | POST | ✅ | `AuthService.register()` |
| `/login` | POST | ✅ | `AuthService.login()` |
| `/verify-otp` | POST | ✅ | `AuthService.verifyOtp()` |
| `/request-login-otp` | POST | ✅ | `AuthService.requestLoginOtp()` |
| `/login-with-otp` | POST | ✅ | `AuthService.loginWithOtp()` |
| `/user` | GET | ✅ | `AuthService.getCurrentUser()` |
| `/profile` | PUT | ✅ | `AuthService.updateProfile()` |
| `/change-password` | POST | ✅ | `AuthService.changePassword()` |
| `/logout` | POST | ✅ | `AuthService.logout()` |
| `/logout-all` | POST | ⏳ | Not yet implemented |

### Auth Flow Details

**Register:**
```dart
POST /register
Body: {
  "name": string (required),
  "email": string (required_without: phone),
  "phone": string (required_without: email),
  "password": string (required, min:8),
  "password_confirmation": string (required)
}
Response: { user, otp_sent: true, message }
```

**Login (Password):**
```dart
POST /login
Body: {
  "identifier": string (email or phone),
  "password": string
}
Response: { user, token, token_type: "Bearer" }
```

**Login (OTP):**
```dart
// Step 1: Request OTP
POST /request-login-otp
Body: { "identifier": string }
Response: { otp_sent: true }

// Step 2: Verify and login
POST /login-with-otp
Body: {
  "identifier": string,
  "code": string (6 digits)
}
Response: { user, token, token_type: "Bearer" }
```

---

## ✅ Tasks Module

**Backend Controller:** `TaskController.php`  
**Backend Model:** `Task.php`  
**Flutter Model:** `lib/features/tasks/data/task_model.dart`

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/tasks` | GET | ✅ | List tasks (paginated, with filters) |
| `/tasks` | POST | ✅ | Create new task |
| `/tasks/{id}` | GET | ✅ | Get single task |
| `/tasks/{id}` | PUT | ✅ | Update task |
| `/tasks/{id}` | DELETE | ✅ | Delete task |
| `/tasks/{id}/complete` | POST | ✅ | Mark task as completed |

### Task Model Structure
```dart
{
  "id": int,
  "user_id": int,
  "assigned_to": int?,
  "category_id": int?,
  "title": string,
  "description": string?,
  "priority": "low" | "medium" | "high",
  "status": "pending" | "in_progress" | "completed" | "cancelled",
  "due_date": date?,
  "due_time": "HH:mm"?,
  "completed_at": datetime?,
  "completed_by": int?,
  "is_recurring": boolean,
  "recurrence_pattern": object?,
  "is_shared": boolean,
  "is_synced": boolean,
  "sync_id": string?,
  "category": Category?,
  "assignee": User?,
  "created_at": datetime,
  "updated_at": datetime
}
```

### Task Query Parameters
```dart
GET /tasks?status=pending           // Filter by status
GET /tasks?priority=high            // Filter by priority
GET /tasks?category_id=1            // Filter by category
GET /tasks?due_date=2026-02-03      // Filter by due date
GET /tasks?overdue=true             // Show overdue tasks
GET /tasks?today=true               // Show tasks due today
GET /tasks?per_page=20              // Pagination (default: 15)
```

### Task Relations
- **Loaded by default:** `category`, `assignee`
- Available in detail view: `user`, `completedByUser`

---

## ✅ Expenses Module

**Backend Controller:** `ExpenseController.php`  
**Backend Model:** `Expense.php`  
**Flutter Model:** `lib/features/expenses/data/expense_model.dart`

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/expenses` | GET | ✅ | List expenses (paginated, with filters) |
| `/expenses` | POST | ✅ | Create new expense |
| `/expenses/{id}` | GET | ✅ | Get single expense |
| `/expenses/{id}` | PUT | ✅ | Update expense |
| `/expenses/{id}` | DELETE | ✅ | Delete expense |
| `/expenses/summary` | GET | ✅ | Get expense summary/statistics |

### Expense Model Structure
```dart
{
  "id": int,
  "user_id": int,
  "category_id": int,
  "payment_method_id": int?,
  "amount": decimal(2),
  "currency": string (3 chars, default: "LYD"),
  "description": string?,
  "notes": string?,
  "expense_date": date,
  "is_synced": boolean,
  "sync_id": string?,
  "category": ExpenseCategory,
  "payment_method": PaymentMethod?,
  "created_at": datetime,
  "updated_at": datetime
}
```

### Expense Query Parameters
```dart
GET /expenses?category_id=1           // Filter by category
GET /expenses?payment_method_id=2     // Filter by payment method
GET /expenses?start_date=2026-02-01&end_date=2026-02-28  // Date range
GET /expenses?this_month=true         // Current month only
GET /expenses?per_page=20             // Pagination (default: 15)
```

### Expense Summary
```dart
GET /expenses/summary?start_date=2026-02-01&end_date=2026-02-28
// Or without dates for this month

Response: {
  "total": decimal,
  "by_category": [
    {
      "category_id": int,
      "total": decimal,
      "category": { "id", "name_ar", "name_en" }
    }
  ]
}
```

### Expense Relations
- **Loaded by default:** `category`, `paymentMethod`

---

## ✅ Categories Module

**Backend Controller:** `CategoryController.php`  
**Backend Model:** `Category.php`

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/categories` | GET | ✅ | List categories (system + user's custom) |
| `/categories` | POST | ⏳ | Create custom category |
| `/categories/{id}` | GET | ⏳ | Get single category |
| `/categories/{id}` | PUT | ⏳ | Update custom category |
| `/categories/{id}` | DELETE | ⏳ | Delete custom category |

### Category Model Structure
```dart
{
  "id": int,
  "name_ar": string,
  "name_en": string,
  "type": "expense" | "income" | "task" | "meal" | "project",
  "icon": string?,
  "color": string?,
  "parent_id": int?,
  "is_system": boolean,
  "user_id": int?,
  "is_active": boolean,
  "children": Category[]?,
  "parent": Category?
}
```

### Category Query Parameters
```dart
GET /categories?type=expense    // Filter by type
```

### Category Rules
- System categories cannot be edited/deleted
- Users can only modify their own custom categories
- Categories can have parent-child relationships

---

## 🔄 Other Modules (Out of MVP Scope)

The backend has these additional modules that are **not** in the MVP:

| Module | Endpoints Available | MVP Status |
|--------|-------------------|-----------|
| Payment Methods | CRUD | ⏳ Phase 2 |
| Service Providers | CRUD | ⏳ Phase 2 |
| People (Contacts) | CRUD | ⏳ Phase 2 |
| Checklists | CRUD + items | ⏳ Phase 2 |
| Incomes | CRUD + summary | ⏳ Phase 2 |
| Debts | CRUD + payments | ⏳ Phase 2 |
| Projects | CRUD + payments | ⏳ Phase 2 |
| Vehicles | CRUD + records | ⏳ Phase 2 |
| Meals | CRUD + planning | ⏳ Phase 2 |
| Personal Documents | CRUD | ⏳ Phase 2 |
| SIM Cards | CRUD | ⏳ Phase 2 |
| Scan History | List + Store | ⏳ Phase 2 |
| Support Requests | List + Store | ⏳ Phase 2 |

---

## 🔐 Authorization

All protected endpoints use middleware: `auth:sanctum`

### Token Management (Flutter)
1. Token stored securely in `flutter_secure_storage`
2. Auto-injected via `ApiClient` interceptor
3. Format: `Authorization: Bearer {token}`
4. 401 responses trigger auto token cleanup

### Permission Checks
- **Tasks:** User must own task OR be assigned to it
- **Expenses:** User must own the expense
- **Categories:** Users can only modify their own custom categories (not system categories)

---

## 📝 Response Patterns

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message"
}
```

### Validation Error (422)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "message": "Success",
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  }
}
```

---

## ✅ Flutter Implementation Status

### Completed ✅
- [x] API Client with Sanctum auth
- [x] Base response models (`ApiResponse`, `PaginatedResponse`)
- [x] User model
- [x] Auth service (complete)
- [x] Task model (complete with relations)
- [x] Expense model (complete with relations)
- [x] Category models (simplified for relations)
- [x] Payment method model
- [x] Environment configuration

### To Be Implemented ⏳
- [ ] Task service (API calls)
- [ ] Expense service (API calls)
- [ ] Category service (API calls)
- [ ] State management (Riverpod providers)
- [ ] UI screens
- [ ] Error handling utilities
- [ ] Form validation
- [ ] Localization (AR/EN)

---

## 🎯 Key Observations

1. **Bilingual Support:** All user-facing entities (categories, payment methods) have `name_ar` and `name_en`
2. **Soft Deletes:** Tasks and Expenses use soft deletes (`deleted_at`)
3. **Sync Fields:** Both have `is_synced` and `sync_id` for future offline sync
4. **Relations:** Backend uses eager loading with `.with()` for optimal performance
5. **Filtering:** Rich query parameter support for filtering and searching
6. **Pagination:** Default 15 items per page, customizable via `per_page`
7. **Default Currency:** Backend uses "LYD" (Libyan Dinar) as default
8. **Task Sharing:** Tasks can be assigned to other users (collaborative)

---

## 📚 Next Steps

1. Create Task service for API calls
2. Create Expense service for API calls  
3. Create Category service for API calls
4. Build Riverpod providers for state management
5. Implement UI screens with proper error handling
6. Add form validation
7. Implement localization with proper locale switching
