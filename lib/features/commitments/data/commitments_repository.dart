import '../../../data/local/database_helper.dart';
import '../../people/data/person_model.dart';
import 'commitment_model.dart';

class CommitmentsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ===== COMMITMENTS =====

  Future<List<CommitmentModel>> getAllCommitments(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'commitments',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    List<CommitmentModel> commitments = [];
    for (var map in maps) {
      final person = await _getPersonById(map['person_id'] as int);
      final paidAmount = await _getTotalPaidAmount(map['id'] as int);
      commitments.add(CommitmentModel.fromMap(map, person: person, paidAmount: paidAmount));
    }
    return commitments;
  }

  Future<List<CommitmentModel>> getCommitmentsByType(int userId, String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'commitments',
      where: 'user_id = ? AND type = ? AND deleted_at IS NULL',
      whereArgs: [userId, type],
      orderBy: 'created_at DESC',
    );

    List<CommitmentModel> commitments = [];
    for (var map in maps) {
      final person = await _getPersonById(map['person_id'] as int);
      final paidAmount = await _getTotalPaidAmount(map['id'] as int);
      commitments.add(CommitmentModel.fromMap(map, person: person, paidAmount: paidAmount));
    }
    return commitments;
  }

  Future<CommitmentModel?> getCommitmentById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'commitments',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    
    final person = await _getPersonById(maps.first['person_id'] as int);
    final paidAmount = await _getTotalPaidAmount(id);
    return CommitmentModel.fromMap(maps.first, person: person, paidAmount: paidAmount);
  }

  Future<int> addCommitment(CommitmentModel commitment) async {
    final db = await _dbHelper.database;
    return await db.insert('commitments', commitment.toMap());
  }

  Future<int> updateCommitment(CommitmentModel commitment) async {
    final db = await _dbHelper.database;
    return await db.update(
      'commitments',
      commitment.copyWith(updatedAt: DateTime.now(), syncStatus: 'pending').toMap(),
      where: 'id = ?',
      whereArgs: [commitment.id],
    );
  }

  Future<int> deleteCommitment(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'commitments',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending'
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCommitmentStatus(int id) async {
    final db = await _dbHelper.database;
    final commitment = await getCommitmentById(id);
    if (commitment == null) return;

    String newStatus;
    if (commitment.isFullyPaid) {
      newStatus = 'completed';
    } else if ((commitment.paidAmount ?? 0) > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'pending';
    }

    await db.update(
      'commitments',
      {'status': newStatus, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== PAYMENTS =====

  Future<List<DebtPaymentModel>> getPaymentsForCommitment(int commitmentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'debt_payments',
      where: 'commitment_id = ?',
      whereArgs: [commitmentId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => DebtPaymentModel.fromMap(maps[i]));
  }

  Future<int> addPayment(DebtPaymentModel payment) async {
    final db = await _dbHelper.database;
    final id = await db.insert('debt_payments', payment.toMap());
    await updateCommitmentStatus(payment.commitmentId);
    return id;
  }

  Future<int> deletePayment(int paymentId, int commitmentId) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'debt_payments',
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    await updateCommitmentStatus(commitmentId);
    return result;
  }

  // ===== TOTALS =====

  Future<double> getTotalDebtToMe(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(c.amount), 0) - COALESCE(SUM(p.total_paid), 0) as remaining
      FROM commitments c
      LEFT JOIN (
        SELECT commitment_id, SUM(amount) as total_paid
        FROM debt_payments
        GROUP BY commitment_id
      ) p ON c.id = p.commitment_id
      WHERE c.user_id = ? AND c.type = 'debt_to_me' AND c.deleted_at IS NULL AND c.status != 'completed'
    ''', [userId]);
    return (result.first['remaining'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalDebtFromMe(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(c.amount), 0) - COALESCE(SUM(p.total_paid), 0) as remaining
      FROM commitments c
      LEFT JOIN (
        SELECT commitment_id, SUM(amount) as total_paid
        FROM debt_payments
        GROUP BY commitment_id
      ) p ON c.id = p.commitment_id
      WHERE c.user_id = ? AND c.type = 'debt_from_me' AND c.deleted_at IS NULL AND c.status != 'completed'
    ''', [userId]);
    return (result.first['remaining'] as num?)?.toDouble() ?? 0.0;
  }

  // ===== HELPERS =====

  Future<PersonModel?> _getPersonById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PersonModel.fromMap(maps.first);
  }

  Future<double> _getTotalPaidAmount(int commitmentId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM debt_payments WHERE commitment_id = ?',
      [commitmentId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
