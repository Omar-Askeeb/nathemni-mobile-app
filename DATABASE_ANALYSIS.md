# Database Analysis - Nathemni Backend

## ✅ Existing Tables (Already in Database)

### Core Tables
1. **users** - User accounts
2. **personal_access_tokens** - Laravel Sanctum tokens
3. **otp_codes** - OTP verification codes
4. **cache** / **jobs** - Laravel system tables

### Data Tables
5. **tasks** ✅
   - Has sync fields: `is_synced`, `sync_id`
   - Supports: assigned_to, category, priority, status, recurring
   
6. **expenses** ✅
   - Has sync fields: `is_synced`, `sync_id`
   - Links to: category, payment_method
   
7. **categories** ✅
   - Bilingual: `name_ar`, `name_en`
   - Types: expense, income, task, meal, project
   - **Missing:** `equipment` type

8. **payment_methods** ✅
9. **people** ✅ (Internal Contacts)
   - Has sync fields: `is_synced`, `sync_id`
   - Types: family, friend, work, other

### Supporting Tables
10. **checklists** + **checklist_items**
11. **incomes** + **debts** + **debt_payments**
12. **projects** + **project_payments**
13. **vehicles** + **vehicle_records**
14. **meals** + **meal_plans**
15. **personal_documents**
16. **sim_cards**
17. **scan_history**
18. **reminders**
19. **activity_logs**
20. **sync_logs** ✅ (For tracking sync operations)
21. **support_requests** + **support_responses** + **admins**
22. **banks** + **cities** (Reference data)
23. **service_providers**
24. **user_partners**

---

## ❌ Missing Tables for Equipment Management

### 1. Equipment Categories Table
**Table:** `equipment_categories`

**Why:** Categories table exists but doesn't have 'equipment' type. Equipment needs dynamic categories managed from admin dashboard (Screwdrivers, Wrenches, etc.)

**Migration:**
```php
Schema::create('equipment_categories', function (Blueprint $table) {
    $table->id();
    $table->string('name_ar');
    $table->string('name_en');
    $table->string('icon')->nullable();
    $table->string('color')->nullable();
    $table->integer('order')->default(0); // Display order
    $table->boolean('is_active')->default(true);
    $table->boolean('is_system')->default(true); // System vs user-created
    $table->foreignId('created_by')->nullable()->constrained('admins')->nullOnDelete();
    $table->timestamps();
    
    $table->index('is_active');
});
```

### 2. Equipment Table
**Table:** `equipment`

**Purpose:** Store equipment inventory

**Migration:**
```php
Schema::create('equipment', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('equipment_category_id')->constrained()->restrictOnDelete();
    $table->string('name');
    $table->text('description')->nullable();
    $table->string('serial_number')->nullable();
    $table->enum('status', [
        'available',
        'borrowed',
        'needs_cleaning',
        'damaged',
        'under_maintenance'
    ])->default('available');
    $table->decimal('rental_price_per_day', 10, 2)->nullable();
    $table->string('currency', 3)->default('LYD');
    $table->boolean('needs_cleaning')->default(false);
    $table->timestamp('last_cleaned_at')->nullable();
    $table->timestamp('next_cleaning_due')->nullable();
    $table->string('image_path')->nullable();
    $table->text('notes')->nullable();
    $table->boolean('is_synced')->default(false);
    $table->uuid('sync_id')->nullable();
    $table->timestamps();
    $table->softDeletes();
    
    $table->index(['user_id', 'status']);
    $table->index(['user_id', 'equipment_category_id']);
});
```

### 3. Equipment Lending Table
**Table:** `equipment_lendings`

**Purpose:** Track equipment lending/borrowing

**Migration:**
```php
Schema::create('equipment_lendings', function (Blueprint $table) {
    $table->id();
    $table->foreignId('equipment_id')->constrained('equipment')->cascadeOnDelete();
    $table->foreignId('lender_id')->constrained('users')->cascadeOnDelete();
    
    // Borrower info (can be registered user or manual entry)
    $table->foreignId('borrower_user_id')->nullable()->constrained('users')->nullOnDelete();
    $table->string('borrower_name')->nullable(); // If not registered
    $table->string('borrower_phone')->nullable();
    $table->string('borrower_email')->nullable();
    
    $table->boolean('borrower_confirmed')->default(false); // In-app confirmation
    $table->timestamp('confirmation_sent_at')->nullable();
    
    $table->date('borrow_date');
    $table->date('expected_return_date');
    $table->date('actual_return_date')->nullable();
    
    $table->decimal('rental_price_per_day', 10, 2)->nullable();
    $table->decimal('total_rental_cost', 10, 2)->nullable();
    $table->string('currency', 3)->default('LYD');
    
    $table->enum('payment_status', ['paid', 'pending', 'partial'])->default('pending');
    $table->foreignId('payment_method_id')->nullable()->constrained()->nullOnDelete();
    
    $table->enum('status', [
        'pending',      // Awaiting borrower confirmation
        'confirmed',    // Borrower confirmed
        'active',       // Equipment is with borrower
        'returned',     // Returned successfully
        'overdue',      // Past expected return date
        'cancelled'
    ])->default('pending');
    
    $table->boolean('is_damaged')->default(false);
    $table->text('damage_report')->nullable();
    $table->string('damage_photo_path')->nullable();
    $table->decimal('repair_cost', 10, 2)->nullable();
    
    $table->text('notes')->nullable();
    $table->boolean('is_synced')->default(false);
    $table->uuid('sync_id')->nullable();
    $table->timestamps();
    $table->softDeletes();
    
    $table->index(['lender_id', 'status']);
    $table->index(['borrower_user_id', 'status']);
    $table->index(['equipment_id', 'status']);
    $table->index(['borrow_date', 'expected_return_date']);
});
```

### 4. Equipment Cleaning Tasks Table
**Table:** `equipment_cleaning_tasks`

**Purpose:** Schedule and track equipment cleaning

**Migration:**
```php
Schema::create('equipment_cleaning_tasks', function (Blueprint $table) {
    $table->id();
    $table->foreignId('equipment_id')->constrained('equipment')->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('task_id')->nullable()->constrained('tasks')->nullOnDelete(); // Link to main tasks table
    $table->date('scheduled_date');
    $table->timestamp('completed_at')->nullable();
    $table->foreignId('completed_by')->nullable()->constrained('users')->nullOnDelete();
    $table->boolean('is_completed')->default(false);
    $table->text('notes')->nullable();
    $table->boolean('is_recurring')->default(false);
    $table->json('recurrence_pattern')->nullable(); // daily, weekly, monthly
    $table->boolean('is_synced')->default(false);
    $table->uuid('sync_id')->nullable();
    $table->timestamps();
    
    $table->index(['equipment_id', 'is_completed']);
    $table->index(['user_id', 'scheduled_date']);
});
```

### 5. Commitments Table (for Contacts Module)
**Table:** `commitments`

**Purpose:** Track obligations between user and contacts

**Migration:**
```php
Schema::create('commitments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('person_id')->constrained('people')->cascadeOnDelete(); // From people table
    $table->string('title');
    $table->text('description')->nullable();
    $table->enum('type', ['i_owe', 'they_owe']); // Direction of obligation
    $table->date('due_date')->nullable();
    $table->enum('status', ['pending', 'fulfilled', 'cancelled'])->default('pending');
    
    // Optional financial tracking
    $table->decimal('amount', 10, 2)->nullable();
    $table->string('currency', 3)->default('LYD');
    
    $table->timestamp('fulfilled_at')->nullable();
    $table->text('fulfillment_notes')->nullable();
    
    $table->boolean('is_synced')->default(false);
    $table->uuid('sync_id')->nullable();
    $table->timestamps();
    $table->softDeletes();
    
    $table->index(['user_id', 'status']);
    $table->index(['person_id', 'status']);
    $table->index(['user_id', 'due_date']);
});
```

---

## 🔄 Required Updates to Existing Tables

### 1. Update `people` table
**Add columns for Nathemni account linking:**

```php
Schema::table('people', function (Blueprint $table) {
    $table->foreignId('linked_user_id')->nullable()
          ->after('email')
          ->constrained('users')
          ->nullOnDelete();
    
    $table->boolean('has_nathemni_account')->default(false)
          ->after('linked_user_id');
    
    $table->enum('connection_status', [
        'none',           // No account or not connected
        'pending',        // Connection request sent
        'connected',      // Connection accepted
        'declined'        // Connection declined
    ])->default('none')->after('has_nathemni_account');
    
    $table->string('avatar')->nullable()->after('email');
});
```

### 2. Update `categories` table
**Add 'equipment' type to enum:**

```php
Schema::table('categories', function (Blueprint $table) {
    // Modify enum to include 'equipment'
    $table->enum('type', ['expense', 'income', 'task', 'meal', 'project', 'equipment'])
          ->change();
});
```

**Note:** In MySQL, changing enum requires dropping and recreating. Better approach:

```php
// Add new migration
Schema::table('categories', function (Blueprint $table) {
    $table->dropColumn('type');
});

Schema::table('categories', function (Blueprint $table) {
    $table->enum('type', [
        'expense', 
        'income', 
        'task', 
        'meal', 
        'project', 
        'equipment',          // NEW
        'equipment_cleaning'   // NEW (for cleaning tasks)
    ])->default('expense')->after('name_en');
});
```

### 3. Update `expenses` table
**Add linking to tasks, equipment, and contacts:**

```php
Schema::table('expenses', function (Blueprint $table) {
    $table->enum('linked_to', ['none', 'task', 'equipment', 'contact', 'project'])
          ->default('none')
          ->after('expense_date');
    
    $table->unsignedBigInteger('linked_id')->nullable()
          ->after('linked_to');
    
    // No foreign key because it can link to different tables
    $table->index(['user_id', 'linked_to', 'linked_id']);
});
```

### 4. Update `support_requests` table
**Add attachment for screenshots:**

```php
Schema::table('support_requests', function (Blueprint $table) {
    $table->json('attachments')->nullable()
          ->after('description');
    // Store array of attachment paths
});
```

---

## 📊 Backend Controllers & Models Needed

### New Controllers to Create

1. **EquipmentCategoryController** (Admin only)
   - CRUD for equipment categories
   - Location: `app/Http/Controllers/Admin/EquipmentCategoryController.php`

2. **EquipmentController**
   - CRUD for equipment
   - Get equipment by category
   - Update equipment status
   - Location: `app/Http/Controllers/Api/V1/EquipmentController.php`

3. **EquipmentLendingController**
   - Create lending record
   - Confirm borrowing (for borrower)
   - Return equipment
   - Get lending history
   - Calculate rental costs
   - Location: `app/Http/Controllers/Api/V1/EquipmentLendingController.php`

4. **EquipmentCleaningController**
   - Schedule cleaning
   - Mark as cleaned
   - Get cleaning schedule
   - Location: `app/Http/Controllers/Api/V1/EquipmentCleaningController.php`

5. **CommitmentController**
   - CRUD for commitments
   - Mark as fulfilled
   - Get commitments by person
   - Location: `app/Http/Controllers/Api/V1/CommitmentController.php`

### New Models to Create

1. `app/Models/EquipmentCategory.php`
2. `app/Models/Equipment.php`
3. `app/Models/EquipmentLending.php`
4. `app/Models/EquipmentCleaningTask.php`
5. `app/Models/Commitment.php`

### Update Existing Models

1. **Person.php**
   - Add `linkedUser()` relationship
   - Add `commitments()` relationship

2. **Expense.php**
   - Add polymorphic relationship for `linked_to`

3. **Category.php**
   - Add `equipment` type handling

---

## 🗄️ Migration Files to Create

Create these migrations in `backend/database/migrations/`:

1. `2026_02_04_100000_create_equipment_categories_table.php`
2. `2026_02_04_100001_create_equipment_table.php`
3. `2026_02_04_100002_create_equipment_lendings_table.php`
4. `2026_02_04_100003_create_equipment_cleaning_tasks_table.php`
5. `2026_02_04_100004_create_commitments_table.php`
6. `2026_02_04_100005_update_people_table_add_account_linking.php`
7. `2026_02_04_100006_update_categories_table_add_equipment_type.php`
8. `2026_02_04_100007_update_expenses_table_add_linking.php`
9. `2026_02_04_100008_update_support_requests_add_attachments.php`

---

## 🔑 API Routes to Add

Add to `routes/api.php`:

```php
// Equipment Management
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    
    // Equipment Categories (read-only for users, managed by admin)
    Route::get('equipment-categories', [EquipmentCategoryController::class, 'index']);
    Route::get('equipment-categories/{id}', [EquipmentCategoryController::class, 'show']);
    
    // Equipment CRUD
    Route::apiResource('equipment', EquipmentController::class);
    Route::get('equipment-by-category/{categoryId}', [EquipmentController::class, 'byCategory']);
    Route::post('equipment/{id}/update-status', [EquipmentController::class, 'updateStatus']);
    
    // Equipment Lending
    Route::post('equipment/{id}/lend', [EquipmentLendingController::class, 'lendEquipment']);
    Route::post('equipment-lendings/{id}/confirm', [EquipmentLendingController::class, 'confirmBorrowing']);
    Route::post('equipment-lendings/{id}/return', [EquipmentLendingController::class, 'returnEquipment']);
    Route::get('equipment-lendings/active', [EquipmentLendingController::class, 'activeLendings']);
    Route::get('equipment-lendings/history', [EquipmentLendingController::class, 'lendingHistory']);
    Route::get('equipment/{id}/lending-history', [EquipmentLendingController::class, 'equipmentHistory']);
    
    // Equipment Cleaning
    Route::post('equipment/{id}/schedule-cleaning', [EquipmentCleaningController::class, 'scheduleCleaning']);
    Route::post('equipment-cleaning/{id}/complete', [EquipmentCleaningController::class, 'markAsCompleted']);
    Route::get('equipment-cleaning/due', [EquipmentCleaningController::class, 'dueCleaning']);
    
    // Commitments
    Route::apiResource('commitments', CommitmentController::class);
    Route::post('commitments/{id}/fulfill', [CommitmentController::class, 'markAsFulfilled']);
    Route::get('people/{personId}/commitments', [CommitmentController::class, 'byPerson']);
});

// Admin routes for equipment categories
Route::prefix('admin')->middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::apiResource('equipment-categories', Admin\EquipmentCategoryController::class);
});
```

---

## 📋 Summary

### What Exists ✅
- Tasks with sync support
- Expenses with sync support  
- Categories (needs equipment type added)
- People (contacts) - needs linking fields
- Sync logs infrastructure
- Support requests system
- Payment methods

### What's Missing ❌
- Equipment categories table
- Equipment table
- Equipment lending table
- Equipment cleaning tasks table
- Commitments table
- Updates to existing tables (people, categories, expenses)

### Next Steps

1. **Create migration files** for new tables
2. **Run migrations** on local database
3. **Create models** with relationships
4. **Create controllers** with API endpoints
5. **Update mobile app** models to match
6. **Test API endpoints** before building mobile UI

---

## 🚀 Quick Start Commands

```bash
# Navigate to backend
cd ../backend

# Create migrations
php artisan make:migration create_equipment_categories_table
php artisan make:migration create_equipment_table
php artisan make:migration create_equipment_lendings_table
php artisan make:migration create_equipment_cleaning_tasks_table
php artisan make:migration create_commitments_table

# Create models
php artisan make:model EquipmentCategory
php artisan make:model Equipment
php artisan make:model EquipmentLending
php artisan make:model EquipmentCleaningTask
php artisan make:model Commitment

# Create controllers
php artisan make:controller Api/V1/EquipmentController --resource
php artisan make:controller Api/V1/EquipmentLendingController
php artisan make:controller Api/V1/EquipmentCleaningController
php artisan make:controller Api/V1/CommitmentController --resource

# Run migrations
php artisan migrate
```
