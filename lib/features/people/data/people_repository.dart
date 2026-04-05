import '../../../data/local/database_helper.dart';
import 'person_model.dart';

class PeopleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<PersonModel>> getAllPeople(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'people',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PersonModel.fromMap(maps[i]));
  }

  Future<List<PersonModel>> getPeopleByType(int userId, String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'people',
      where: 'user_id = ? AND type = ? AND deleted_at IS NULL',
      whereArgs: [userId, type],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PersonModel.fromMap(maps[i]));
  }

  Future<PersonModel?> getPersonById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'people',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PersonModel.fromMap(maps.first);
  }

  Future<List<PersonModel>> searchPeople(int userId, String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'people',
      where: 'user_id = ? AND name LIKE ? AND deleted_at IS NULL',
      whereArgs: [userId, '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PersonModel.fromMap(maps[i]));
  }

  Future<int> addPerson(PersonModel person) async {
    final db = await _dbHelper.database;
    return await db.insert('people', person.toMap());
  }

  Future<int> updatePerson(PersonModel person) async {
    final db = await _dbHelper.database;
    return await db.update(
      'people',
      person.copyWith(updatedAt: DateTime.now(), syncStatus: 'pending').toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'people',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending'
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPersonCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM people WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
