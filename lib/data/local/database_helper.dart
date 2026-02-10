import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Helper
/// Manages local database for offline functionality
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _databaseFuture;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Use a future variable to ensure initialization only happens once
    // even if multiple calls arrive simultaneously
    _databaseFuture ??= _initDB('nathemni.db');
    _database = await _databaseFuture;
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('Opening database at: $path');

    final db = await openDatabase(
      path,
      version: 16,
      onConfigure: (db) async {
        debugPrint('Configuring database (enabling foreign keys)...');
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        debugPrint('Creating database version $version...');
        await _createDB(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('Upgrading database from $oldVersion to $newVersion...');
        await _upgradeDB(db, oldVersion, newVersion);
      },
    );

    debugPrint('Database opened. Verifying schema...');
    await _verifyAndFixSchema(db);
    debugPrint('Database schema verification complete.');

    return db;
  }

  /// Verify critical columns exist and add them if missing
  Future<void> _verifyAndFixSchema(Database db) async {
    // Check if payment_method column exists in expenses table
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(expenses)');
      final hasPaymentMethod = tableInfo.any((col) => col['name'] == 'payment_method');
      if (!hasPaymentMethod) {
        await db.execute('ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT "cash"');
      }
    } catch (e) {
      // Silently ignore if table doesn't exist yet
    }

    // Ensure a default user exists for the hardcoded ID 1
    try {
      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (users.isEmpty) {
        await db.insert('users', {
          'id': 1,
          'name': 'User',
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Inserted default user with ID 1.');
      }
    } catch (e) {
      debugPrint('Default user check warning: $e');
    }

    // Verify and fix tools tables schema
    await _verifyToolsSchema(db);
  }

  Future<void> _verifyToolsSchema(Database db) async {
    try {
      // Check tool_categories columns
      final catInfo = await db.rawQuery('PRAGMA table_info(tool_categories)');
      if (catInfo.isNotEmpty) {
        final hasSortOrder = catInfo.any((col) => col['name'] == 'sort_order');
        if (!hasSortOrder) {
          await db.execute('ALTER TABLE tool_categories ADD COLUMN sort_order INTEGER DEFAULT 0');
          debugPrint('Added sort_order column to tool_categories');
        }
      }

      // Check tools table columns
      final toolsInfo = await db.rawQuery('PRAGMA table_info(tools)');
      if (toolsInfo.isNotEmpty) {
        final hasNotes = toolsInfo.any((col) => col['name'] == 'notes');
        if (!hasNotes) {
          await db.execute('ALTER TABLE tools ADD COLUMN notes TEXT');
          debugPrint('Added notes column to tools table');
        }
        
        final hasCost = toolsInfo.any((col) => col['name'] == 'cost');
        if (!hasCost) {
          await db.execute('ALTER TABLE tools ADD COLUMN cost REAL DEFAULT 0');
          debugPrint('Added cost column to tools table');
        }

        final hasDailyPrice = toolsInfo.any((col) => col['name'] == 'daily_price');
        if (!hasDailyPrice) {
          await db.execute('ALTER TABLE tools ADD COLUMN daily_price REAL DEFAULT 0');
          debugPrint('Added daily_price column to tools table');
        }
      }

      // Check tool_extensions columns
      final extInfo = await db.rawQuery('PRAGMA table_info(tool_extensions)');
      if (extInfo.isNotEmpty) {
        final hasCost = extInfo.any((col) => col['name'] == 'cost');
        if (!hasCost) {
          await db.execute('ALTER TABLE tool_extensions ADD COLUMN cost REAL DEFAULT 0');
          debugPrint('Added cost column to tool_extensions');
        }
        // Always ensure cost has values (migration fix)
        await db.execute('UPDATE tool_extensions SET cost = COALESCE(daily_price, 0) WHERE cost IS NULL');
      }

      // Check tool_transactions columns
      final transInfo = await db.rawQuery('PRAGMA table_info(tool_transactions)');
      if (transInfo.isNotEmpty) {
        final hasIsPaid = transInfo.any((col) => col['name'] == 'is_paid');
        if (!hasIsPaid) {
          try {
            await db.execute('ALTER TABLE tool_transactions ADD COLUMN is_paid INTEGER DEFAULT 0');
            debugPrint('Added is_paid column to tool_transactions');
          } catch (_) {}
        }

        final hasStartDate = transInfo.any((col) => col['name'] == 'start_date');
        if (!hasStartDate) {
          // Table exists but missing critical columns - recreate it
          debugPrint('tool_transactions missing columns, recreating...');
          await db.execute('DROP TABLE IF EXISTS transaction_extensions');
          await db.execute('DROP TABLE IF EXISTS tool_transactions');
          
          // Recreate tables
          await db.execute('''
            CREATE TABLE tool_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              tool_id INTEGER NOT NULL,
              person_id INTEGER NOT NULL,
              transaction_type TEXT NOT NULL,
              start_date TEXT NOT NULL,
              due_date TEXT NOT NULL,
              return_date TEXT,
              daily_price REAL DEFAULT 0,
              extensions_price REAL DEFAULT 0,
              total_days INTEGER DEFAULT 0,
              subtotal REAL DEFAULT 0,
              late_fee REAL DEFAULT 0,
              total_amount REAL DEFAULT 0,
              status TEXT DEFAULT 'active',
              notes TEXT,
              created_at TEXT,
              updated_at TEXT,
              sync_status TEXT DEFAULT 'pending',
              is_paid INTEGER DEFAULT 0,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY (tool_id) REFERENCES tools(id) ON DELETE RESTRICT,
              FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE transaction_extensions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL,
              extension_id INTEGER NOT NULL,
              daily_price REAL DEFAULT 0,
              FOREIGN KEY (transaction_id) REFERENCES tool_transactions(id) ON DELETE CASCADE,
              FOREIGN KEY (extension_id) REFERENCES tool_extensions(id) ON DELETE RESTRICT
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_user ON tool_transactions(user_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_tool ON tool_transactions(tool_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_person ON tool_transactions(person_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_status ON tool_transactions(status)');
        }
      }
    } catch (e) {
      debugPrint('Tools schema verification warning: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create all tables
    await _createUsersTable(db);
    await _createCategoriesTable(db);
    await _createTasksTable(db);
    await _createExpensesTable(db);
    await _createPeopleTable(db);
    await _createCommitmentsTable(db);
    await _createDebtPaymentsTable(db);
    await _createPaymentMethodsTable(db);
    await _createSimCardsTable(db);
    await _createBankAccountsTable(db);
    await _createSyncQueueTable(db);
    await _createMealsTable(db);
    await _createMealLogsTable(db);
    await _createCarManagementTables(db);
    await _createToolsTables(db);
    await _createIncomeTable(db);
    await _createNotificationsTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add task_type column for version 2
      await db.execute('ALTER TABLE tasks ADD COLUMN task_type TEXT');
    }
    if (oldVersion < 3) {
      // Add sim_cards table for version 3
      await _createSimCardsTable(db);
    }
    if (oldVersion < 4) {
      // Add bank_accounts table for version 4
      await _createBankAccountsTable(db);
    }
    if (oldVersion < 5) {
      // Add expense_category column for version 5
      await db.execute('ALTER TABLE tasks ADD COLUMN expense_category TEXT');
    }
    if (oldVersion < 6) {
      // Add payment_method column for version 6
      // First check if column already exists to avoid errors
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(expenses)');
        final hasPaymentMethod = tableInfo.any((col) => col['name'] == 'payment_method');
        if (!hasPaymentMethod) {
          await db.execute('ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT "cash"');
        }
      } catch (e) {
        // If table doesn't exist or other error, try adding column anyway
        try {
          await db.execute('ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT "cash"');
        } catch (_) {
          // Column might already exist, ignore
        }
      }
    }
    if (oldVersion < 7) {
      // Add debt_payments table for version 7
      await _createDebtPaymentsTable(db);
    }
    if (oldVersion < 8) {
      // Add meals & meal_logs tables for version 8
      await _createMealsTable(db);
      await _createMealLogsTable(db);
    }
    if (oldVersion < 9) {
      // Add car management tables for version 9
      await _createCarManagementTables(db);
    }
    if (oldVersion < 10) {
      // Add income and notifications tables for version 10
      await _createIncomeTable(db);
      await _createNotificationsTable(db);
    }
    if (oldVersion < 11) {
      // Add tools management tables for version 11
      await _createToolsTables(db);
    }
    if (oldVersion < 12) {
      // Add cost and daily_price columns to tools table for version 12
      try {
        await db.execute('ALTER TABLE tools ADD COLUMN cost REAL DEFAULT 0');
        await db.execute('ALTER TABLE tools ADD COLUMN daily_price REAL DEFAULT 0');
        await db.execute('ALTER TABLE tools ADD COLUMN notes TEXT');
      } catch (_) {}
      
      // Add is_paid column to tool_transactions table
      try {
        await db.execute('ALTER TABLE tool_transactions ADD COLUMN is_paid INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      // Rename daily_price to cost in tool_extensions table for version 13
      try {
        await db.execute('ALTER TABLE tool_extensions ADD COLUMN cost REAL DEFAULT 0');
        await db.execute('UPDATE tool_extensions SET cost = COALESCE(daily_price, 0) WHERE cost IS NULL');
      } catch (_) {}
    }
    if (oldVersion < 14) {
      // Add payment_method and bank_account_id to income table
      try {
        await db.execute('ALTER TABLE income ADD COLUMN payment_method TEXT DEFAULT "cash"');
        await db.execute('ALTER TABLE income ADD COLUMN bank_account_id INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 15) {
      // Fix expenses table schema: category_id should be TEXT and remove foreign key constraint
      // Also add payment_method and bank_account_id for consistency
      try {
        await db.transaction((txn) async {
          // 1. Rename existing table
          await txn.execute('ALTER TABLE expenses RENAME TO expenses_old');

          // 2. Create new table with corrected schema
          await txn.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              server_id INTEGER,
              user_id INTEGER NOT NULL,
              category_id TEXT NOT NULL,
              payment_method_id INTEGER,
              payment_method TEXT DEFAULT 'cash',
              bank_account_id INTEGER,
              amount REAL NOT NULL,
              currency TEXT DEFAULT 'LYD',
              description TEXT,
              notes TEXT,
              expense_date TEXT NOT NULL,
              linked_to TEXT DEFAULT 'none',
              linked_id INTEGER,
              is_synced INTEGER DEFAULT 0,
              sync_id TEXT,
              created_offline INTEGER DEFAULT 0,
              created_at TEXT,
              updated_at TEXT,
              deleted_at TEXT,
              sync_status TEXT DEFAULT 'pending',
              last_modified TEXT,
              UNIQUE(server_id),
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
            )
          ''');

          // 3. Copy data from old table
          // Note: we cast ID to string if it was numeric, but since we use slugs now, 
          // we hope the existing data is either empty or already contains compatible values.
          await txn.execute('''
            INSERT INTO expenses (
              id, server_id, user_id, category_id, payment_method, amount, 
              currency, description, notes, expense_date, linked_to, linked_id,
              is_synced, sync_id, created_offline, created_at, updated_at, 
              deleted_at, sync_status, last_modified
            )
            SELECT 
              id, server_id, user_id, CAST(category_id AS TEXT), payment_method, amount,
              currency, description, notes, expense_date, linked_to, linked_id,
              is_synced, sync_id, created_offline, created_at, updated_at, 
              deleted_at, sync_status, last_modified
            FROM expenses_old
          ''');

          // 4. Drop old table
          await txn.execute('DROP TABLE expenses_old');
          
          // 5. Re-create indexes
          await txn.execute('CREATE INDEX idx_expenses_user_date ON expenses(user_id, expense_date)');
          await txn.execute('CREATE INDEX idx_expenses_user_category ON expenses(user_id, category_id)');
          await txn.execute('CREATE INDEX idx_expenses_sync ON expenses(sync_status)');
          await txn.execute('CREATE INDEX idx_expenses_link ON expenses(user_id, linked_to, linked_id)');
        });
      } catch (e) {
        debugPrint('Migration to v15 failed: $e');
      }
    }
    if (oldVersion < 16) {
      // Add new user fields for user management
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
        final columns = tableInfo.map((col) => col['name'] as String).toSet();
        
        if (!columns.contains('name_ar')) {
          await db.execute('ALTER TABLE users ADD COLUMN name_ar TEXT');
        }
        if (!columns.contains('name_en')) {
          await db.execute('ALTER TABLE users ADD COLUMN name_en TEXT');
        }
        if (!columns.contains('username')) {
          await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
        }
        if (!columns.contains('profile_image')) {
          await db.execute('ALTER TABLE users ADD COLUMN profile_image TEXT');
        }
        if (!columns.contains('password_hash')) {
          await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT');
        }
        if (!columns.contains('email_verified_at')) {
          await db.execute('ALTER TABLE users ADD COLUMN email_verified_at TEXT');
        }
        if (!columns.contains('phone_verified_at')) {
          await db.execute('ALTER TABLE users ADD COLUMN phone_verified_at TEXT');
        }
        debugPrint('Migration to v16 completed: Added user management fields');
      } catch (e) {
        debugPrint('Migration to v16 failed: $e');
      }
    }
  }

  // ========================================
  // TABLE CREATION METHODS
  // ========================================

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        name_ar TEXT,
        name_en TEXT,
        username TEXT,
        email TEXT,
        phone TEXT,
        profile_image TEXT,
        password_hash TEXT,
        language TEXT DEFAULT 'ar',
        is_active INTEGER DEFAULT 1,
        email_verified_at TEXT,
        phone_verified_at TEXT,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(server_id),
        UNIQUE(username),
        UNIQUE(email),
        UNIQUE(phone)
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        parent_id INTEGER,
        is_system INTEGER DEFAULT 1,
        user_id INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'synced',
        UNIQUE(server_id)
      )
    ''');

    // Create index
    await db.execute(
        'CREATE INDEX idx_categories_type ON categories(type, is_active)');
  }

  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        assigned_to INTEGER,
        category_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        task_type TEXT,
        expense_category TEXT,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        due_date TEXT,
        due_time TEXT,
        completed_at TEXT,
        completed_by INTEGER,
        is_recurring INTEGER DEFAULT 0,
        recurrence_pattern TEXT,
        is_shared INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (completed_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db
        .execute('CREATE INDEX idx_tasks_user_status ON tasks(user_id, status)');
    await db.execute(
        'CREATE INDEX idx_tasks_user_due ON tasks(user_id, due_date)');
    await db.execute('CREATE INDEX idx_tasks_sync ON tasks(sync_status)');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        payment_method_id INTEGER,
        payment_method TEXT DEFAULT 'cash',
        bank_account_id INTEGER,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'LYD',
        description TEXT,
        notes TEXT,
        expense_date TEXT NOT NULL,
        linked_to TEXT DEFAULT 'none',
        linked_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_expenses_user_date ON expenses(user_id, expense_date)');
    await db.execute(
        'CREATE INDEX idx_expenses_user_category ON expenses(user_id, category_id)');
    await db.execute('CREATE INDEX idx_expenses_sync ON expenses(sync_status)');
    await db.execute(
        'CREATE INDEX idx_expenses_link ON expenses(user_id, linked_to, linked_id)');
  }

  Future<void> _createPeopleTable(Database db) async {
    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        avatar TEXT,
        type TEXT DEFAULT 'other',
        notes TEXT,
        has_nathemni_account INTEGER DEFAULT 0,
        linked_user_id INTEGER,
        connection_status TEXT DEFAULT 'none',
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (linked_user_id) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create index
    await db
        .execute('CREATE INDEX idx_people_user_type ON people(user_id, type)');
  }

  Future<void> _createCommitmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE commitments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        due_date TEXT,
        status TEXT DEFAULT 'pending',
        amount REAL,
        currency TEXT DEFAULT 'LYD',
        fulfilled_at TEXT,
        fulfillment_notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_commitments_user ON commitments(user_id, status)');
    await db.execute(
        'CREATE INDEX idx_commitments_person ON commitments(person_id, status)');
  }

  Future<void> _createDebtPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commitment_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'LYD',
        payment_date TEXT NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (commitment_id) REFERENCES commitments(id) ON DELETE CASCADE
      )
    ''');

    // Create index
    await db.execute(
        'CREATE INDEX idx_debt_payments_commitment ON debt_payments(commitment_id)');
  }

  Future<void> _createPaymentMethodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        type TEXT,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'synced',
        UNIQUE(server_id)
      )
    ''');
  }

  Future<void> _createSimCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE sim_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        sim_number TEXT NOT NULL,
        provider TEXT NOT NULL,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        UNIQUE(user_id, sim_number, provider),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_sim_cards_user_provider ON sim_cards(user_id, provider)');
    await db.execute('CREATE INDEX idx_sim_cards_sync ON sim_cards(sync_status)');
  }

  Future<void> _createBankAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE bank_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        bank_id TEXT NOT NULL,
        branch TEXT,
        account_number TEXT NOT NULL,
        iban TEXT,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        UNIQUE(user_id, bank_id, account_number),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id)');
    await db.execute('CREATE INDEX idx_bank_accounts_sync ON bank_accounts(sync_status)');
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        server_id INTEGER,
        data TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        attempts INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(operation_type, entity_type, entity_id)
      )
    ''');

    // Create index
    await db.execute(
        'CREATE INDEX idx_sync_queue_status ON sync_queue(status, created_at)');
  }

  Future<void> _createMealsTable(Database db) async {
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        categories TEXT, -- JSON or comma-separated
        image_path TEXT,
        ingredients TEXT, -- JSON
        recipe_steps TEXT, -- JSON
        rating REAL,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_meals_user ON meals(user_id)');
  }

  Future<void> _createMealLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE meal_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        meal_id INTEGER NOT NULL,
        meal_type TEXT NOT NULL, -- breakfast, lunch, dinner, snack
        eaten_at TEXT NOT NULL,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_meal_logs_user_date ON meal_logs(user_id, eaten_at)');
    await db.execute(
        'CREATE INDEX idx_meal_logs_meal ON meal_logs(meal_id)');
  }

  Future<void> _createCarManagementTables(Database db) async {
    // Cars table
    await db.execute('''
      CREATE TABLE cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        model TEXT,
        year INTEGER,
        plate_number TEXT,
        current_odometer REAL,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_cars_user ON cars(user_id)');

    // Car oil changes table
    await db.execute('''
      CREATE TABLE car_oil_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        car_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        change_date TEXT NOT NULL,
        odometer REAL NOT NULL,
        cost REAL NOT NULL,
        currency TEXT DEFAULT 'LYD',
        oil_type TEXT,
        oil_viscosity TEXT,
        filter_changed INTEGER DEFAULT 0,
        expected_distance REAL,
        next_change_odometer REAL,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_oil_changes_car ON car_oil_changes(car_id, change_date)');

    // Car documents table (insurance, tax, inspection)
    await db.execute('''
      CREATE TABLE car_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        car_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        document_type TEXT NOT NULL,
        renewal_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        cost REAL NOT NULL,
        currency TEXT DEFAULT 'LYD',
        place_name TEXT,
        place_contact TEXT,
        payment_method TEXT DEFAULT 'cash',
        notification_id INTEGER,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_car_documents_car ON car_documents(car_id, document_type)');
    await db.execute(
        'CREATE INDEX idx_car_documents_expiry ON car_documents(user_id, expiry_date)');
  }

  Future<void> _createToolsTables(Database db) async {
    // Tool categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tool_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tools table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        cost REAL DEFAULT 0,
        daily_price REAL DEFAULT 0,
        status TEXT DEFAULT 'available',
        image_path TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES tool_categories(id) ON DELETE RESTRICT
      )
    ''');
    
    // Tool extensions/attachments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tool_extensions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        cost REAL DEFAULT 0,
        status TEXT DEFAULT 'available',
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (tool_id) REFERENCES tools(id) ON DELETE CASCADE
      )
    ''');

    // Tool transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tool_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tool_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        return_date TEXT,
        daily_price REAL DEFAULT 0,
        extensions_price REAL DEFAULT 0,
        total_days INTEGER DEFAULT 0,
        subtotal REAL DEFAULT 0,
        late_fee REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        is_paid INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (tool_id) REFERENCES tools(id) ON DELETE RESTRICT,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT
      )
    ''');

    // Transaction extensions junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_extensions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        extension_id INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES tool_transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (extension_id) REFERENCES tool_extensions(id) ON DELETE RESTRICT
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tools_user ON tools(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_extensions_tool ON tool_extensions(tool_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_user ON tool_transactions(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_tool ON tool_transactions(tool_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_person ON tool_transactions(person_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tool_transactions_status ON tool_transactions(status)');
  }

  Future<void> _createIncomeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        source_type TEXT NOT NULL, -- tool_rental, salary, business, etc.
        source_id INTEGER,
        payment_method TEXT DEFAULT 'cash',
        bank_account_id INTEGER,
        entry_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_income_user ON income(user_id, entry_date)');
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL, -- tool_due, doc_expiry, etc.
        related_type TEXT, -- tools, car_documents, etc.
        related_id INTEGER,
        scheduled_at TEXT,
        sent_at TEXT,
        read_at TEXT,
        created_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, read_at)');
  }

  // ========================================
  // DATABASE OPERATIONS
  // ========================================

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('car_documents');
    await db.delete('car_oil_changes');
    await db.delete('cars');
    await db.delete('meal_logs');
    await db.delete('meals');
    await db.delete('debt_payments');
    await db.delete('commitments');
    await db.delete('people');
    await db.delete('expenses');
    await db.delete('tasks');
    await db.delete('sim_cards');
    await db.delete('bank_accounts');
    await db.delete('categories');
    await db.delete('payment_methods');
    await db.delete('notifications');
    await db.delete('income');
    await db.delete('transaction_extensions');
    await db.delete('tool_transactions');
    await db.delete('tool_extensions');
    await db.delete('tools');
    await db.delete('tool_categories');
    await db.delete('users');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nathemni.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
