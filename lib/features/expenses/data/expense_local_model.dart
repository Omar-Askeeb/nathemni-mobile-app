/// Model for expense data
class ExpenseLocalModel {
  final int? id;
  final int userId;
  final String categoryId;
  final double amount;
  final String currency;
  final String paymentMethod; // 'cash' or 'card'
  final int? bankAccountId;
  final DateTime expenseDate;
  final String? notes;
  final String? linkedTo; // 'task' for shopping tasks
  final int? linkedId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  ExpenseLocalModel({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.currency = 'LYD',
    this.paymentMethod = 'cash',
    this.bankAccountId,
    required this.expenseDate,
    this.notes,
    this.linkedTo,
    this.linkedId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ExpenseLocalModel.fromMap(Map<String, dynamic> map) {
    return ExpenseLocalModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'LYD',
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      bankAccountId: map['bank_account_id'] as int?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      notes: map['notes'] as String?,
      linkedTo: map['linked_to'] as String?,
      linkedId: map['linked_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'bank_account_id': bankAccountId,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'notes': notes,
      'linked_to': linkedTo,
      'linked_id': linkedId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  ExpenseLocalModel copyWith({
    int? id,
    int? userId,
    String? categoryId,
    double? amount,
    String? currency,
    String? paymentMethod,
    int? bankAccountId,
    DateTime? expenseDate,
    String? notes,
    String? linkedTo,
    int? linkedId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return ExpenseLocalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      linkedTo: linkedTo ?? this.linkedTo,
      linkedId: linkedId ?? this.linkedId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// Expense category information
class ExpenseCategoryInfo {
  final String id;
  final String nameArabic;
  final String icon;
  final String color;

  const ExpenseCategoryInfo({
    required this.id,
    required this.nameArabic,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategoryInfo> allCategories = [
    ExpenseCategoryInfo(
      id: 'vegetables_fruits',
      nameArabic: 'خضروات وفواكه',
      icon: '🥗',
      color: '#4CAF50',
    ),
    ExpenseCategoryInfo(
      id: 'pharmacy',
      nameArabic: 'صيدلية',
      icon: '🩺',
      color: '#F44336',
    ),
    ExpenseCategoryInfo(
      id: 'groceries',
      nameArabic: 'مواد غذائية',
      icon: '🍞',
      color: '#FF9800',
    ),
    ExpenseCategoryInfo(
      id: 'fuel',
      nameArabic: 'وقود',
      icon: '⛽',
      color: '#9C27B0',
    ),
    ExpenseCategoryInfo(
      id: 'balance_subscriptions',
      nameArabic: 'رصيد واشتراكات',
      icon: '💳',
      color: '#2196F3',
    ),
    ExpenseCategoryInfo(
      id: 'home_furniture',
      nameArabic: 'مواد منزلية وأثاث',
      icon: '🛋️',
      color: '#795548',
    ),
    ExpenseCategoryInfo(
      id: 'cleaning',
      nameArabic: 'مواد تنظيف',
      icon: '🧽',
      color: '#00BCD4',
    ),
    ExpenseCategoryInfo(
      id: 'perfumes',
      nameArabic: 'عطرية',
      icon: '🌸',
      color: '#E91E63',
    ),
    ExpenseCategoryInfo(
      id: 'butcher_meat',
      nameArabic: 'قصاب ولحوم',
      icon: '🥩',
      color: '#D32F2F',
    ),
    ExpenseCategoryInfo(
      id: 'kitchen_supplies',
      nameArabic: 'لوازم مطبخ',
      icon: '🍴',
      color: '#FFC107',
    ),
    ExpenseCategoryInfo(
      id: 'other',
      nameArabic: 'أخرى',
      icon: '📋',
      color: '#607D8B',
    ),
  ];

  static ExpenseCategoryInfo? fromId(String id) {
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Payment method information
class PaymentMethodInfo {
  final String id;
  final String nameArabic;
  final String icon;

  const PaymentMethodInfo({
    required this.id,
    required this.nameArabic,
    required this.icon,
  });

  static const List<PaymentMethodInfo> allMethods = [
    PaymentMethodInfo(
      id: 'cash',
      nameArabic: 'كاش',
      icon: '💵',
    ),
    PaymentMethodInfo(
      id: 'card',
      nameArabic: 'بطاقة',
      icon: '💳',
    ),
  ];

  static PaymentMethodInfo? fromId(String id) {
    try {
      return allMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }
}
