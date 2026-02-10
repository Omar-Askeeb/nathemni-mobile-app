import '../../../data/local/database_helper.dart';
import '../../../core/services/notification_service.dart';
import 'tool_category_model.dart';
import 'tool_model.dart';
import 'tool_extension_model.dart';
import 'tool_transaction_model.dart';

class ToolsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CATEGORIES
  // ========================================

  Future<List<ToolCategoryModel>> getCategories(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tool_categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC',
    );

    if (maps.isEmpty) {
      await seedDefaultCategories(userId);
      return getCategories(userId);
    }

    return maps.map((m) => ToolCategoryModel.fromMap(m)).toList();
  }

  Future<void> seedDefaultCategories(int userId) async {
    final db = await _dbHelper.database;
    final categories = ToolCategoryModel.defaultCategories;
    
    for (int i = 0; i < categories.length; i++) {
      await db.insert('tool_categories', {
        'user_id': userId,
        'name_ar': categories[i]['name_ar'],
        'name_en': categories[i]['name_en'],
        'icon': categories[i]['icon'],
        'sort_order': i,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<int> addCategory(ToolCategoryModel category) async {
    final db = await _dbHelper.database;
    return await db.insert('tool_categories', category.toMap());
  }

  // ========================================
  // TOOLS
  // ========================================

  Future<List<ToolModel>> getTools(int userId, {int? categoryId, String? status}) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (status != null && status != 'all') {
      where += ' AND status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query(
      'tools',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => ToolModel.fromMap(m)).toList();
  }

  Future<ToolModel?> getToolById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tools',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ToolModel.fromMap(maps.first);
  }

  Future<int> addTool(ToolModel tool) async {
    final db = await _dbHelper.database;
    return await db.insert('tools', tool.toMap());
  }

  Future<int> updateTool(ToolModel tool) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tools',
      tool.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [tool.id],
    );
  }

  Future<int> deleteTool(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('tools', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToolStatus(int toolId, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'tools',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [toolId],
    );
  }

  // ========================================
  // EXTENSIONS
  // ========================================

  Future<List<ToolExtensionModel>> getExtensions(int toolId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tool_extensions',
      where: 'tool_id = ?',
      whereArgs: [toolId],
      orderBy: 'name ASC',
    );

    return maps.map((m) => ToolExtensionModel.fromMap(m)).toList();
  }

  Future<List<ToolExtensionModel>> getAvailableExtensions(int toolId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tool_extensions',
      where: 'tool_id = ? AND status = ?',
      whereArgs: [toolId, 'available'],
      orderBy: 'name ASC',
    );

    return maps.map((m) => ToolExtensionModel.fromMap(m)).toList();
  }

  Future<int> addExtension(ToolExtensionModel extension) async {
    final db = await _dbHelper.database;
    return await db.insert('tool_extensions', extension.toMap());
  }

  Future<int> updateExtension(ToolExtensionModel extension) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tool_extensions',
      extension.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [extension.id],
    );
  }

  Future<int> deleteExtension(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('tool_extensions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateExtensionStatus(int extensionId, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'tool_extensions',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [extensionId],
    );
  }

  // ========================================
  // TRANSACTIONS
  // ========================================

  Future<int> createTransaction(ToolTransactionModel transaction, List<int> extensionIds) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert transaction
      final transactionId = await txn.insert('tool_transactions', transaction.toMap());

      // 2. Insert selected extensions and update their status
      for (final extId in extensionIds) {
        await txn.insert('transaction_extensions', {
          'transaction_id': transactionId,
          'extension_id': extId,
        });
        // Update extension status
        await txn.update(
          'tool_extensions',
          {'status': 'rented', 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [extId],
        );
      }

      // 3. Update tool status
      final toolStatus = transaction.transactionType == 'rent' ? 'rented' : 'lent';
      await txn.update(
        'tools',
        {'status': toolStatus, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [transaction.toolId],
      );

      // 4. Record notification in DB
      await txn.insert('notifications', {
        'user_id': transaction.userId,
        'title': 'موعد إرجاع معدة',
        'body': 'يحين موعد إرجاع المعدة بتاريخ ${transaction.dueDate.toString().split(' ').first}',
        'type': 'tool_due',
        'related_type': 'tool_transactions',
        'related_id': transactionId,
        'scheduled_at': transaction.dueDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return transactionId;
    }).then((id) async {
      // Schedule system notification (outside DB transaction)
      await _scheduleNotification(id, transaction);
      return id;
    });
  }

  Future<void> _scheduleNotification(int transactionId, ToolTransactionModel transaction) async {
    try {
      if (transaction.dueDate.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: transactionId + 20000,
          title: 'موعد إرجاع معدة',
          body: 'يحين موعد إرجاع المعدة اليوم',
          scheduledDate: transaction.dueDate,
          payload: 'tool_transaction_$transactionId',
        );
      }
    } catch (e) {
      // Notification scheduling is not critical
    }
  }

  Future<void> returnTool(int transactionId,
      {double lateFee = 0, String? notes, bool isPaid = false, String paymentMethod = 'cash', int? bankAccountId}) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Get transaction details
      final maps = await txn.query('tool_transactions', where: 'id = ?', whereArgs: [transactionId]);
      if (maps.isEmpty) return;

      final transaction = ToolTransactionModel.fromMap(maps.first);
      final now = DateTime.now();

      // 2. Calculate final amounts
      final actualDays = now.difference(transaction.startDate).inDays;
      final totalDays = actualDays < 1 ? 1 : actualDays;
      final subtotal = transaction.combinedDailyRate * totalDays;
      final totalAmount = subtotal + lateFee;

      // 3. Update transaction
      await txn.update(
        'tool_transactions',
        {
          'return_date': now.toIso8601String(),
          'total_days': totalDays,
          'subtotal': subtotal,
          'late_fee': lateFee,
          'total_amount': totalAmount,
          'status': 'returned',
          'notes': notes ?? transaction.notes,
          'updated_at': now.toIso8601String(),
          'is_paid': isPaid ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // 4. Update tool status
      await txn.update(
        'tools',
        {'status': 'available', 'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [transaction.toolId],
      );

      // 5. Update extensions status
      final extMaps = await txn.query(
        'transaction_extensions',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
      for (final ext in extMaps) {
        await txn.update(
          'tool_extensions',
          {'status': 'available', 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [ext['extension_id']],
        );
      }

      // 6. Create income record for rentals ONLY if paid
      if (transaction.isRental && isPaid && totalAmount > 0) {
        // Get tool name
        final toolMaps = await txn.query('tools', where: 'id = ?', whereArgs: [transaction.toolId]);
        final toolName = toolMaps.isNotEmpty ? toolMaps.first['name'] as String : 'معدة';

        await txn.insert('income', {
          'user_id': transaction.userId,
          'amount': totalAmount,
          'source_type': 'tool_rental',
          'source_id': transactionId,
          'payment_method': paymentMethod,
          'bank_account_id': bankAccountId,
          'entry_date': now.toIso8601String(),
          'description': 'إيجار معدة: $toolName',
          'created_at': now.toIso8601String(),
        });
      }

      // 7. Cancel notification
      await NotificationService.instance.cancelNotification(transactionId + 20000);
    });
  }

  Future<List<ToolTransactionModel>> getTransactions(
    int userId, {
    int? toolId,
    int? personId,
    int? categoryId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 't.user_id = ?';
    List<dynamic> args = [userId];

    if (toolId != null) {
      whereClause += ' AND t.tool_id = ?';
      args.add(toolId);
    }
    if (personId != null) {
      whereClause += ' AND t.person_id = ?';
      args.add(personId);
    }
    if (categoryId != null) {
      whereClause += ' AND tool.category_id = ?';
      args.add(categoryId);
    }
    if (status != null && status != 'all') {
      whereClause += ' AND t.status = ?';
      args.add(status);
    }
    if (startDate != null) {
      whereClause += ' AND t.start_date >= ?';
      args.add(startDate.toIso8601String().split('T').first);
    }
    if (endDate != null) {
      // Use < next day to include the full end date
      whereClause += ' AND t.start_date < ?';
      args.add(endDate.add(const Duration(days: 1)).toIso8601String().split('T').first);
    }

    final maps = await db.rawQuery('''
      SELECT t.*, tool.name as tool_name, tool.category_id as category_id, p.name as person_name
      FROM tool_transactions t
      JOIN tools tool ON t.tool_id = tool.id
      JOIN people p ON t.person_id = p.id
      WHERE $whereClause
      ORDER BY t.start_date DESC
    ''', args);

    return maps.map((m) => ToolTransactionModel.fromMap(m)).toList();
  }

  Future<ToolTransactionModel?> getActiveTransaction(int toolId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT t.*, tool.name as tool_name, p.name as person_name
      FROM tool_transactions t
      JOIN tools tool ON t.tool_id = tool.id
      JOIN people p ON t.person_id = p.id
      WHERE t.tool_id = ? AND t.status = 'active'
      LIMIT 1
    ''', [toolId]);

    if (maps.isEmpty) return null;
    return ToolTransactionModel.fromMap(maps.first);
  }

  Future<List<int>> getTransactionExtensionIds(int transactionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transaction_extensions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((m) => m['extension_id'] as int).toList();
  }

  // ========================================
  // REPORTS & SUMMARIES
  // ========================================

  Future<Map<String, dynamic>> getToolsSummary(int userId) async {
    final db = await _dbHelper.database;

    // Tool counts by status
    final toolCounts = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM tools 
      WHERE user_id = ? 
      GROUP BY status
    ''', [userId]);

    int totalTools = 0;
    int availableTools = 0;
    int rentedTools = 0;
    int lentTools = 0;

    for (final row in toolCounts) {
      final count = row['count'] as int;
      totalTools += count;
      switch (row['status']) {
        case 'available':
          availableTools = count;
          break;
        case 'rented':
          rentedTools = count;
          break;
        case 'lent':
          lentTools = count;
          break;
      }
    }

    // Active transactions
    final activeTransactions = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tool_transactions 
      WHERE user_id = ? AND status = 'active'
    ''', [userId]);
    final activeCount = activeTransactions.first['count'] as int;

    // Overdue transactions
    final now = DateTime.now().toIso8601String();
    final overdueTransactions = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tool_transactions 
      WHERE user_id = ? AND status = 'active' AND due_date < ?
    ''', [userId, now]);
    final overdueCount = overdueTransactions.first['count'] as int;

    // Total income from tool rentals
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM income 
      WHERE user_id = ? AND source_type = 'tool_rental'
    ''', [userId]);
    final totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;

    // Total cost of tools
    final costResult = await db.rawQuery('''
      SELECT COALESCE(SUM(cost), 0) as total_cost FROM tools WHERE user_id = ?
    ''', [userId]);
    final totalToolsCost = (costResult.first['total_cost'] as num?)?.toDouble() ?? 0;

    // Total cost of extensions
    final extCostResult = await db.rawQuery('''
      SELECT COALESCE(SUM(e.cost), 0) as total_cost 
      FROM tool_extensions e
      JOIN tools t ON e.tool_id = t.id
      WHERE t.user_id = ?
    ''', [userId]);
    final totalExtensionsCost = (extCostResult.first['total_cost'] as num?)?.toDouble() ?? 0;

    return {
      'totalTools': totalTools,
      'availableTools': availableTools,
      'rentedTools': rentedTools,
      'lentTools': lentTools,
      'activeTransactions': activeCount,
      'overdueTransactions': overdueCount,
      'totalToolsCost': totalToolsCost,
      'totalExtensionsCost': totalExtensionsCost,
      'totalInvestment': totalToolsCost + totalExtensionsCost,
      'totalIncome': totalIncome,
    };
  }

  Future<List<Map<String, dynamic>>> getMostRentedTools(int userId, {int limit = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT t.id, t.name, COUNT(tr.id) as rental_count, SUM(tr.total_amount) as total_income
      FROM tools t
      LEFT JOIN tool_transactions tr ON t.id = tr.tool_id AND tr.transaction_type = 'rent'
      WHERE t.user_id = ?
      GROUP BY t.id
      ORDER BY rental_count DESC
      LIMIT ?
    ''', [userId, limit]);
  }

  Future<Map<String, double>> getFilteredPeriodStats(
    int userId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? personId,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;

    // Use getTransactions to ensure consistency with the list view logic
    // and to include active transactions' current value
    final transactions = await getTransactions(
      userId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      personId: personId,
      categoryId: categoryId,
    );

    double totalIncome = 0;
    for (final transaction in transactions) {
      if (transaction.isRental) {
        // Use currentTotalAmount to include accrued value of active transactions
        totalIncome += transaction.currentTotalAmount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'transactionCount': transactions.length.toDouble(),
    };
  }
}
