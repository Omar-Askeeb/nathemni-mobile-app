import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Helper
/// Manages local database for offline functionality
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nathemni.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 7, // Incremented for debt_payments table
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Verify and fix schema after opening
    await _verifyAndFixSchema(db);

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
  }

  Future<void> _createDB(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create all tables
    await _createUsersTable(db);
    await _createCategoriesTable(db);
    await _createTasksTable(db);
    await _createExpensesTable(db);
    await _createPeopleTable(db);
    await _createCommitmentsTable(db);
    await _createDebtPaymentsTable(db);
    await _createEquipmentCategoriesTable(db);
    await _createEquipmentTable(db);
    await _createEquipmentLendingsTable(db);
    await _createEquipmentCleaningTasksTable(db);
    await _createPaymentMethodsTable(db);
    await _createSimCardsTable(db);
    await _createBankAccountsTable(db);
    await _createSyncQueueTable(db);
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
        email TEXT,
        phone TEXT,
        avatar TEXT,
        language TEXT DEFAULT 'ar',
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(server_id)
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
        category_id INTEGER NOT NULL,
        payment_method_id INTEGER,
        payment_method TEXT DEFAULT 'cash',
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
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE SET NULL
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

  Future<void> _createEquipmentCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE equipment_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        display_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_system INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'synced',
        UNIQUE(server_id)
      )
    ''');
  }

  Future<void> _createEquipmentTable(Database db) async {
    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        user_id INTEGER NOT NULL,
        equipment_category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        serial_number TEXT,
        status TEXT DEFAULT 'available',
        rental_price_per_day REAL,
        currency TEXT DEFAULT 'LYD',
        needs_cleaning INTEGER DEFAULT 0,
        last_cleaned_at TEXT,
        next_cleaning_due TEXT,
        image_path TEXT,
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
        FOREIGN KEY (equipment_category_id) REFERENCES equipment_categories(id) ON DELETE RESTRICT
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_equipment_user_status ON equipment(user_id, status)');
    await db.execute(
        'CREATE INDEX idx_equipment_category ON equipment(equipment_category_id)');
  }

  Future<void> _createEquipmentLendingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE equipment_lendings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        equipment_id INTEGER NOT NULL,
        lender_id INTEGER NOT NULL,
        borrower_user_id INTEGER,
        borrower_name TEXT,
        borrower_phone TEXT,
        borrower_email TEXT,
        borrower_confirmed INTEGER DEFAULT 0,
        confirmation_sent_at TEXT,
        borrow_date TEXT NOT NULL,
        expected_return_date TEXT NOT NULL,
        actual_return_date TEXT,
        rental_price_per_day REAL,
        total_rental_cost REAL,
        currency TEXT DEFAULT 'LYD',
        payment_status TEXT DEFAULT 'pending',
        payment_method_id INTEGER,
        status TEXT DEFAULT 'pending',
        is_damaged INTEGER DEFAULT 0,
        damage_report TEXT,
        damage_photo_path TEXT,
        repair_cost REAL,
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
        FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
        FOREIGN KEY (lender_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (borrower_user_id) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_lendings_lender ON equipment_lendings(lender_id, status)');
    await db.execute(
        'CREATE INDEX idx_lendings_borrower ON equipment_lendings(borrower_user_id, status)');
    await db.execute(
        'CREATE INDEX idx_lendings_equipment ON equipment_lendings(equipment_id, status)');
  }

  Future<void> _createEquipmentCleaningTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE equipment_cleaning_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        equipment_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        task_id INTEGER,
        scheduled_date TEXT NOT NULL,
        completed_at TEXT,
        completed_by INTEGER,
        is_completed INTEGER DEFAULT 0,
        notes TEXT,
        is_recurring INTEGER DEFAULT 0,
        recurrence_pattern TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_id TEXT,
        created_offline INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_modified TEXT,
        UNIQUE(server_id),
        FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
        FOREIGN KEY (completed_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_cleaning_equipment ON equipment_cleaning_tasks(equipment_id, is_completed)');
    await db.execute(
        'CREATE INDEX idx_cleaning_scheduled ON equipment_cleaning_tasks(user_id, scheduled_date)');
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

  // ========================================
  // DATABASE OPERATIONS
  // ========================================

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('equipment_cleaning_tasks');
    await db.delete('equipment_lendings');
    await db.delete('equipment');
    await db.delete('equipment_categories');
    await db.delete('commitments');
    await db.delete('people');
    await db.delete('expenses');
    await db.delete('tasks');
    await db.delete('sim_cards');
    await db.delete('bank_accounts');
    await db.delete('categories');
    await db.delete('payment_methods');
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
