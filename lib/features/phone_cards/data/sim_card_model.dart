/// Model for SIM card data
class SimCardModel {
  final int? id;
  final int userId;
  final String simNumber;
  final String provider; // 'libyana', 'almadar', 'ltt'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // 'synced', 'pending', 'failed'

  SimCardModel({
    this.id,
    required this.userId,
    required this.simNumber,
    required this.provider,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create from database map
  factory SimCardModel.fromMap(Map<String, dynamic> map) {
    return SimCardModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      simNumber: map['sim_number'] as String,
      provider: map['provider'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sim_number': simNumber,
      'provider': provider,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  // Copy with
  SimCardModel copyWith({
    int? id,
    int? userId,
    String? simNumber,
    String? provider,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return SimCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      simNumber: simNumber ?? this.simNumber,
      provider: provider ?? this.provider,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Format SIM number for display (e.g., 091-234-5678)
  String get formattedNumber {
    if (simNumber.length == 10) {
      return '${simNumber.substring(0, 3)}-${simNumber.substring(3, 6)}-${simNumber.substring(6)}';
    }
    return simNumber;
  }
}

/// Provider information
class ProviderInfo {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String colorHex;

  const ProviderInfo({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.colorHex,
  });

  static const libyana = ProviderInfo(
    id: 'libyana',
    nameArabic: 'ليبيانا',
    nameEnglish: 'Libyana',
    colorHex: '#A01594', // Purple
  );

  static const almadar = ProviderInfo(
    id: 'almadar',
    nameArabic: 'المدار الجديد',
    nameEnglish: 'Al Madar',
    colorHex: '#81b12a', // Green
  );

  static const ltt = ProviderInfo(
    id: 'ltt',
    nameArabic: 'ليبيا للاتصالات والتقنية',
    nameEnglish: 'LTT',
    colorHex: '#FF9900', // Orange
  );

  static List<ProviderInfo> get all => [libyana, almadar, ltt];

  static ProviderInfo? fromId(String id) {
    return all.firstWhere((p) => p.id == id);
  }
}
