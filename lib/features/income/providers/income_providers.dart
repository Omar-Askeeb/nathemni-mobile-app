import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/income_model.dart';
import '../data/income_repository.dart';
import '../../../core/providers/common_providers.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository();
});

// Filters
final incomeStartDateProvider = StateProvider<DateTime?>((ref) => null);
final incomeEndDateProvider = StateProvider<DateTime?>((ref) => null);
final incomeSourceTypeFilterProvider = StateProvider<String>((ref) => 'all');
final incomePaymentMethodFilterProvider = StateProvider<String>((ref) => 'all');
final incomeBankAccountIdFilterProvider = StateProvider<int?>((ref) => null);

final incomeProvider = FutureProvider<List<IncomeModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final startDate = ref.watch(incomeStartDateProvider);
  final endDate = ref.watch(incomeEndDateProvider);
  final sourceType = ref.watch(incomeSourceTypeFilterProvider);
  final paymentMethod = ref.watch(incomePaymentMethodFilterProvider);
  final bankAccountId = ref.watch(incomeBankAccountIdFilterProvider);

  return ref.watch(incomeRepositoryProvider).getIncomes(
        userId,
        startDate: startDate,
        endDate: endDate,
        sourceType: sourceType,
        paymentMethod: paymentMethod,
        bankAccountId: bankAccountId,
      );
});

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final startDate = ref.watch(incomeStartDateProvider);
  final endDate = ref.watch(incomeEndDateProvider);
  final sourceType = ref.watch(incomeSourceTypeFilterProvider);
  final paymentMethod = ref.watch(incomePaymentMethodFilterProvider);
  final bankAccountId = ref.watch(incomeBankAccountIdFilterProvider);

  return ref.watch(incomeRepositoryProvider).getTotalIncome(
        userId,
        startDate: startDate,
        endDate: endDate,
        sourceType: sourceType,
        paymentMethod: paymentMethod,
        bankAccountId: bankAccountId,
      );
});

class IncomeNotifier extends StateNotifier<AsyncValue<void>> {
  final IncomeRepository _repository;
  final Ref _ref;

  IncomeNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addIncome(IncomeModel income) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addIncome(income);
      _ref.invalidate(incomeProvider);
      _ref.invalidate(totalIncomeProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateIncome(IncomeModel income) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateIncome(income);
      _ref.invalidate(incomeProvider);
      _ref.invalidate(totalIncomeProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteIncome(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteIncome(id);
      _ref.invalidate(incomeProvider);
      _ref.invalidate(totalIncomeProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final incomeNotifierProvider = StateNotifierProvider<IncomeNotifier, AsyncValue<void>>((ref) {
  return IncomeNotifier(ref.watch(incomeRepositoryProvider), ref);
});
