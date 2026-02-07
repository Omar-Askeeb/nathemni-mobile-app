import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/commitment_model.dart';
import '../data/commitments_repository.dart';

final commitmentsRepositoryProvider = Provider<CommitmentsRepository>((ref) {
  return CommitmentsRepository();
});

final currentUserIdProvider = Provider<int>((ref) => 1);

// All commitments provider
final commitmentsProvider = FutureProvider.autoDispose<List<CommitmentModel>>((ref) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getAllCommitments(userId);
});

// Debts owed to me (others owe me)
final debtsToMeProvider = FutureProvider.autoDispose<List<CommitmentModel>>((ref) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getCommitmentsByType(userId, 'debt_to_me');
});

// Debts I owe to others
final debtsFromMeProvider = FutureProvider.autoDispose<List<CommitmentModel>>((ref) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getCommitmentsByType(userId, 'debt_from_me');
});

// Totals
final totalDebtToMeProvider = FutureProvider.autoDispose<double>((ref) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getTotalDebtToMe(userId);
});

final totalDebtFromMeProvider = FutureProvider.autoDispose<double>((ref) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getTotalDebtFromMe(userId);
});

// Payments for a specific commitment
final paymentsProvider = FutureProvider.autoDispose.family<List<DebtPaymentModel>, int>((ref, commitmentId) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  return repository.getPaymentsForCommitment(commitmentId);
});

// Single commitment provider
final commitmentProvider = FutureProvider.autoDispose.family<CommitmentModel?, int>((ref, id) async {
  final repository = ref.watch(commitmentsRepositoryProvider);
  return repository.getCommitmentById(id);
});

class CommitmentsNotifier extends StateNotifier<AsyncValue<List<CommitmentModel>>> {
  final CommitmentsRepository _repository;
  final int _userId;

  CommitmentsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadCommitments();
  }

  Future<void> _loadCommitments() async {
    state = const AsyncValue.loading();
    try {
      final commitments = await _repository.getAllCommitments(_userId);
      state = AsyncValue.data(commitments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCommitment(CommitmentModel commitment) async {
    try {
      await _repository.addCommitment(commitment);
      await _loadCommitments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCommitment(CommitmentModel commitment) async {
    try {
      await _repository.updateCommitment(commitment);
      await _loadCommitments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCommitment(int id) async {
    try {
      await _repository.deleteCommitment(id);
      await _loadCommitments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPayment(DebtPaymentModel payment) async {
    try {
      await _repository.addPayment(payment);
      await _loadCommitments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePayment(int paymentId, int commitmentId) async {
    try {
      await _repository.deletePayment(paymentId, commitmentId);
      await _loadCommitments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadCommitments();
  }
}

final commitmentsNotifierProvider = StateNotifierProvider<CommitmentsNotifier,
    AsyncValue<List<CommitmentModel>>>((ref) {
  final repository = ref.watch(commitmentsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return CommitmentsNotifier(repository, userId);
});
