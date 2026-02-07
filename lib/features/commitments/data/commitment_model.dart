import '../../people/data/person_model.dart';

/// Model for commitment/debt data
class CommitmentModel {
  final int? id;
  final int userId;
  final int personId;
  final String title;
  final String? description;
  final String type; // 'debt_to_me' (someone owes me), 'debt_from_me' (I owe someone)
  final DateTime? dueDate;
  final String status; // 'pending', 'partial', 'completed'
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  // Joined data
  final PersonModel? person;
  final double? paidAmount;

  CommitmentModel({
    this.id,
    required this.userId,
    required this.personId,
    required this.title,
    this.description,
    required this.type,
    this.dueDate,
    this.status = 'pending',
    required this.amount,
    this.currency = 'LYD',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
    this.person,
    this.paidAmount,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory CommitmentModel.fromMap(Map<String, dynamic> map, {PersonModel? person, double? paidAmount}) {
    return CommitmentModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      personId: map['person_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: map['type'] as String,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: map['status'] as String? ?? 'pending',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LYD',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      person: person,
      paidAmount: paidAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'person_id': personId,
      'title': title,
      'description': description,
      'type': type,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status,
      'amount': amount,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  CommitmentModel copyWith({
    int? id,
    int? userId,
    int? personId,
    String? title,
    String? description,
    String? type,
    DateTime? dueDate,
    String? status,
    double? amount,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    PersonModel? person,
    double? paidAmount,
  }) {
    return CommitmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personId: personId ?? this.personId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      person: person ?? this.person,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  double get remainingAmount => amount - (paidAmount ?? 0);
  bool get isFullyPaid => remainingAmount <= 0;
  double get progressPercentage => amount > 0 ? ((paidAmount ?? 0) / amount) * 100 : 0;

  String get typeArabic {
    switch (type) {
      case 'debt_to_me':
        return 'دين لي';
      case 'debt_from_me':
        return 'دين علي';
      default:
        return type;
    }
  }

  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'partial':
        return 'مدفوع جزئياً';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CommitmentModel &&
        other.id == id &&
        other.userId == userId &&
        other.personId == personId &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.dueDate == dueDate &&
        other.status == status &&
        other.amount == amount &&
        other.currency == currency &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        personId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        type.hashCode ^
        dueDate.hashCode ^
        status.hashCode ^
        amount.hashCode ^
        currency.hashCode ^
        syncStatus.hashCode;
  }
}

/// Model for debt payment
class DebtPaymentModel {
  final int? id;
  final int commitmentId;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  DebtPaymentModel({
    this.id,
    required this.commitmentId,
    required this.amount,
    this.currency = 'LYD',
    required this.paymentDate,
    this.paymentMethod = 'cash',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtPaymentModel(
      id: map['id'] as int?,
      commitmentId: map['commitment_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'LYD',
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
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
      'commitment_id': commitmentId,
      'amount': amount,
      'currency': currency,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  String get paymentMethodArabic {
    switch (paymentMethod) {
      case 'cash':
        return 'نقداً';
      case 'card':
        return 'بطاقة';
      case 'transfer':
        return 'تحويل';
      default:
        return paymentMethod;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DebtPaymentModel &&
        other.id == id &&
        other.commitmentId == commitmentId &&
        other.amount == amount &&
        other.currency == currency &&
        other.paymentDate == paymentDate &&
        other.paymentMethod == paymentMethod &&
        other.notes == notes &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        commitmentId.hashCode ^
        amount.hashCode ^
        currency.hashCode ^
        paymentDate.hashCode ^
        paymentMethod.hashCode ^
        notes.hashCode ^
        syncStatus.hashCode;
  }
}
