import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_local_model.dart';
import '../data/tasks_repository.dart';

// ========== REPOSITORY PROVIDER ==========

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

// ========== CURRENT USER ID PROVIDER (temporary for testing) ==========
// TODO: Replace with actual auth user ID from auth provider
final currentUserIdProvider = StateProvider<int>((ref) => 1);

// ========== TASKS LIST STATE ==========

/// State notifier for managing tasks list
class TasksNotifier extends StateNotifier<AsyncValue<List<TaskLocalModel>>> {
  final TasksRepository _repository;
  final int _userId;

  TasksNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadTasks();
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getAllTasks(_userId);
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
      // Handle error
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
    try {
      await _repository.completeTask(taskId, _userId);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(int taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks(); // Refresh list
    } catch (error) {
      rethrow;
    }
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    if (query.isEmpty) {
      await loadTasks();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.searchTasks(_userId, query);
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
    final userId = ref.watch(currentUserIdProvider);
    return TasksNotifier(repository, userId);
  },
);

// ========== FILTERED TASKS PROVIDERS ==========

/// Pending tasks only
final pendingTasksProvider = FutureProvider<List<TaskLocalModel>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getPendingTasks(userId);
});

/// Completed tasks only
final completedTasksProvider =
    FutureProvider<List<TaskLocalModel>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getCompletedTasks(userId);
});

/// Overdue tasks
final overdueTasksProvider = FutureProvider<List<TaskLocalModel>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getOverdueTasks(userId);
});

/// Today's tasks
final todayTasksProvider = FutureProvider<List<TaskLocalModel>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getTodayTasks(userId);
});

// ========== TASKS STATISTICS PROVIDER ==========

final tasksStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repository.getTasksStats(userId);
});

// ========== CONNECTIVITY PROVIDER ==========

final isOnlineProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  return repository.isOnline();
});
