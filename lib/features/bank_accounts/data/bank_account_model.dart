/// Model for bank account data
class BankAccountModel {
  final int? id;
  final int userId;
  final String bankId;
  final String? branch;
  final String accountNumber;
  final String? iban;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  BankAccountModel({
    this.id,
    required this.userId,
    required this.bankId,
    this.branch,
    required this.accountNumber,
    this.iban,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BankAccountModel.fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      bankId: map['bank_id'] as String,
      branch: map['branch'] as String?,
      accountNumber: map['account_number'] as String,
      iban: map['iban'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'bank_id': bankId,
      'branch': branch,
      'account_number': accountNumber,
      'iban': iban,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  BankAccountModel copyWith({
    int? id,
    int? userId,
    String? bankId,
    String? branch,
    String? accountNumber,
    String? iban,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankId: bankId ?? this.bankId,
      branch: branch ?? this.branch,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// Bank information
class BankInfo {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String logoPath;

  const BankInfo({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.logoPath,
  });

  static const List<BankInfo> allBanks = [
    BankInfo(
      id: 'libyan_islamic',
      nameArabic: 'المصرف الإسلامي الليبي',
      nameEnglish: 'Libyan Islamic Bank',
      logoPath: 'assets/images/bank_logos/libyan_islamic.png',
    ),
    BankInfo(
      id: 'tadhamun',
      nameArabic: 'المصرف التضامن',
      nameEnglish: 'Tadhamun Bank',
      logoPath: 'assets/images/bank_logos/tadhamun.png',
    ),
    BankInfo(
      id: 'libyan_foreign',
      nameArabic: 'المصرف الليبي الخارجي',
      nameEnglish: 'Libyan Foreign Bank',
      logoPath: 'assets/images/bank_logos/libyan_foreign.png',
    ),
    BankInfo(
      id: 'aman',
      nameArabic: 'مصرف الأمان',
      nameEnglish: 'Aman Bank',
      logoPath: 'assets/images/bank_logos/aman.png',
    ),
    BankInfo(
      id: 'andalus',
      nameArabic: 'مصرف الأندلس',
      nameEnglish: 'Andalus Bank',
      logoPath: 'assets/images/bank_logos/andalus.png',
    ),
    BankInfo(
      id: 'arab_islamic_investment',
      nameArabic: 'مصرف الإستثمار العربي الإسلامي',
      nameEnglish: 'Arab Islamic Investment Bank',
      logoPath: 'assets/images/bank_logos/arab_islamic_investment.png',
    ),
    BankInfo(
      id: 'national_unio',
      nameArabic: 'مصرف الاتحاد الوطني',
      nameEnglish: 'National Unio Bank',
      logoPath: 'assets/images/bank_logos/national_unio.png',
    ),
    BankInfo(
      id: 'commerce_development',
      nameArabic: 'مصرف التجارة والتنمية',
      nameEnglish: 'Bank of Commerce & Development',
      logoPath: 'assets/images/bank_logos/commerce_development.png',
    ),
    BankInfo(
      id: 'national_commercial',
      nameArabic: 'مصرف التجاري الوطني',
      nameEnglish: 'National Commercial Bank',
      logoPath: 'assets/images/bank_logos/national_commercial.png',
    ),
    BankInfo(
      id: 'islamic_finance',
      nameArabic: 'مصرف التمويل الاسلامي',
      nameEnglish: 'Islamic Finance Bank',
      logoPath: 'assets/images/bank_logos/islamic_finance.png',
    ),
    BankInfo(
      id: 'development',
      nameArabic: 'مصرف التنمية',
      nameEnglish: 'Development Bank',
      logoPath: 'assets/images/bank_logos/development.png',
    ),
    BankInfo(
      id: 'jumhouria',
      nameArabic: 'مصرف الجمهورية',
      nameEnglish: 'Jumhouria Bank',
      logoPath: 'assets/images/bank_logos/jumhouria.png',
    ),
    BankInfo(
      id: 'first_gulf',
      nameArabic: 'مصرف الخليج الأول',
      nameEnglish: 'First Gulf Libyan Bank',
      logoPath: 'assets/images/bank_logos/first_gulf.png',
    ),
    BankInfo(
      id: 'alseraj_islamic',
      nameArabic: 'مصرف السراج الاسلامي',
      nameEnglish: 'Alseraj Islamic Bank',
      logoPath: 'assets/images/bank_logos/alseraj_islamic.png',
    ),
    BankInfo(
      id: 'assaray',
      nameArabic: 'مصرف السراي',
      nameEnglish: 'Assaray Bank',
      logoPath: 'assets/images/bank_logos/assaray.png',
    ),
    BankInfo(
      id: 'sahara',
      nameArabic: 'مصرف الصحارى',
      nameEnglish: 'Sahara Bank',
      logoPath: 'assets/images/bank_logos/sahara.png',
    ),
    BankInfo(
      id: 'daman_islamic',
      nameArabic: 'مصرف الضمان الاسلامي',
      nameEnglish: 'Daman Islamic Bank',
      logoPath: 'assets/images/bank_logos/daman_islamic.png',
    ),
    BankInfo(
      id: 'ubci',
      nameArabic: 'مصرف المتحد',
      nameEnglish: 'UBCI Bank',
      logoPath: 'assets/images/bank_logos/ubci.png',
    ),
    BankInfo(
      id: 'meditbank',
      nameArabic: 'مصرف المتوسط',
      nameEnglish: 'Meditbank Bank',
      logoPath: 'assets/images/bank_logos/meditbank.png',
    ),
    BankInfo(
      id: 'nuran',
      nameArabic: 'مصرف النوران',
      nameEnglish: 'Nuran Bank',
      logoPath: 'assets/images/bank_logos/nuran.png',
    ),
    BankInfo(
      id: 'waha',
      nameArabic: 'مصرف الواحة',
      nameEnglish: 'Waha Bank',
      logoPath: 'assets/images/bank_logos/waha.png',
    ),
    BankInfo(
      id: 'wehda',
      nameArabic: 'مصرف الوحدة',
      nameEnglish: 'Wehda Bank',
      logoPath: 'assets/images/bank_logos/wehda.png',
    ),
    BankInfo(
      id: 'alwafa',
      nameArabic: 'مصرف الوفاء',
      nameEnglish: 'Alwafa Bank',
      logoPath: 'assets/images/bank_logos/alwafa.png',
    ),
    BankInfo(
      id: 'yaqeen',
      nameArabic: 'مصرف اليقين',
      nameEnglish: 'Yaqeen Bank',
      logoPath: 'assets/images/bank_logos/yaqeen.png',
    ),
    BankInfo(
      id: 'north_africa',
      nameArabic: 'مصرف شمال أفريقيا',
      nameEnglish: 'North Africa Bank',
      logoPath: 'assets/images/bank_logos/north_africa.png',
    ),
  ];

  static BankInfo? fromId(String id) {
    try {
      return allBanks.firstWhere((bank) => bank.id == id);
    } catch (e) {
      return null;
    }
  }
}
