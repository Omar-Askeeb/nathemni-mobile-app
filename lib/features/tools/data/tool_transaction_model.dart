/// Model for Tool Transaction (Rent/Lend) data
class ToolTransactionModel {
  final int? id;
  final int userId;
  final int toolId;
  final int personId;
  final String transactionType; // rent, lend
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double dailyPrice;
  final double extensionsPrice;
  final int totalDays;
  final double subtotal;
  final double lateFee;
  final double totalAmount;
  final String status; // active, returned, overdue
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPaid;
  final String syncStatus;

  // Joined fields (not stored in DB)
  final String? toolName;
  final String? personName;
  final List<int>? selectedExtensionIds;

  ToolTransactionModel({
    this.id,
    required this.userId,
    required this.toolId,
    required this.personId,
    required this.transactionType,
    required this.startDate,
    required this.dueDate,
    this.returnDate,
    this.dailyPrice = 0,
    this.extensionsPrice = 0,
    this.totalDays = 0,
    this.subtotal = 0,
    this.lateFee = 0,
    this.totalAmount = 0,
    this.status = 'active',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
    this.isPaid = false,
    this.toolName,
    this.personName,
    this.selectedExtensionIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ToolTransactionModel.fromMap(Map<String, dynamic> map) {
    return ToolTransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      toolId: map['tool_id'] as int? ?? 0,
      personId: map['person_id'] as int? ?? 0,
      transactionType: (map['transaction_type'] as String?) ?? 'rent',
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      returnDate: map['return_date'] != null
          ? DateTime.parse(map['return_date'] as String)
          : null,
      dailyPrice: (map['daily_price'] as num?)?.toDouble() ?? 0,
      extensionsPrice: (map['extensions_price'] as num?)?.toDouble() ?? 0,
      totalDays: map['total_days'] as int? ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      lateFee: (map['late_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] as String?) ?? 'active',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      syncStatus: (map['sync_status'] as String?) ?? 'pending',
      isPaid: (map['is_paid'] as int? ?? 0) == 1,
      toolName: map['tool_name'] as String?,
      personName: map['person_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tool_id': toolId,
      'person_id': personId,
      'transaction_type': transactionType,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'daily_price': dailyPrice,
      'extensions_price': extensionsPrice,
      'total_days': totalDays,
      'subtotal': subtotal,
      'late_fee': lateFee,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  ToolTransactionModel copyWith({
    int? id,
    int? userId,
    int? toolId,
    int? personId,
    String? transactionType,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? returnDate,
    double? dailyPrice,
    double? extensionsPrice,
    int? totalDays,
    double? subtotal,
    double? lateFee,
    double? totalAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isPaid,
    String? toolName,
    String? personName,
    List<int>? selectedExtensionIds,
  }) {
    return ToolTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      toolId: toolId ?? this.toolId,
      personId: personId ?? this.personId,
      transactionType: transactionType ?? this.transactionType,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      extensionsPrice: extensionsPrice ?? this.extensionsPrice,
      totalDays: totalDays ?? this.totalDays,
      subtotal: subtotal ?? this.subtotal,
      lateFee: lateFee ?? this.lateFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isPaid: isPaid ?? this.isPaid,
      toolName: toolName ?? this.toolName,
      personName: personName ?? this.personName,
      selectedExtensionIds: selectedExtensionIds ?? this.selectedExtensionIds,
    );
  }

  /// Whether this is a rental transaction (paid)
  bool get isRental => transactionType == 'rent';

  /// Whether this is a lending transaction (free)
  bool get isLending => transactionType == 'lend';

  /// Whether this transaction is active
  bool get isActive => status == 'active';

  /// Whether this transaction is overdue
  bool get isOverdue {
    if (status == 'returned') return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Calculate days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Arabic transaction type
  String get transactionTypeArabic {
    return transactionType == 'rent' ? 'تأجير' : 'إعارة';
  }

  /// Arabic status text
  String get statusArabic {
    switch (status) {
      case 'active':
        return isOverdue ? 'متأخر' : 'نشط';
      case 'returned':
        return 'تم الإرجاع';
      case 'overdue':
        return 'متأخر';
      default:
        return 'غير معروف';
    }
  }

  /// Combined daily rate (tool + extensions)
  /// Note: extensionsPrice is currently ignored as it stores purchase cost, not rental price
  double get combinedDailyRate => dailyPrice;

  /// Effective days (current or total)
  int get effectiveDays {
    if (status == 'returned') return totalDays;
    
    final end = DateTime.now();
    final diff = end.difference(startDate).inDays;
    return diff < 1 ? 1 : diff; // Minimum 1 day
  }

  /// Current running total amount (for active transactions) or final amount (for returned)
  double get currentTotalAmount {
    if (status == 'returned') return totalAmount;
    
    // For active transactions, calculate based on current duration
    return (effectiveDays * combinedDailyRate) + lateFee;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolTransactionModel &&
        other.id == id &&
        other.toolId == toolId &&
        other.personId == personId &&
        other.isPaid == isPaid;
  }

  @override
  int get hashCode => id.hashCode ^ toolId.hashCode ^ personId.hashCode ^ isPaid.hashCode;
}
