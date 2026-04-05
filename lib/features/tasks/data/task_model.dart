import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final int id;
  final int userId;
  final int? assignedTo;
  final int? categoryId;
  final String title;
  final String? description;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final DateTime? dueDate;
  final String? dueTime;
  final DateTime? completedAt;
  final int? completedBy;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final bool isShared;
  final bool isSynced;
  final String? syncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Relationships
  final Category? category;
  final User? assignee;
  final User? user;

  const Task({
    required this.id,
    required this.userId,
    this.assignedTo,
    this.categoryId,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.status = 'pending',
    this.dueDate,
    this.dueTime,
    this.completedAt,
    this.completedBy,
    this.isRecurring = false,
    this.recurrencePattern,
    this.isShared = false,
    this.isSynced = false,
    this.syncId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.category,
    this.assignee,
    this.user,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      assignedTo: json['assigned_to'] as int?,
      categoryId: json['category_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      dueTime: json['due_time'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as Map<String, dynamic>?,
      isShared: json['is_shared'] as bool? ?? false,
      isSynced: json['is_synced'] as bool? ?? false,
      syncId: json['sync_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? User.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (dueTime != null) 'due_time': dueTime,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (completedBy != null) 'completed_by': completedBy,
      'is_recurring': isRecurring,
      if (recurrencePattern != null) 'recurrence_pattern': recurrencePattern,
      'is_shared': isShared,
      'is_synced': isSynced,
      if (syncId != null) 'sync_id': syncId,
    };
  }

  bool get isCompleted => status == 'completed';
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  Task copyWith({
    int? id,
    int? userId,
    int? assignedTo,
    int? categoryId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
    String? dueTime,
    DateTime? completedAt,
    int? completedBy,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    bool? isShared,
    bool? isSynced,
    String? syncId,
    Category? category,
    User? assignee,
    User? user,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      isShared: isShared ?? this.isShared,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
      category: category ?? this.category,
      assignee: assignee ?? this.assignee,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        assignedTo,
        categoryId,
        title,
        description,
        priority,
        status,
        dueDate,
        dueTime,
        completedAt,
        completedBy,
        isRecurring,
        recurrencePattern,
        isShared,
        isSynced,
        syncId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

// Simplified Category model for relationships
class Category {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? type;
  final String? icon;
  final String? color;

  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.type,
    this.icon,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      type: json['type'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;
}

// Simplified User model for relationships
class User {
  final int id;
  final String name;
  final String? email;

  const User({
    required this.id,
    required this.name,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }
}
