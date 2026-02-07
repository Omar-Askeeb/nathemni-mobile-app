import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sim_card_model.dart';
import '../data/sim_cards_repository.dart';

// Repository provider
final simCardsRepositoryProvider = Provider<SimCardsRepository>((ref) {
  return SimCardsRepository();
});

// Current user ID provider (hardcoded to 1 for now - will be replaced with auth)
final currentUserIdProvider = Provider<int>((ref) => 1);

// SIM cards provider - gets all SIM cards for current user
final simCardsProvider =
    FutureProvider.autoDispose<List<SimCardModel>>((ref) async {
  final repository = ref.watch(simCardsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getAllSimCards(userId);
});

// SIM cards by provider
final simCardsByProviderProvider = FutureProvider.autoDispose
    .family<List<SimCardModel>, String>((ref, provider) async {
  final repository = ref.watch(simCardsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getSimCardsByProvider(userId, provider);
});

// Search query state provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Filtered SIM cards (with search)
final filteredSimCardsProvider = FutureProvider.autoDispose
    .family<List<SimCardModel>, String>((ref, provider) async {
  final repository = ref.watch(simCardsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  if (searchQuery.isEmpty) {
    return repository.getSimCardsByProvider(userId, provider);
  } else {
    return repository.searchSimCards(userId, provider, searchQuery);
  }
});

// Statistics provider
final simCardsStatisticsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(simCardsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getStatistics(userId);
});

// Notifier for CRUD operations
class SimCardsNotifier extends StateNotifier<AsyncValue<List<SimCardModel>>> {
  final SimCardsRepository _repository;
  final int _userId;

  SimCardsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadSimCards();
  }

  Future<void> _loadSimCards() async {
    state = const AsyncValue.loading();
    try {
      final simCards = await _repository.getAllSimCards(_userId);
      state = AsyncValue.data(simCards);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSimCard(SimCardModel simCard) async {
    try {
      await _repository.addSimCard(simCard);
      await _loadSimCards();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSimCard(SimCardModel simCard) async {
    try {
      await _repository.updateSimCard(simCard);
      await _loadSimCards();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSimCard(int id) async {
    try {
      await _repository.deleteSimCard(id);
      await _loadSimCards();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadSimCards();
  }
}

// Provider for the notifier
final simCardsNotifierProvider =
    StateNotifierProvider<SimCardsNotifier, AsyncValue<List<SimCardModel>>>(
        (ref) {
  final repository = ref.watch(simCardsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return SimCardsNotifier(repository, userId);
});
