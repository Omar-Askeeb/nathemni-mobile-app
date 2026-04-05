import '../../../data/local/database_helper.dart';
import 'expense_local_model.dart';

class ExpensesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<dynamic> get database async => await _dbHelper.database;

  Future<List<ExpenseLocalModel>> getAllExpenses(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'expense_date DESC',
    );
    return List.generate(maps.length, (i) => ExpenseLocalModel.fromMap(maps[i]));
  }

  Future<List<ExpenseLocalModel>> getExpensesByDateRange(
      int userId, DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'user_id = ? AND expense_date BETWEEN ? AND ? AND deleted_at IS NULL',
      whereArgs: [userId, startDate.toIso8601String().split('T')[0], 
                  endDate.toIso8601String().split('T')[0]],
      orderBy: 'expense_date DESC',
    );
    return List.generate(maps.length, (i) => ExpenseLocalModel.fromMap(maps[i]));
  }

  Future<List<ExpenseLocalModel>> getExpensesByCategory(
      int userId, String categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'user_id = ? AND category_id = ? AND deleted_at IS NULL',
      whereArgs: [userId, categoryId],
      orderBy: 'expense_date DESC',
    );
    return List.generate(maps.length, (i) => ExpenseLocalModel.fromMap(maps[i]));
  }

  Future<int> addExpense(ExpenseLocalModel expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(ExpenseLocalModel expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now(), syncStatus: 'pending').toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      {'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalByCategory(int userId, String categoryId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND category_id = ? AND deleted_at IS NULL',
      [userId, categoryId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalByDateRange(
      int userId, DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE user_id = ? AND expense_date BETWEEN ? AND ? AND deleted_at IS NULL',
      [userId, startDate.toIso8601String().split('T')[0], 
       endDate.toIso8601String().split('T')[0]],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<ExpenseLocalModel?> getExpenseByLinkedItem(String linkedTo, int linkedId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'linked_to = ? AND linked_id = ? AND deleted_at IS NULL',
      whereArgs: [linkedTo, linkedId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseLocalModel.fromMap(maps.first);
  }
}
