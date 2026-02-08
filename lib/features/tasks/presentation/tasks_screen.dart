import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tasks_providers.dart';
import '../data/task_local_model.dart';
import '../data/checklist_item_model.dart';
import 'add_task_screen.dart';
import 'task_details_screen.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/utils/arabic_numbers.dart';

// Filter state provider
final taskFilterProvider = StateProvider<String>((ref) => 'all');

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final isDeviceOnline = ref.watch(isDeviceOnlineProvider);
    final currentFilter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام والتنظيم اليومي'),
        centerTitle: true,
        actions: const [],
      ),
      drawer: const AppDrawer(),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(context);
          }
          // Apply filter
          final filteredTasks = _filterTasks(tasks, currentFilter);
          return _buildTasksList(context, ref, tasks, filteredTasks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<TaskLocalModel> _filterTasks(List<TaskLocalModel> tasks, String filter) {
    switch (filter) {
      case 'pending':
        return tasks.where((t) => t.status == 'pending').toList();
      case 'in_progress':
        return tasks.where((t) => t.status == 'in_progress').toList();
      case 'completed':
        return tasks.where((t) => t.status == 'completed').toList();
      default:
        return tasks;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة مهمة جديدة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(
    BuildContext context,
    WidgetRef ref,
    List<TaskLocalModel> allTasks,
    List<TaskLocalModel> filteredTasks,
  ) {
    // Use all tasks for stats, filtered for display
    final pending = allTasks.where((t) => t.status == 'pending').toList();
    final inProgress = allTasks.where((t) => t.status == 'in_progress').toList();
    final completed = allTasks.where((t) => t.status == 'completed').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics Cards (clickable)
        _buildStatsCards(context, ref, pending.length, inProgress.length,
            completed.length, allTasks.length),
        const SizedBox(height: 24),

        // Filtered Tasks
        if (filteredTasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('لا توجد مهام في هذا القسم'),
            ),
          )
        else
          ...filteredTasks.map((task) => _buildTaskCard(context, ref, task)),
      ],
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    WidgetRef ref,
    int pending,
    int inProgress,
    int completed,
    int total,
  ) {
    final currentFilter = ref.watch(taskFilterProvider);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            ref,
            'الكل',
            ArabicNumbers.convert(total.toString()),
            Colors.blue,
            Icons.list_alt,
            'all',
            currentFilter == 'all',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            ref,
            'قيد التنفيذ',
            ArabicNumbers.convert((pending + inProgress).toString()),
            Colors.orange,
            Icons.pending_actions,
            'pending',
            currentFilter == 'pending',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            ref,
            'مكتملة',
            ArabicNumbers.convert(completed.toString()),
            Colors.green,
            Icons.check_circle,
            'completed',
            currentFilter == 'completed',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    Color color,
    IconData icon,
    String filterValue,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        ref.read(taskFilterProvider.notifier).state = filterValue;
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: isActive ? 4 : 1,
        color: isActive ? color : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? Colors.white.withOpacity(0.9) : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskLocalModel task,
  ) {
    final isOverdue = task.isOverdue;
    final dateFormat = DateFormat('yyyy-MM-dd', 'en'); // Changed to 'en'
    
    // Parse checklist to get completion status and total price
    List<ChecklistItem> checklist = [];
    double totalPrice = 0.0;
    int completedItems = 0;
    
    if (task.description != null && task.description!.startsWith('[')) {
      try {
        checklist = ChecklistHelper.decodeChecklist(task.description!);
        completedItems = checklist.where((item) => item.isCompleted).length;
        if (task.taskType == 'shopping') {
          totalPrice = ChecklistHelper.getTotalPrice(checklist);
        }
      } catch (e) {
        // If parsing fails, description is not a checklist
      }
    }
    
    // Auto-complete task if all checklist items are checked
    if (checklist.isNotEmpty && 
        completedItems == checklist.length && 
        !task.isCompleted) {
      // Schedule completion after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tasksProvider.notifier).completeTask(task.id!);
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            if (value == true) {
              ref.read(tasksProvider.notifier).completeTask(task.id!);
            }
          },
          shape: const CircleBorder(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show checklist summary instead of raw JSON
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ArabicNumbers.convert(completedItems.toString())} / ${ArabicNumbers.convert(checklist.length.toString())} ${task.taskType == 'shopping' ? 'صنف' : 'نقطة'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (task.taskType == 'shopping' && totalPrice > 0) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${ArabicNumbers.convert(totalPrice.toStringAsFixed(2))} د.ل',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (task.description != null && !task.description!.startsWith('[')) ...[
              // Show regular description if not a checklist
              const SizedBox(height: 4),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(task.dueDate!), // Removed ArabicNumbers.formatDate
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'متأخر',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            // Sync status indicator
            if (task.syncStatus == 'pending') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'بانتظار المزامنة',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildPriorityBadge(context, task.priority),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(task: task),
            ),
          );
        },
        onLongPress: () {
          _showTaskActions(context, ref, task);
        },
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'high':
        color = Colors.red;
        label = 'عالية';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'متوسطة';
        break;
      case 'low':
        color = Colors.green;
        label = 'منخفضة';
        break;
      default:
        color = Colors.grey;
        label = 'عادية';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTaskActions(
    BuildContext context,
    WidgetRef ref,
    TaskLocalModel task,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('تعيين كمكتملة'),
              onTap: () {
                Navigator.pop(context);
                ref.read(tasksProvider.notifier).completeTask(task.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskLocalModel task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: Text('هل أنت متأكد من حذف "${task.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(tasksProvider.notifier).deleteTask(task.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
