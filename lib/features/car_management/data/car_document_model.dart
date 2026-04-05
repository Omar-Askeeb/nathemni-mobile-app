import 'package:equatable/equatable.dart';

enum CarDocumentType {
  insurance,
  tax,
  inspection;

  String get nameAr {
    switch (this) {
      case CarDocumentType.insurance:
        return 'التأمين الإجباري';
      case CarDocumentType.tax:
        return 'البل (ضريبة الطريق)';
      case CarDocumentType.inspection:
        return 'الفحص الفني';
    }
  }

  String get nameEn {
    switch (this) {
      case CarDocumentType.insurance:
        return 'Insurance';
      case CarDocumentType.tax:
        return 'Road Tax';
      case CarDocumentType.inspection:
        return 'Technical Inspection';
    }
  }

  static CarDocumentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'insurance':
        return CarDocumentType.insurance;
      case 'tax':
        return CarDocumentType.tax;
      case 'inspection':
        return CarDocumentType.inspection;
      default:
        return CarDocumentType.insurance;
    }
  }
}

class CarDocument extends Equatable {
  final int id;
  final int carId;
  final int userId;
  final CarDocumentType documentType;
  final DateTime renewalDate;
  final DateTime expiryDate;
  final double cost;
  final String currency;
  final String? placeName;
  final String? placeContact;
  final String paymentMethod;
  final int? notificationId;
  final String? notes;
  final bool isSynced;
  final String? syncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const CarDocument({
    required this.id,
    required this.carId,
    required this.userId,
    required this.documentType,
    required this.renewalDate,
    required this.expiryDate,
    required this.cost,
    this.currency = 'LYD',
    this.placeName,
    this.placeContact,
    this.paymentMethod = 'cash',
    this.notificationId,
    this.notes,
    this.isSynced = false,
    this.syncId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CarDocument.fromJson(Map<String, dynamic> json) {
    return CarDocument(
      id: json['id'] as int,
      carId: json['car_id'] as int,
      userId: json['user_id'] as int,
      documentType: CarDocumentType.fromString(json['document_type'] as String),
      renewalDate: DateTime.parse(json['renewal_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      cost: (json['cost'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'LYD',
      placeName: json['place_name'] as String?,
      placeContact: json['place_contact'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notificationId: json['notification_id'] as int?,
      notes: json['notes'] as String?,
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      'user_id': userId,
      'document_type': documentType.name,
      'renewal_date': renewalDate.toIso8601String().split('T')[0],
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'cost': cost,
      'currency': currency,
      if (placeName != null) 'place_name': placeName,
      if (placeContact != null) 'place_contact': placeContact,
      'payment_method': paymentMethod,
      if (notificationId != null) 'notification_id': notificationId,
      if (notes != null) 'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      if (syncId != null) 'sync_id': syncId,
    };
  }

  CarDocument copyWith({
    int? id,
    int? carId,
    int? userId,
    CarDocumentType? documentType,
    DateTime? renewalDate,
    DateTime? expiryDate,
    double? cost,
    String? currency,
    String? placeName,
    String? placeContact,
    String? paymentMethod,
    int? notificationId,
    String? notes,
    bool? isSynced,
    String? syncId,
  }) {
    return CarDocument(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      renewalDate: renewalDate ?? this.renewalDate,
      expiryDate: expiryDate ?? this.expiryDate,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      placeName: placeName ?? this.placeName,
      placeContact: placeContact ?? this.placeContact,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notificationId: notificationId ?? this.notificationId,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
    );
  }

  /// Returns true if document expires within the next 15 days
  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 15 && daysUntilExpiry >= 0;
  }

  /// Returns true if document has already expired
  bool get isExpired {
    return expiryDate.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        carId,
        userId,
        documentType,
        renewalDate,
        expiryDate,
        cost,
        currency,
        placeName,
        placeContact,
        paymentMethod,
        notificationId,
        notes,
        isSynced,
        syncId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
