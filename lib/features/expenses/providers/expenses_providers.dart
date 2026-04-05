import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_local_model.dart';
import '../data/expenses_repository.dart';
import '../../../core/providers/common_providers.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository();
});

// Filter states
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final selectedPaymentMethodFilterProvider = StateProvider<String?>((ref) => null);
final startDateFilterProvider = StateProvider<DateTime?>((ref) => null);
final endDateFilterProvider = StateProvider<DateTime?>((ref) => null);

// All expenses provider
final expensesProvider =
    FutureProvider.autoDispose<List<ExpenseLocalModel>>((ref) async {
  final repository = ref.watch(expensesRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);
  final paymentMethodFilter = ref.watch(selectedPaymentMethodFilterProvider);
  final startDate = ref.watch(startDateFilterProvider);
  final endDate = ref.watch(endDateFilterProvider);

  // Get all expenses and apply filters manually
  List<ExpenseLocalModel> expenses;
  
  if (startDate != null && endDate != null) {
    expenses = await repository.getExpensesByDateRange(userId, startDate, endDate);
  } else {
    expenses = await repository.getAllExpenses(userId);
  }

  // Apply category filter
  if (categoryFilter != null) {
    expenses = expenses.where((e) => e.categoryId == categoryFilter).toList();
  }

  // Apply payment method filter
  if (paymentMethodFilter != null) {
    expenses = expenses.where((e) => e.paymentMethod == paymentMethodFilter).toList();
  }

  return expenses;
});

// Total expenses provider
final totalExpensesProvider = FutureProvider.autoDispose<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  double total = 0.0;
  for (var expense in expenses) {
    total += expense.amount;
  }
  return total;
});

// Expenses by category summary
final expensesByCategoryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final Map<String, double> categoryTotals = {};

  for (var expense in expenses) {
    categoryTotals[expense.categoryId] =
        (categoryTotals[expense.categoryId] ?? 0.0) + expense.amount;
  }

  return categoryTotals;
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<ExpenseLocalModel>>> {
  final ExpensesRepository _repository;
  final int _userId;
  final Ref _ref;

  ExpensesNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.loading()) {
    Future.microtask(() => _loadExpenses());
  }

  void _invalidateProviders() {
    _ref.invalidate(expensesProvider);
    _ref.invalidate(totalExpensesProvider);
    _ref.invalidate(expensesByCategoryProvider);
  }

  Future<void> _loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAllExpenses(_userId);
      state = AsyncValue.data(expenses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExpense(ExpenseLocalModel expense) async {
    try {
      await _repository.addExpense(expense);
      _invalidateProviders();
      await _loadExpenses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addOrUpdateLinkedExpense(ExpenseLocalModel expense) async {
    if (expense.linkedTo == null || expense.linkedId == null) {
      return addExpense(expense);
    }

    try {
      final existing = await _repository.getExpenseByLinkedItem(
        expense.linkedTo!,
        expense.linkedId!,
      );

      if (existing != null) {
        await updateExpense(expense.copyWith(id: existing.id));
      } else {
        await addExpense(expense);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseLocalModel expense) async {
    try {
      await _repository.updateExpense(expense);
      _invalidateProviders();
      await _loadExpenses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      _invalidateProviders();
      await _loadExpenses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadExpenses();
  }
}

final expensesNotifierProvider = StateNotifierProvider<ExpensesNotifier,
    AsyncValue<List<ExpenseLocalModel>>>((ref) {
  final repository = ref.watch(expensesRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ExpensesNotifier(repository, userId, ref);
});
