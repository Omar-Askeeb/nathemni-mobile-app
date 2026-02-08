import 'package:sqflite/sqflite.dart';
import '../../../data/local/database_helper.dart';
import 'car_model.dart';
import 'oil_change_model.dart';
import 'car_document_model.dart';

class CarRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CARS
  // ========================================

  Future<List<Car>> getAllCars(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cars',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Car.fromJson(maps[i]));
  }

  Future<Car?> getCarById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cars',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Car.fromJson(maps.first);
  }

  Future<int> addCar(Car car) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = car.toJson();
    data['created_at'] = now;
    data['updated_at'] = now;
    data['last_modified'] = now;
    return await db.insert('cars', data);
  }

  Future<void> updateCar(Car car) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = car.toJson();
    data['updated_at'] = now;
    data['last_modified'] = now;
    await db.update(
      'cars',
      data,
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<void> deleteCar(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'cars',
      {'deleted_at': now, 'last_modified': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // OIL CHANGES
  // ========================================

  Future<List<OilChange>> getOilChangeHistory(int carId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'car_oil_changes',
      where: 'car_id = ? AND deleted_at IS NULL',
      whereArgs: [carId],
      orderBy: 'change_date DESC',
    );
    return List.generate(maps.length, (i) => OilChange.fromJson(maps[i]));
  }

  Future<OilChange?> getLatestOilChange(int carId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'car_oil_changes',
      where: 'car_id = ? AND deleted_at IS NULL',
      whereArgs: [carId],
      orderBy: 'change_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OilChange.fromJson(maps.first);
  }

  Future<int> addOilChange(OilChange oilChange) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = oilChange.toJson();
    data['created_at'] = now;
    data['updated_at'] = now;
    data['last_modified'] = now;
    return await db.insert('car_oil_changes', data);
  }

  Future<void> updateOilChange(OilChange oilChange) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = oilChange.toJson();
    data['updated_at'] = now;
    data['last_modified'] = now;
    await db.update(
      'car_oil_changes',
      data,
      where: 'id = ?',
      whereArgs: [oilChange.id],
    );
  }

  Future<void> deleteOilChange(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'car_oil_changes',
      {'deleted_at': now, 'last_modified': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // CAR DOCUMENTS
  // ========================================

  Future<List<CarDocument>> getCarDocuments(int carId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'car_documents',
      where: 'car_id = ? AND deleted_at IS NULL',
      whereArgs: [carId],
      orderBy: 'renewal_date DESC',
    );
    return List.generate(maps.length, (i) => CarDocument.fromJson(maps[i]));
  }

  Future<List<CarDocument>> getDocumentsByType(
      int carId, CarDocumentType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'car_documents',
      where: 'car_id = ? AND document_type = ? AND deleted_at IS NULL',
      whereArgs: [carId, type.name],
      orderBy: 'renewal_date DESC',
    );
    return List.generate(maps.length, (i) => CarDocument.fromJson(maps[i]));
  }

  Future<List<CarDocument>> getExpiringSoonDocuments(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final fifteenDaysLater = now.add(const Duration(days: 15));
    final nowStr = now.toIso8601String().split('T')[0];
    final laterStr = fifteenDaysLater.toIso8601String().split('T')[0];

    // Get the latest document of each type for each car, then filter by expiry
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM car_documents 
      WHERE user_id = ? 
      AND deleted_at IS NULL
      AND id IN (
        SELECT id FROM car_documents 
        WHERE user_id = ? AND deleted_at IS NULL
        GROUP BY car_id, document_type 
        HAVING MAX(renewal_date)
      )
      AND expiry_date <= ? 
      AND expiry_date >= ?
      ORDER BY expiry_date ASC
    ''', [userId, userId, laterStr, nowStr]);

    return List.generate(maps.length, (i) => CarDocument.fromJson(maps[i]));
  }

  Future<int> addCarDocument(CarDocument document) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = document.toJson();
    data['created_at'] = now;
    data['updated_at'] = now;
    data['last_modified'] = now;
    return await db.insert('car_documents', data);
  }

  Future<void> updateCarDocument(CarDocument document) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = document.toJson();
    data['updated_at'] = now;
    data['last_modified'] = now;
    await db.update(
      'car_documents',
      data,
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteCarDocument(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'car_documents',
      {'deleted_at': now, 'last_modified': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
