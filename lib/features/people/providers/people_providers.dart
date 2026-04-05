import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/person_model.dart';
import '../../../core/providers/common_providers.dart';
import '../data/people_repository.dart';

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepository();
});

final peopleProvider = FutureProvider.autoDispose<List<PersonModel>>((ref) async {
  final repository = ref.watch(peopleRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getAllPeople(userId);
});

class PeopleNotifier extends StateNotifier<AsyncValue<List<PersonModel>>> {
  final PeopleRepository _repository;
  final int _userId;

  PeopleNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    state = const AsyncValue.loading();
    try {
      final people = await _repository.getAllPeople(_userId);
      state = AsyncValue.data(people);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPerson(PersonModel person) async {
    try {
      await _repository.addPerson(person);
      await _loadPeople();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePerson(PersonModel person) async {
    try {
      await _repository.updatePerson(person);
      await _loadPeople();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePerson(int id) async {
    try {
      await _repository.deletePerson(id);
      await _loadPeople();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadPeople();
  }
}

final peopleNotifierProvider = StateNotifierProvider<PeopleNotifier,
    AsyncValue<List<PersonModel>>>((ref) {
  final repository = ref.watch(peopleRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return PeopleNotifier(repository, userId);
});
