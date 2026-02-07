/// Model for person data
class PersonModel {
  final int? id;
  final int userId;
  final String name;
  final String? phone;
  final String? email;
  final String type; // 'friend', 'family', 'coworker', 'other'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  PersonModel({
    this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.type = 'other',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      type: map['type'] as String? ?? 'other',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'type': type,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  PersonModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? phone,
    String? email,
    String? type,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return PersonModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  String get typeArabic {
    switch (type) {
      case 'friend':
        return 'صديق';
      case 'family':
        return 'عائلة';
      case 'coworker':
        return 'زميل عمل';
      case 'client':
        return 'عميل';
      case 'supplier':
        return 'مورد';
      default:
        return 'آخر';
    }
  }

  static List<Map<String, String>> get allTypes => [
    {'id': 'friend', 'name': 'صديق', 'icon': '👤'},
    {'id': 'family', 'name': 'عائلة', 'icon': '👨‍👩‍👧‍👦'},
    {'id': 'coworker', 'name': 'زميل عمل', 'icon': '💼'},
    {'id': 'client', 'name': 'عميل', 'icon': '🤝'},
    {'id': 'supplier', 'name': 'مورد', 'icon': '📦'},
    {'id': 'other', 'name': 'آخر', 'icon': '👥'},
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PersonModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.type == type &&
        other.notes == notes &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        type.hashCode ^
        notes.hashCode ^
        syncStatus.hashCode;
  }
}
