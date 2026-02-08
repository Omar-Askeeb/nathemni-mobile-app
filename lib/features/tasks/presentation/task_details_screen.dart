import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/task_local_model.dart';
import '../data/checklist_item_model.dart';
import '../providers/tasks_providers.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../expenses/data/expense_local_model.dart';
import '../../expenses/providers/expenses_providers.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final TaskLocalModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late List<ChecklistItem> _checklistItems;
  final TextEditingController _newItemController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final _uuid = const Uuid();
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _checklistItems = _parseChecklistFromDescription(widget.task.description);
  }

  List<ChecklistItem> _parseChecklistFromDescription(String? description) {
    if (description == null || description.isEmpty) return [];
    
    try {
      return ChecklistHelper.decodeChecklist(description);
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final title = _newItemController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _checklistItems.add(ChecklistItem(
        id: _uuid.v4(),
        title: title,
        isCompleted: false,
      ));
    });

    _newItemController.clear();
    // When adding a new item, task should become incomplete
    _saveChecklist(forceIncomplete: true);
  }

  void _toggleChecklistItem(int index) async {
    final item = _checklistItems[index];
    
    // If it's a shopping item and being checked, ask for price
    if (widget.task.taskType == 'shopping' && 
        !item.isCompleted && 
        item.price == null) {
      final price = await _showPriceDialog(item.title);
      if (price != null) {
        setState(() {
          _checklistItems[index] = item.copyWith(
            isCompleted: true,
            price: price,
          );
        });
        _saveChecklist();
      }
    } else {
      setState(() {
        _checklistItems[index] = item.copyWith(
          isCompleted: !item.isCompleted,
        );
      });
      _saveChecklist();
    }
  }

  Future<double?> _showPriceDialog(String itemName) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدخل السعر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر',
                border: OutlineInputBorder(),
                suffixText: 'د.ل',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              Navigator.pop(context, price);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _editItemPrice(int index) async {
    final item = _checklistItems[index];
    final controller = TextEditingController(
      text: item.price?.toString() ?? '',
    );
    
    final price = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر',
                border: OutlineInputBorder(),
                suffixText: 'د.ل',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              Navigator.pop(context, price);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (price != null) {
      setState(() {
        _checklistItems[index] = item.copyWith(price: price);
      });
      _saveChecklist();
    }
  }

  void _deleteChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
    _saveChecklist();
  }

  Future<void> _saveChecklist({bool forceIncomplete = false}) async {
    final checklistJson = ChecklistHelper.encodeChecklist(_checklistItems);
    final allCompleted = ChecklistHelper.areAllCompleted(_checklistItems);
    
    // Determine task status based on checklist completion
    String newStatus = widget.task.status;
    if (forceIncomplete) {
      // When adding new item, force task to be incomplete
      newStatus = 'pending';
    } else if (_checklistItems.isNotEmpty && allCompleted) {
      // All items checked - check if it's a shopping task
      if (widget.task.taskType == 'shopping') {
        // For shopping, we need payment method before completing
        await _completeShoppingTask();
        return;
      }
      newStatus = 'completed';
    } else if (_checklistItems.isNotEmpty && !allCompleted) {
      // Not all items are checked
      newStatus = 'pending';
    }
    
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: checklistJson,
      status: newStatus,
      completedAt: newStatus == 'completed' ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    await ref.read(tasksProvider.notifier).updateTask(updatedTask);
  }

  Future<void> _completeShoppingTask() async {
    final totalPrice = ChecklistHelper.getTotalPrice(_checklistItems);
    
    // Check if there's already an existing expense for this task
    String? paymentMethod;
    final existingExpense = await ref.read(expensesRepositoryProvider).getExpenseByLinkedItem('task', widget.task.id!);
    
    if (existingExpense != null) {
      // If updating, reuse the previous payment method
      paymentMethod = existingExpense.paymentMethod;
    } else {
      // If it's the first time completing, show payment method dialog
      paymentMethod = await _showPaymentMethodDialog(totalPrice);
    }
    
    if (paymentMethod == null) return;

    // Save to expenses table
    final expense = ExpenseLocalModel(
      userId: widget.task.userId,
      categoryId: widget.task.expenseCategory ?? 'other',
      amount: totalPrice,
      currency: 'LYD',
      paymentMethod: paymentMethod,
      expenseDate: existingExpense?.expenseDate ?? DateTime.now(),
      notes: widget.task.title,
      linkedTo: 'task',
      linkedId: widget.task.id,
    );

    try {
      await ref.read(expensesNotifierProvider.notifier).addOrUpdateLinkedExpense(expense);

      // Update task as completed
      final checklistJson = ChecklistHelper.encodeChecklist(_checklistItems);
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: checklistJson,
        status: 'completed',
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(tasksProvider.notifier).updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ المصروف: ${ArabicNumbers.convert(totalPrice.toStringAsFixed(2))} د.ل'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPaymentMethodDialog(double totalPrice) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طريقة الدفع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المجموع: ${ArabicNumbers.convert(totalPrice.toStringAsFixed(2))} د.ل',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text('اختر طريقة الدفع:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'cash'),
                    icon: const Text('💵', style: TextStyle(fontSize: 24)),
                    label: const Text('كاش'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'card'),
                    icon: const Text('💳', style: TextStyle(fontSize: 24)),
                    label: const Text('بطاقة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final completionPercentage =
        ChecklistHelper.getCompletionPercentage(_checklistItems);
    final totalPrice = ChecklistHelper.getTotalPrice(_checklistItems);
    final isShoppingTask = widget.task.taskType == 'shopping';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المهمة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditingTitle ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditingTitle) {
                _saveChecklist();
              }
              setState(() {
                _isEditingTitle = !_isEditingTitle;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Task Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (editable)
                if (_isEditingTitle)
                  TextField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  )
                else
                  Text(
                    _titleController.text,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Task Type Badge
                    if (widget.task.taskType != null)
                      _buildInfoChip(
                        icon: widget.task.taskType == 'shopping'
                            ? Icons.shopping_cart
                            : Icons.task,
                        label: widget.task.taskType == 'shopping'
                            ? 'مشتريات'
                            : 'مهام',
                        color: widget.task.taskType == 'shopping'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    _buildInfoChip(
                      icon: Icons.flag,
                      label: _getPriorityLabel(widget.task.priority),
                      color: _getPriorityColor(widget.task.priority),
                    ),
                    if (widget.task.dueDate != null)
                      _buildInfoChip(
                        icon: Icons.calendar_today,
                        label: ArabicNumbers.formatDate(
                          dateFormat.format(widget.task.dueDate!),
                        ),
                        color: widget.task.isOverdue
                            ? Colors.red
                            : Colors.blue,
                      ),
                  ],
                ),
                if (_checklistItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ArabicNumbers.convert(completionPercentage.toStringAsFixed(0))}% مكتمل',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (isShoppingTask && totalPrice > 0)
                        Text(
                          'المجموع: ${ArabicNumbers.convert(totalPrice.toStringAsFixed(2))} د.ل',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Checklist Items
          Expanded(
            child: _checklistItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isShoppingTask ? Icons.shopping_bag : Icons.checklist,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isShoppingTask
                              ? 'أضف عناصر للمشتريات'
                              : 'أضف عناصر للقائمة',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _checklistItems.length,
                    itemBuilder: (context, index) {
                      final item = _checklistItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isCompleted,
                            onChanged: (_) => _toggleChecklistItem(index),
                            shape: const CircleBorder(),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          subtitle: isShoppingTask && item.price != null
                              ? Text(
                                  '${ArabicNumbers.convert(item.price!.toStringAsFixed(2))} د.ل',
                                  style: TextStyle(
                                    color: item.isCompleted
                                        ? Colors.grey
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isShoppingTask && item.isCompleted)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editItemPrice(index),
                                  color: Colors.blue,
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteChecklistItem(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add Item Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: InputDecoration(
                      hintText: isShoppingTask
                          ? 'أضف عنصر للمشتريات...'
                          : 'أضف عنصر جديد...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addChecklistItem(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addChecklistItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'عالية';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return 'عادية';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
