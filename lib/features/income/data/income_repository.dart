import '../../../data/local/database_helper.dart';
import 'income_model.dart';

class IncomeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<IncomeModel>> getIncomes(
    int userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? sourceType,
    String? paymentMethod,
    int? bankAccountId,
  }) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      where += ' AND entry_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND entry_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (sourceType != null && sourceType != 'all') {
      where += ' AND source_type = ?';
      whereArgs.add(sourceType);
    }

    if (paymentMethod != null && paymentMethod != 'all') {
      where += ' AND payment_method = ?';
      whereArgs.add(paymentMethod);
    }

    if (bankAccountId != null) {
      where += ' AND bank_account_id = ?';
      whereArgs.add(bankAccountId);
    }

    final maps = await db.query(
      'income',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'entry_date DESC, created_at DESC',
    );

    return maps.map((m) => IncomeModel.fromMap(m)).toList();
  }

  Future<int> addIncome(IncomeModel income) async {
    final db = await _dbHelper.database;
    return await db.insert('income', income.toMap());
  }

  Future<int> updateIncome(IncomeModel income) async {
    final db = await _dbHelper.database;
    return await db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncome(
    int userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? sourceType,
    String? paymentMethod,
    int? bankAccountId,
  }) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      where += ' AND entry_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND entry_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (sourceType != null && sourceType != 'all') {
      where += ' AND source_type = ?';
      whereArgs.add(sourceType);
    }

    if (paymentMethod != null && paymentMethod != 'all') {
      where += ' AND payment_method = ?';
      whereArgs.add(paymentMethod);
    }

    if (bankAccountId != null) {
      where += ' AND bank_account_id = ?';
      whereArgs.add(bankAccountId);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE $where',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
