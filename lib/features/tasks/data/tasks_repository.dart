import 'package:connectivity_plus/connectivity_plus.dart';
import 'task_local_model.dart';
import 'tasks_local_dao.dart';

/// Repository pattern: Unified interface for tasks data
/// Handles offline-first logic with online sync capability
class TasksRepository {
  final TasksLocalDao _localDao;
  final Connectivity _connectivity;

  TasksRepository({
    TasksLocalDao? localDao,
    Connectivity? connectivity,
  })  : _localDao = localDao ?? TasksLocalDao(),
        _connectivity = connectivity ?? Connectivity();

  // ========== CREATE ==========

  /// Create a new task (offline-first)
  Future<TaskLocalModel> createTask(TaskLocalModel task) async {
    final taskWithId = await _localDao.insert(task);
    return taskWithId;
  }

  // ========== READ ==========

  /// Get all tasks for a user
  Future<List<TaskLocalModel>> getAllTasks(int userId) async {
    return await _localDao.getAllTasks(userId: userId);
  }

  /// Get tasks by status
  Future<List<TaskLocalModel>> getTasksByStatus(
    int userId,
    String status,
  ) async {
    return await _localDao.getTasksByStatus(userId: userId, status: status);
  }

  /// Get pending tasks (not completed)
  Future<List<TaskLocalModel>> getPendingTasks(int userId) async {
    return await _localDao.getTasksByStatus(userId: userId, status: 'pending');
  }

  /// Get completed tasks
  Future<List<TaskLocalModel>> getCompletedTasks(int userId) async {
    return await _localDao.getTasksByStatus(userId: userId, status: 'completed');
  }

  /// Get overdue tasks
  Future<List<TaskLocalModel>> getOverdueTasks(int userId) async {
    return await _localDao.getOverdueTasks(userId);
  }

  /// Get today's tasks
  Future<List<TaskLocalModel>> getTodayTasks(int userId) async {
    return await _localDao.getTodayTasks(userId);
  }

  /// Get single task by ID
  Future<TaskLocalModel?> getTaskById(int id) async {
    return await _localDao.getTaskById(id);
  }

  /// Search tasks by query
  Future<List<TaskLocalModel>> searchTasks(int userId, String query) async {
    return await _localDao.searchTasks(userId: userId, query: query);
  }

  /// Get tasks statistics
  Future<Map<String, int>> getTasksStats(int userId) async {
    return await _localDao.getTasksCount(userId);
  }

  // ========== UPDATE ==========

  /// Update an existing task
  Future<bool> updateTask(TaskLocalModel task) async {
    final updated = task.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );
    final rowsAffected = await _localDao.update(updated);
    return rowsAffected > 0;
  }

  /// Mark task as completed
  Future<bool> completeTask(int taskId, int userId) async {
    final rowsAffected = await _localDao.markAsCompleted(taskId, userId);
    return rowsAffected > 0;
  }

  /// Change task status
  Future<bool> changeTaskStatus(int taskId, String status) async {
    final task = await _localDao.getTaskById(taskId);
    if (task == null) return false;

    final updated = task.copyWith(
      status: status,
      completedAt: status == 'completed' ? DateTime.now() : null,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    final rowsAffected = await _localDao.update(updated);
    return rowsAffected > 0;
  }

  // ========== DELETE ==========

  /// Soft delete task
  Future<bool> deleteTask(int taskId) async {
    final rowsAffected = await _localDao.delete(taskId);
    return rowsAffected > 0;
  }

  /// Permanent delete
  Future<bool> permanentDeleteTask(int taskId) async {
    final rowsAffected = await _localDao.permanentDelete(taskId);
    return rowsAffected > 0;
  }

  // ========== SYNC ==========

  /// Get tasks pending sync
  Future<List<TaskLocalModel>> getPendingSyncTasks(int userId) async {
    return await _localDao.getPendingSyncTasks();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Sync with backend (to be implemented later)
  Future<void> syncTasks(int userId) async {
    final online = await isOnline();
    if (!online) {
      throw Exception('No internet connection');
    }

    // TODO: Implement sync logic in Phase 4
    // 1. Get pending sync tasks
    // 2. Send to backend
    // 3. Update local with server IDs
    // 4. Handle conflicts
  }
}
