import 'dart:convert';

/// Local SQLite model for tasks
/// Simplified version optimized for offline storage
class TaskLocalModel {
  final int? id; // Local ID
  final int? serverId; // Backend ID (when synced)
  final int userId;
  final int? assignedTo;
  final int? categoryId;
  final String title;
  final String? description;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String? taskType; // 'shopping', 'tasks', or null for regular tasks
  final String? expenseCategory; // Expense category ID for shopping tasks
  final DateTime? dueDate;
  final String? dueTime;
  final DateTime? completedAt;
  final int? completedBy;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final bool isShared;
  final bool isSynced;
  final String? syncId;
  final bool createdOffline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String syncStatus; // 'pending', 'synced', 'failed', 'conflict'
  final DateTime? lastModified;

  TaskLocalModel({
    this.id,
    this.serverId,
    required this.userId,
    this.assignedTo,
    this.categoryId,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.status = 'pending',
    this.taskType,
    this.expenseCategory,
    this.dueDate,
    this.dueTime,
    this.completedAt,
    this.completedBy,
    this.isRecurring = false,
    this.recurrencePattern,
    this.isShared = false,
    this.isSynced = false,
    this.syncId,
    this.createdOffline = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
    this.lastModified,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'user_id': userId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      'status': status,
      if (taskType != null) 'task_type': taskType,
      if (expenseCategory != null) 'expense_category': expenseCategory,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (dueTime != null) 'due_time': dueTime,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (completedBy != null) 'completed_by': completedBy,
      'is_recurring': isRecurring ? 1 : 0,
      if (recurrencePattern != null)
        'recurrence_pattern': jsonEncode(recurrencePattern),
      'is_shared': isShared ? 1 : 0,
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

  // Create from SQLite Map
  factory TaskLocalModel.fromMap(Map<String, dynamic> map) {
    return TaskLocalModel(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      userId: map['user_id'] as int,
      assignedTo: map['assigned_to'] as int?,
      categoryId: map['category_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      taskType: map['task_type'] as String?,
      expenseCategory: map['expense_category'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      dueTime: map['due_time'] as String?,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      completedBy: map['completed_by'] as int?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrencePattern: map['recurrence_pattern'] != null
          ? jsonDecode(map['recurrence_pattern'] as String)
          : null,
      isShared: (map['is_shared'] as int? ?? 0) == 1,
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

  // Copy with method
  TaskLocalModel copyWith({
    int? id,
    int? serverId,
    int? userId,
    int? assignedTo,
    int? categoryId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? taskType,
    String? expenseCategory,
    DateTime? dueDate,
    String? dueTime,
    DateTime? completedAt,
    int? completedBy,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    bool? isShared,
    bool? isSynced,
    String? syncId,
    bool? createdOffline,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
    DateTime? lastModified,
  }) {
    return TaskLocalModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      taskType: taskType ?? this.taskType,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      isShared: isShared ?? this.isShared,
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

  // Helper getters
  bool get isCompleted => status == 'completed';
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isPending => syncStatus == 'pending';
  bool get isSyncFailed => syncStatus == 'failed';
  bool get hasConflict => syncStatus == 'conflict';
}
