/// Model for Income data
class IncomeModel {
  final int? id;
  final int userId;
  final double amount;
  final String sourceType; // tool_rental, salary, business, other
  final int? sourceId;
  final DateTime entryDate;
  final String? description;
  final DateTime createdAt;
  final String syncStatus;

  IncomeModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.sourceType,
    this.sourceId,
    required this.entryDate,
    this.description,
    DateTime? createdAt,
    this.syncStatus = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as int?,
      entryDate: DateTime.parse(map['entry_date'] as String),
      description: map['description'] as String?,
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
      'amount': amount,
      'source_type': sourceType,
      'source_id': sourceId,
      'entry_date': entryDate.toIso8601String(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  IncomeModel copyWith({
    int? id,
    int? userId,
    double? amount,
    String? sourceType,
    int? sourceId,
    DateTime? entryDate,
    String? description,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  String get sourceTypeArabic {
    switch (sourceType) {
      case 'tool_rental':
        return 'إيجار معدات';
      case 'salary':
        return 'راتب';
      case 'business':
        return 'عمل خاص';
      default:
        return 'أخرى';
    }
  }
}
