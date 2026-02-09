/// Model for Tool data
class ToolModel {
  final int? id;
  final int userId;
  final int categoryId;
  final String name;
  final String? description;
  final double cost; // Purchase cost - what user paid for the tool
  final double dailyPrice; // Rental price per day
  final String status; // available, rented, lent, maintenance
  final String? imagePath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  ToolModel({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    this.description,
    this.cost = 0,
    this.dailyPrice = 0,
    this.status = 'available',
    this.imagePath,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ToolModel.fromMap(Map<String, dynamic> map) {
    return ToolModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      categoryId: map['category_id'] as int? ?? 0,
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      dailyPrice: (map['daily_price'] as num?)?.toDouble() ?? 0,
      status: (map['status'] as String?) ?? 'available',
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      syncStatus: (map['sync_status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'cost': cost,
      'daily_price': dailyPrice,
      'status': status,
      'image_path': imagePath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  ToolModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? name,
    String? description,
    double? cost,
    double? dailyPrice,
    String? status,
    String? imagePath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return ToolModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Whether this tool is available for rent/lend
  bool get isAvailable => status == 'available';

  /// Whether this tool is intended for rental (has a price)
  bool get isRental => dailyPrice > 0;

  /// Arabic status text
  String get statusArabic {
    switch (status) {
      case 'available':
        return 'متوفر';
      case 'rented':
        return 'مؤجر';
      case 'lent':
        return 'معار';
      case 'maintenance':
        return 'قيد الصيانة';
      default:
        return 'غير معروف';
    }
  }

  /// All possible statuses
  static List<Map<String, String>> get allStatuses => [
    {'id': 'available', 'name': 'متوفر'},
    {'id': 'rented', 'name': 'مؤجر'},
    {'id': 'lent', 'name': 'معار'},
    {'id': 'maintenance', 'name': 'قيد الصيانة'},
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolModel &&
        other.id == id &&
        other.userId == userId &&
        other.categoryId == categoryId &&
        other.name == name &&
        other.dailyPrice == dailyPrice &&
        other.status == status;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      categoryId.hashCode ^
      name.hashCode ^
      dailyPrice.hashCode ^
      status.hashCode;
}
