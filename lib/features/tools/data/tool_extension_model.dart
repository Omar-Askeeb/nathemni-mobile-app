/// Model for Tool Extension/Attachment data
class ToolExtensionModel {
  final int? id;
  final int toolId;
  final String name;
  final double cost; // Purchase cost
  final String status; // available, rented
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ToolExtensionModel({
    this.id,
    required this.toolId,
    required this.name,
    this.cost = 0,
    this.status = 'available',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ToolExtensionModel.fromMap(Map<String, dynamic> map) {
    return ToolExtensionModel(
      id: map['id'] as int?,
      toolId: map['tool_id'] as int,
      name: map['name'] as String,
      // Support both 'cost' and legacy 'daily_price' columns
      cost: (map['cost'] as num?)?.toDouble() ?? 
            (map['daily_price'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'available',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tool_id': toolId,
      'name': name,
      'cost': cost,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ToolExtensionModel copyWith({
    int? id,
    int? toolId,
    String? name,
    double? cost,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ToolExtensionModel(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this extension is available
  bool get isAvailable => status == 'available';

  /// Arabic status text
  String get statusArabic {
    switch (status) {
      case 'available':
        return 'متوفر';
      case 'rented':
        return 'مستخدم';
      default:
        return 'غير معروف';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolExtensionModel &&
        other.id == id &&
        other.toolId == toolId &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ toolId.hashCode ^ name.hashCode;
}
