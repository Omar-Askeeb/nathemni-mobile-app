import 'package:sqflite/sqflite.dart';
import '../../../data/local/database_helper.dart';
import 'task_local_model.dart';

/// Data Access Object for Tasks table
/// Handles all SQLite CRUD operations for tasks
class TasksLocalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CREATE
  // ========================================

  Future<TaskLocalModel> insert(TaskLocalModel task) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return task.copyWith(id: id);
  }

  Future<void> insertAll(List<TaskLocalModel> tasks) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert('tasks', task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ========================================
  // READ
  // ========================================

  Future<List<TaskLocalModel>> getAllTasks({int? userId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: userId != null ? 'user_id = ? AND deleted_at IS NULL' : 'deleted_at IS NULL',
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  Future<TaskLocalModel?> getTaskById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskLocalModel.fromMap(maps.first);
  }

  Future<TaskLocalModel?> getTaskByServerId(int serverId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'server_id = ? AND deleted_at IS NULL',
      whereArgs: [serverId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskLocalModel.fromMap(maps.first);
  }

  Future<List<TaskLocalModel>> getTasksByStatus({
    required int userId,
    required String status,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'user_id = ? AND status = ? AND deleted_at IS NULL',
      whereArgs: [userId, status],
      orderBy: 'due_date ASC, created_at DESC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  Future<List<TaskLocalModel>> getTasksByCategory({
    required int userId,
    required int categoryId,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'user_id = ? AND category_id = ? AND deleted_at IS NULL',
      whereArgs: [userId, categoryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  Future<List<TaskLocalModel>> getOverdueTasks(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'user_id = ? AND status != ? AND due_date < ? AND deleted_at IS NULL',
      whereArgs: [userId, 'completed', now],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  Future<List<TaskLocalModel>> getTodayTasks(int userId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'user_id = ? AND due_date = ? AND deleted_at IS NULL',
      whereArgs: [userId, today],
      orderBy: 'due_time ASC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  Future<List<TaskLocalModel>> getPendingSyncTasks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified ASC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  // ========================================
  // UPDATE
  // ========================================

  Future<int> update(TaskLocalModel task) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> updateServerId(int localId, int serverId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tasks',
      {
        'server_id': serverId,
        'sync_status': 'synced',
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> updateSyncStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tasks',
      {
        'sync_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAsCompleted(int id, int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'tasks',
      {
        'status': 'completed',
        'completed_at': now,
        'completed_by': userId,
        'sync_status': 'pending',
        'updated_at': now,
        'last_modified': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // DELETE
  // ========================================

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    // Soft delete
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'tasks',
      {
        'deleted_at': now,
        'sync_status': 'pending',
        'updated_at': now,
        'last_modified': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentDelete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('tasks');
  }

  // ========================================
  // SEARCH & FILTER
  // ========================================

  Future<List<TaskLocalModel>> searchTasks({
    required int userId,
    required String query,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'user_id = ? AND (title LIKE ? OR description LIKE ?) AND deleted_at IS NULL',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TaskLocalModel.fromMap(map)).toList();
  }

  // ========================================
  // STATISTICS
  // ========================================

  Future<Map<String, int>> getTasksCount(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed
      FROM tasks 
      WHERE user_id = ? AND deleted_at IS NULL
    ''', [userId]);

    final row = result.first;
    return {
      'total': row['total'] as int? ?? 0,
      'pending': row['pending'] as int? ?? 0,
      'in_progress': row['in_progress'] as int? ?? 0,
      'completed': row['completed'] as int? ?? 0,
    };
  }
}
