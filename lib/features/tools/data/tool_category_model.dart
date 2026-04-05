/// Model for Tool Category data
class ToolCategoryModel {
  final int? id;
  final int userId;
  final String nameAr;
  final String nameEn;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;

  ToolCategoryModel({
    this.id,
    required this.userId,
    required this.nameAr,
    required this.nameEn,
    this.icon,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ToolCategoryModel.fromMap(Map<String, dynamic> map) {
    return ToolCategoryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      nameAr: (map['name_ar'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      icon: map['icon'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ToolCategoryModel copyWith({
    int? id,
    int? userId,
    String? nameAr,
    String? nameEn,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ToolCategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Default categories to seed
  static List<Map<String, String>> get defaultCategories => [
    {'name_ar': 'مفاتيح', 'name_en': 'Wrenches / Spanners', 'icon': '🔧'},
    {'name_ar': 'مفك براغي (كشفيتي)', 'name_en': 'Screwdrivers', 'icon': '🪛'},
    {'name_ar': 'بينسة (كلّاب)', 'name_en': 'Pliers', 'icon': '🔨'},
    {'name_ar': 'عدة جيدور', 'name_en': 'Socket Set', 'icon': '🧰'},
    {'name_ar': 'هلتي وترابنو', 'name_en': 'Rotary Hammer & Drill', 'icon': '🔩'},
    {'name_ar': 'معدات كهربائية', 'name_en': 'Power Tools', 'icon': '⚡'},
    {'name_ar': 'معدات متخصصة', 'name_en': 'Specialized Tools', 'icon': '🛠️'},
    {'name_ar': 'معدات قياس', 'name_en': 'Measuring Tools', 'icon': '📏'},
    {'name_ar': 'معدات سلامة', 'name_en': 'Safety Equipment', 'icon': '🦺'},
    {'name_ar': 'ملحقات', 'name_en': 'Accessories / Attachments', 'icon': '🔗'},
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCategoryModel &&
        other.id == id &&
        other.userId == userId &&
        other.nameAr == nameAr &&
        other.nameEn == nameEn;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ nameAr.hashCode ^ nameEn.hashCode;
}
