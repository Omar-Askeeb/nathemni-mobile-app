import '../../../data/local/database_helper.dart';
import 'bank_account_model.dart';

class BankAccountsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<BankAccountModel>> getAllBankAccounts(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bank_accounts',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => BankAccountModel.fromMap(maps[i]));
  }

  Future<BankAccountModel?> getBankAccount(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bank_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BankAccountModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> addBankAccount(BankAccountModel account) async {
    final db = await _dbHelper.database;
    return await db.insert('bank_accounts', account.toMap());
  }

  Future<int> updateBankAccount(BankAccountModel account) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bank_accounts',
      account.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      ).toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteBankAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bank_accounts',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
