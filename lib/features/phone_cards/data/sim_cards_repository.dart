import '../../../data/local/database_helper.dart';
import 'sim_card_model.dart';

/// Repository for SIM cards data operations
class SimCardsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all SIM cards for a user
  Future<List<SimCardModel>> getAllSimCards(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sim_cards',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'provider, created_at DESC',
    );

    return List.generate(maps.length, (i) => SimCardModel.fromMap(maps[i]));
  }

  // Get SIM cards by provider
  Future<List<SimCardModel>> getSimCardsByProvider(
      int userId, String provider) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sim_cards',
      where: 'user_id = ? AND provider = ? AND deleted_at IS NULL',
      whereArgs: [userId, provider],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => SimCardModel.fromMap(maps[i]));
  }

  // Search SIM cards
  Future<List<SimCardModel>> searchSimCards(
      int userId, String provider, String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sim_cards',
      where:
          'user_id = ? AND provider = ? AND sim_number LIKE ? AND deleted_at IS NULL',
      whereArgs: [userId, provider, '%$query%'],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => SimCardModel.fromMap(maps[i]));
  }

  // Get single SIM card
  Future<SimCardModel?> getSimCard(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sim_cards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SimCardModel.fromMap(maps.first);
    }
    return null;
  }

  // Count SIM cards by provider
  Future<int> countSimCardsByProvider(int userId, String provider) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sim_cards WHERE user_id = ? AND provider = ? AND deleted_at IS NULL',
      [userId, provider],
    );
    return result.first['count'] as int;
  }

  // Add new SIM card
  Future<int> addSimCard(SimCardModel simCard) async {
    final db = await _dbHelper.database;
    
    // Check if limit reached (10 per provider)
    final count = await countSimCardsByProvider(simCard.userId, simCard.provider);
    if (count >= 10) {
      throw Exception('تم الوصول للحد الأقصى (10 بطاقات) لهذا المزود');
    }

    return await db.insert('sim_cards', simCard.toMap());
  }

  // Update SIM card
  Future<int> updateSimCard(SimCardModel simCard) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sim_cards',
      simCard.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      ).toMap(),
      where: 'id = ?',
      whereArgs: [simCard.id],
    );
  }

  // Delete SIM card (soft delete)
  Future<int> deleteSimCard(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sim_cards',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hard delete SIM card
  Future<int> hardDeleteSimCard(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'sim_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get statistics
  Future<Map<String, int>> getStatistics(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        provider,
        COUNT(*) as count
      FROM sim_cards
      WHERE user_id = ? AND deleted_at IS NULL
      GROUP BY provider
    ''', [userId]);

    Map<String, int> stats = {
      'libyana': 0,
      'almadar': 0,
      'ltt': 0,
    };

    for (var row in result) {
      stats[row['provider'] as String] = row['count'] as int;
    }

    return stats;
  }
}
