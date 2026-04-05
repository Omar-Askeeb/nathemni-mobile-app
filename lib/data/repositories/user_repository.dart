import 'package:flutter/foundation.dart';
import '../local/database_helper.dart';
import '../models/user.dart';

/// Repository for managing local user data in SQLite
class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Save or update a user in the local database
  Future<User> saveUser(User user) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    debugPrint('UserRepository: Saving user: ${user.toJson()}');
    final existingUser = await getUser(user.id);
    
    if (existingUser != null) {
      // Update existing user - merge new data with existing to preserve local fields
      final mergedUser = existingUser.merge(user).copyWith(updatedAt: now);
      debugPrint('UserRepository: Merged user for update: ${mergedUser.toJson()}');
      await db.update(
        'users',
        mergedUser.toJson(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return mergedUser;
    } else {
      // Insert new user
      final newUser = user.copyWith(createdAt: now, updatedAt: now);
      debugPrint('UserRepository: Inserting new user: ${newUser.toJson()}');
      await db.insert(
        'users',
        newUser.toJson(),
      );
      return newUser;
    }
  }

  /// Get a user by ID
  Future<User?> getUser(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      debugPrint('UserRepository: User with ID $id not found in DB');
      return null;
    }
    
    debugPrint('UserRepository: Found user in DB: ${results.first}');
    return User.fromJson(results.first);
  }

  /// Get a user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromJson(results.first);
  }

  /// Get a user by phone
  Future<User?> getUserByPhone(String phone) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromJson(results.first);
  }

  /// Get a user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromJson(results.first);
  }

  /// Get the current logged-in user (first active user)
  Future<User?> getCurrentUser() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromJson(results.first);
  }

  /// Check if any user exists in the database
  Future<bool> hasUser() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      columns: ['id'],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Check if a registered user exists (not the default user)
  Future<bool> hasRegisteredUser() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username IS NOT NULL OR email IS NOT NULL',
      columns: ['id'],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Update user data
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      'users',
      {
        ...user.toJson(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Update user profile image path
  Future<int> updateProfileImage(int userId, String imagePath) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      'users',
      {
        'profile_image': imagePath,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete a user
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all users (for logout/reset)
  Future<void> clearAllUsers() async {
    final db = await _dbHelper.database;
    await db.delete('users');
    debugPrint('All users cleared from local database');
  }

  /// Create a new user with registration data
  Future<User> createUser({
    required String name,
    required String nameAr,
    required String nameEn,
    required String username,
    required String email,
    required String phone,
    String? profileImage,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final id = await db.insert('users', {
      'name': name,
      'name_ar': nameAr,
      'name_en': nameEn,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'is_active': 1,
      'language': 'ar',
      'created_at': now,
      'updated_at': now,
    });

    return User(
      id: id,
      name: name,
      nameAr: nameAr,
      nameEn: nameEn,
      username: username,
      email: email,
      phone: phone,
      profileImage: profileImage,
      isActive: true,
      language: 'ar',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Validate login credentials (for offline login)
  Future<User?> validateLogin(String identifier, String passwordHash) async {
    final db = await _dbHelper.database;
    
    // Try to find user by email or phone
    final results = await db.query(
      'users',
      where: '(email = ? OR phone = ?) AND password_hash = ? AND is_active = 1',
      whereArgs: [identifier, identifier, passwordHash],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromJson(results.first);
  }

  /// Store password hash for offline login
  Future<void> setPasswordHash(int userId, String passwordHash) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Verify current password hash
  Future<bool> verifyPasswordHash(int userId, String passwordHash) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ? AND password_hash = ?',
      whereArgs: [userId, passwordHash],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Change password (verify old, set new)
  Future<bool> changePassword(int userId, String oldPasswordHash, String newPasswordHash) async {
    // Verify old password first
    final isValid = await verifyPasswordHash(userId, oldPasswordHash);
    if (!isValid) return false;

    // Update to new password
    await setPasswordHash(userId, newPasswordHash);
    return true;
  }

  /// Delete user account and all related data
  Future<bool> deleteUserAccount(int userId) async {
    final db = await _dbHelper.database;
    try {
      // Delete user - cascades to related data due to foreign keys
      final deleted = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return deleted > 0;
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      return false;
    }
  }
}
