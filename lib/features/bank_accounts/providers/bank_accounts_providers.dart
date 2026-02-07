import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bank_account_model.dart';
import '../data/bank_accounts_repository.dart';

final bankAccountsRepositoryProvider = Provider<BankAccountsRepository>((ref) {
  return BankAccountsRepository();
});

final currentUserIdProvider = Provider<int>((ref) => 1);

final bankAccountsProvider =
    FutureProvider.autoDispose<List<BankAccountModel>>((ref) async {
  final repository = ref.watch(bankAccountsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getAllBankAccounts(userId);
});

class BankAccountsNotifier
    extends StateNotifier<AsyncValue<List<BankAccountModel>>> {
  final BankAccountsRepository _repository;
  final int _userId;

  BankAccountsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await _repository.getAllBankAccounts(_userId);
      state = AsyncValue.data(accounts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAccount(BankAccountModel account) async {
    try {
      await _repository.addBankAccount(account);
      await _loadAccounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAccount(BankAccountModel account) async {
    try {
      await _repository.updateBankAccount(account);
      await _loadAccounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _repository.deleteBankAccount(id);
      await _loadAccounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadAccounts();
  }
}

final bankAccountsNotifierProvider = StateNotifierProvider<
    BankAccountsNotifier, AsyncValue<List<BankAccountModel>>>((ref) {
  final repository = ref.watch(bankAccountsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return BankAccountsNotifier(repository, userId);
});
