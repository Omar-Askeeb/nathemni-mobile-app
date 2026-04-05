import 'package:sqflite/sqflite.dart';
import '../../../../data/local/database_helper.dart';
import 'meal_model.dart';

class MealsRepository {
  final DatabaseHelper _databaseHelper;

  MealsRepository(this._databaseHelper);

  // ========================================
  // MEALS OPERATIONS
  // ========================================

  Future<List<Meal>> getMeals({String? category}) async {
    final db = await _databaseHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (category != null && category != 'all') {
      // Since categories is a JSON list or comma-separated string, we use LIKE
      // Note: This is a simple implementation. For more robust, use a join table.
      whereClause = 'categories LIKE ? AND deleted_at IS NULL';
      whereArgs = ['%$category%'];
    } else {
      whereClause = 'deleted_at IS NULL';
    }

    final result = await db.query(
      'meals',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Meal.fromMap(map)).toList();
  }

  Future<Meal?> getMealById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Meal.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertMeal(Meal meal) async {
    final db = await _databaseHelper.database;
    return await db.insert('meals', meal.toMap());
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(int id) async {
    final db = await _databaseHelper.database;
    // Soft delete
    return await db.update(
      'meals',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // MEAL LOGS OPERATIONS
  // ========================================

  Future<List<MealLog>> getMealLogs({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'l.deleted_at IS NULL';
    List<dynamic> whereArgs = [];

    if (start != null) {
      whereClause += ' AND l.eaten_at >= ?';
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      whereClause += ' AND l.eaten_at <= ?';
      whereArgs.add(end.toIso8601String());
    }

    // Join with meals table to get meal name
    final result = await db.rawQuery('''
      SELECT l.*, m.name as meal_name 
      FROM meal_logs l
      LEFT JOIN meals m ON l.meal_id = m.id
      WHERE $whereClause
      ORDER BY l.eaten_at DESC
    ''', whereArgs);

    return result.map((map) => MealLog.fromMap(map)).toList();
  }

  Future<int> insertMealLog(MealLog log) async {
    final db = await _databaseHelper.database;
    return await db.insert('meal_logs', log.toMap());
  }

  Future<int> deleteMealLog(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  // Get last time a meal was eaten
  Future<DateTime?> getLastEatenDate(int mealId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'meal_logs',
      columns: ['eaten_at'],
      where: 'meal_id = ? AND deleted_at IS NULL',
      whereArgs: [mealId],
      orderBy: 'eaten_at DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return DateTime.parse(result.first['eaten_at'] as String);
    }
    return null;
  }
}
