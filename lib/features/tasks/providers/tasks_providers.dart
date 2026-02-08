import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../data/task_local_model.dart';
import '../data/tasks_repository.dart';
import '../../../core/providers/common_providers.dart';

// ========== REPOSITORY PROVIDER ==========

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

// ========== TASKS LIST STATE ==========

/// State notifier for managing tasks list
class TasksNotifier extends StateNotifier<AsyncValue<List<TaskLocalModel>>> {
  final TasksRepository _repository;
  final Ref _ref;

  TasksNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    Future.microtask(() => loadTasks());
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    final userId = _ref.read(currentUserIdProvider);
    try {
      final tasks = await _repository.getAllTasks(userId);
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create new task
  Future<void> createTask(TaskLocalModel task) async {
    try {
      await _repository.createTask(task);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Update task
  Future<void> updateTask(TaskLocalModel task) async {
    try {
      await _repository.updateTask(task);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Complete task
  Future<void> completeTask(int taskId) async {
    final userId = _ref.read(currentUserIdProvider);
    try {
      await _repository.completeTask(taskId, userId);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(int taskId) async {
    try {
      // Delete linked expense if it exists
      final expensesRepository = ExpensesRepository();
      final existingExpense = await expensesRepository.getExpenseByLinkedItem('task', taskId);
      if (existingExpense != null) {
        await expensesRepository.deleteExpense(existingExpense.id!);
        _ref.invalidate(expensesProvider);
        _ref.invalidate(totalExpensesProvider);
        _ref.invalidate(expensesByCategoryProvider);
      }

      await _repository.deleteTask(taskId);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    final userId = _ref.read(currentUserIdProvider);
    if (query.isEmpty) {
      await loadTasks();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.searchTasks(userId, query);
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for tasks list
final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskLocalModel>>>(
  (ref) {
    final repository = ref.watch(tasksRepositoryProvider);
    return TasksNotifier(repository, ref);
  },
);

// Offline status provider
final isDeviceOnlineProvider = FutureProvider<bool>((ref) async => true);
