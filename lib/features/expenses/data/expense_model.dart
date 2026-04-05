import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int id;
  final int userId;
  final int categoryId;
  final int? paymentMethodId;
  final double amount;
  final String currency;
  final String? description;
  final String? notes;
  final DateTime expenseDate;
  final bool isSynced;
  final String? syncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Relationships
  final ExpenseCategory? category;
  final PaymentMethod? paymentMethod;

  const Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.paymentMethodId,
    required this.amount,
    this.currency = 'LYD',
    this.description,
    this.notes,
    required this.expenseDate,
    this.isSynced = false,
    this.syncId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.category,
    this.paymentMethod,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      paymentMethodId: json['payment_method_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'LYD',
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      isSynced: json['is_synced'] as bool? ?? false,
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
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromJson(json['payment_method'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      'amount': amount,
      'currency': currency,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'is_synced': isSynced,
      if (syncId != null) 'sync_id': syncId,
    };
  }

  Expense copyWith({
    int? id,
    int? userId,
    int? categoryId,
    int? paymentMethodId,
    double? amount,
    String? currency,
    String? description,
    String? notes,
    DateTime? expenseDate,
    bool? isSynced,
    String? syncId,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      expenseDate: expenseDate ?? this.expenseDate,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        paymentMethodId,
        amount,
        currency,
        description,
        notes,
        expenseDate,
        isSynced,
        syncId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

class ExpenseCategory {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? icon;
  final String? color;

  const ExpenseCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
    this.color,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;
}

class PaymentMethod {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? type;
  final String? icon;

  const PaymentMethod({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.type,
    this.icon,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      type: json['type'] as String?,
      icon: json['icon'] as String?,
    );
  }

  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;
}

class ExpenseSummary {
  final double total;
  final List<CategoryExpenseTotal> byCategory;

  const ExpenseSummary({
    required this.total,
    required this.byCategory,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      total: (json['total'] as num).toDouble(),
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategoryExpenseTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryExpenseTotal {
  final int categoryId;
  final double total;
  final ExpenseCategory? category;

  const CategoryExpenseTotal({
    required this.categoryId,
    required this.total,
    this.category,
  });

  factory CategoryExpenseTotal.fromJson(Map<String, dynamic> json) {
    return CategoryExpenseTotal(
      categoryId: json['category_id'] as int,
      total: (json['total'] as num).toDouble(),
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}
