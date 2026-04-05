import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tool_category_model.dart';
import '../data/tool_model.dart';
import '../data/tool_extension_model.dart';
import '../data/tool_transaction_model.dart';
import '../data/tools_repository.dart';
import '../../../core/providers/common_providers.dart';
import '../../income/providers/income_providers.dart';

// ========================================
// REPOSITORY PROVIDER
// ========================================

final toolsRepositoryProvider = Provider<ToolsRepository>((ref) {
  return ToolsRepository();
});

// ========================================
// CATEGORIES
// ========================================

final toolCategoriesProvider = FutureProvider<List<ToolCategoryModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(toolsRepositoryProvider).getCategories(userId);
});

final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

// ========================================
// TOOLS
// ========================================

final toolStatusFilterProvider = StateProvider<String>((ref) => 'all');

final toolsProvider = FutureProvider<List<ToolModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final status = ref.watch(toolStatusFilterProvider);
  
  return ref.watch(toolsRepositoryProvider).getTools(
    userId,
    categoryId: categoryId,
    status: status == 'all' ? null : status,
  );
});

final toolByIdProvider = FutureProvider.family<ToolModel?, int>((ref, toolId) async {
  return ref.watch(toolsRepositoryProvider).getToolById(toolId);
});

// ========================================
// EXTENSIONS
// ========================================

final toolExtensionsProvider = FutureProvider.family<List<ToolExtensionModel>, int>((ref, toolId) async {
  return ref.watch(toolsRepositoryProvider).getExtensions(toolId);
});

final availableExtensionsProvider = FutureProvider.family<List<ToolExtensionModel>, int>((ref, toolId) async {
  return ref.watch(toolsRepositoryProvider).getAvailableExtensions(toolId);
});

// ========================================
// TRANSACTIONS
// ========================================

final transactionStatusFilterProvider = StateProvider<String>((ref) => 'all');
final transactionStartDateProvider = StateProvider<DateTime?>((ref) => null);
final transactionEndDateProvider = StateProvider<DateTime?>((ref) => null);
final transactionPersonFilterProvider = StateProvider<int?>((ref) => null);
final transactionCategoryFilterProvider = StateProvider<int?>((ref) => null);

final transactionsProvider = FutureProvider<List<ToolTransactionModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final status = ref.watch(transactionStatusFilterProvider);
  final startDate = ref.watch(transactionStartDateProvider);
  final endDate = ref.watch(transactionEndDateProvider);
  final personId = ref.watch(transactionPersonFilterProvider);
  final categoryId = ref.watch(transactionCategoryFilterProvider);
  
  return ref.watch(toolsRepositoryProvider).getTransactions(
    userId,
    status: status == 'all' ? null : status,
    startDate: startDate,
    endDate: endDate,
    personId: personId,
    categoryId: categoryId,
  );
});

final toolTransactionsProvider = FutureProvider.family<List<ToolTransactionModel>, int>((ref, toolId) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(toolsRepositoryProvider).getTransactions(userId, toolId: toolId);
});

final activeTransactionProvider = FutureProvider.family<ToolTransactionModel?, int>((ref, toolId) async {
  return ref.watch(toolsRepositoryProvider).getActiveTransaction(toolId);
});

// ========================================
// SUMMARY & REPORTS
// ========================================

final toolsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(toolsRepositoryProvider).getToolsSummary(userId);
});

final mostRentedToolsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(toolsRepositoryProvider).getMostRentedTools(userId);
});

final filteredPeriodStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final status = ref.watch(transactionStatusFilterProvider);
  final startDate = ref.watch(transactionStartDateProvider);
  final endDate = ref.watch(transactionEndDateProvider);
  final personId = ref.watch(transactionPersonFilterProvider);
  final categoryId = ref.watch(transactionCategoryFilterProvider);
  
  return ref.watch(toolsRepositoryProvider).getFilteredPeriodStats(
    userId,
    status: status == 'all' ? null : status,
    startDate: startDate,
    endDate: endDate,
    personId: personId,
    categoryId: categoryId,
  );
});

// ========================================
// NOTIFIERS FOR MUTATIONS
// ========================================

class ToolsNotifier extends StateNotifier<AsyncValue<void>> {
  final ToolsRepository _repository;
  final Ref _ref;

  ToolsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addTool(ToolModel tool) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTool(tool);
      _ref.invalidate(toolsProvider);
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTool(ToolModel tool) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTool(tool);
      _ref.invalidate(toolsProvider);
      _ref.invalidate(toolByIdProvider(tool.id!));
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTool(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTool(id);
      _ref.invalidate(toolsProvider);
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final toolsNotifierProvider = StateNotifierProvider<ToolsNotifier, AsyncValue<void>>((ref) {
  return ToolsNotifier(ref.watch(toolsRepositoryProvider), ref);
});

class ExtensionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ToolsRepository _repository;
  final Ref _ref;

  ExtensionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addExtension(ToolExtensionModel extension) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addExtension(extension);
      _ref.invalidate(toolExtensionsProvider(extension.toolId));
      _ref.invalidate(availableExtensionsProvider(extension.toolId));
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateExtension(ToolExtensionModel extension) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateExtension(extension);
      _ref.invalidate(toolExtensionsProvider(extension.toolId));
      _ref.invalidate(availableExtensionsProvider(extension.toolId));
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteExtension(int id, int toolId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteExtension(id);
      _ref.invalidate(toolExtensionsProvider(toolId));
      _ref.invalidate(availableExtensionsProvider(toolId));
      _ref.invalidate(toolsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final extensionsNotifierProvider = StateNotifierProvider<ExtensionsNotifier, AsyncValue<void>>((ref) {
  return ExtensionsNotifier(ref.watch(toolsRepositoryProvider), ref);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ToolsRepository _repository;
  final Ref _ref;

  TransactionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<int> createTransaction(ToolTransactionModel transaction, List<int> extensionIds) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createTransaction(transaction, extensionIds);
      _invalidateAll(transaction.toolId);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> returnTool(int transactionId, int toolId,
      {double lateFee = 0, String? notes, bool isPaid = false, String paymentMethod = 'cash', int? bankAccountId}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.returnTool(transactionId,
          lateFee: lateFee, notes: notes, isPaid: isPaid, paymentMethod: paymentMethod, bankAccountId: bankAccountId);
      _invalidateAll(toolId);
      if (isPaid) {
        _ref.invalidate(incomeProvider);
        _ref.invalidate(totalIncomeProvider);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateAll(int toolId) {
    _ref.invalidate(toolsProvider);
    _ref.invalidate(toolByIdProvider(toolId));
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(toolTransactionsProvider(toolId));
    _ref.invalidate(activeTransactionProvider(toolId));
    _ref.invalidate(toolExtensionsProvider(toolId));
    _ref.invalidate(availableExtensionsProvider(toolId));
    _ref.invalidate(toolsSummaryProvider);
    _ref.invalidate(filteredPeriodStatsProvider);
  }
}

final transactionsNotifierProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<void>>((ref) {
  return TransactionsNotifier(ref.watch(toolsRepositoryProvider), ref);
});
