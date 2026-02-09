/// Model for Notification data
class NotificationModel {
  final int? id;
  final int userId;
  final String title;
  final String body;
  final String type; // tool_due, doc_expiry, general
  final String? relatedType; // tools, car_documents, etc.
  final int? relatedId;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final String syncStatus;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedType,
    this.relatedId,
    this.scheduledAt,
    this.sentAt,
    this.readAt,
    DateTime? createdAt,
    this.syncStatus = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      relatedType: map['related_type'] as String?,
      relatedId: map['related_id'] as int?,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String)
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'] as String)
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_type': relatedType,
      'related_id': relatedId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    String? relatedType,
    int? relatedId,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  bool get isRead => readAt != null;
}
