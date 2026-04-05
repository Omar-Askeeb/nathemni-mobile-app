import 'dart:convert';

/// Meal model for SQLite
class Meal {
  final int? id;
  final int? serverId;
  final int userId;
  final String name;
  final List<String> categories;
  final String? imagePath;
  final List<String> ingredients;
  final List<String> recipeSteps;
  final double? rating;
  final bool isSynced;
  final String? syncId;
  final bool createdOffline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final DateTime? lastModified;

  Meal({
    this.id,
    this.serverId,
    required this.userId,
    required this.name,
    this.categories = const [],
    this.imagePath,
    this.ingredients = const [],
    this.recipeSteps = const [],
    this.rating,
    this.isSynced = false,
    this.syncId,
    this.createdOffline = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
    this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'user_id': userId,
      'name': name,
      'categories': jsonEncode(categories),
      if (imagePath != null) 'image_path': imagePath,
      'ingredients': jsonEncode(ingredients),
      'recipe_steps': jsonEncode(recipeSteps),
      if (rating != null) 'rating': rating,
      'is_synced': isSynced ? 1 : 0,
      if (syncId != null) 'sync_id': syncId,
      'created_offline': createdOffline ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      'sync_status': syncStatus,
      'last_modified': (lastModified ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      categories: map['categories'] != null
          ? List<String>.from(jsonDecode(map['categories'] as String))
          : [],
      imagePath: map['image_path'] as String?,
      ingredients: map['ingredients'] != null
          ? List<String>.from(jsonDecode(map['ingredients'] as String))
          : [],
      recipeSteps: map['recipe_steps'] != null
          ? List<String>.from(jsonDecode(map['recipe_steps'] as String))
          : [],
      rating: map['rating'] as double?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      syncId: map['sync_id'] as String?,
      createdOffline: (map['created_offline'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
    );
  }

  Meal copyWith({
    int? id,
    int? serverId,
    int? userId,
    String? name,
    List<String>? categories,
    String? imagePath,
    List<String>? ingredients,
    List<String>? recipeSteps,
    double? rating,
    bool? isSynced,
    String? syncId,
    bool? createdOffline,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
    DateTime? lastModified,
  }) {
    return Meal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      imagePath: imagePath ?? this.imagePath,
      ingredients: ingredients ?? this.ingredients,
      recipeSteps: recipeSteps ?? this.recipeSteps,
      rating: rating ?? this.rating,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
      createdOffline: createdOffline ?? this.createdOffline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Meal Log model for SQLite
class MealLog {
  final int? id;
  final int? serverId;
  final int userId;
  final int mealId;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime eatenAt;
  final String? notes;
  final bool isSynced;
  final String? syncId;
  final bool createdOffline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final DateTime? lastModified;

  // Joined fields (optional)
  final String? mealName;

  MealLog({
    this.id,
    this.serverId,
    required this.userId,
    required this.mealId,
    required this.mealType,
    required this.eatenAt,
    this.notes,
    this.isSynced = false,
    this.syncId,
    this.createdOffline = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
    this.lastModified,
    this.mealName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'user_id': userId,
      'meal_id': mealId,
      'meal_type': mealType,
      'eaten_at': eatenAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      if (syncId != null) 'sync_id': syncId,
      'created_offline': createdOffline ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      'sync_status': syncStatus,
      'last_modified': (lastModified ?? DateTime.now()).toIso8601String(),
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      userId: map['user_id'] as int,
      mealId: map['meal_id'] as int,
      mealType: map['meal_type'] as String,
      eatenAt: DateTime.parse(map['eaten_at'] as String),
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      syncId: map['sync_id'] as String?,
      createdOffline: (map['created_offline'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
      mealName: map['meal_name'] as String?,
    );
  }

  MealLog copyWith({
    int? id,
    int? serverId,
    int? userId,
    int? mealId,
    String? mealType,
    DateTime? eatenAt,
    String? notes,
    bool? isSynced,
    String? syncId,
    bool? createdOffline,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
    DateTime? lastModified,
  }) {
    return MealLog(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      mealId: mealId ?? this.mealId,
      mealType: mealType ?? this.mealType,
      eatenAt: eatenAt ?? this.eatenAt,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
      createdOffline: createdOffline ?? this.createdOffline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      mealName: mealName ?? this.mealName,
    );
  }
}
