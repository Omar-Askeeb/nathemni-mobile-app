import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tool_category_model.dart';
import '../data/tool_model.dart';
import '../providers/tools_providers.dart';
import 'add_edit_tool_dialog.dart';
import 'tool_details_screen.dart';
import 'transaction_logs_screen.dart';
import 'widgets/tool_card.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(toolCategoriesProvider);
    final toolsAsync = ref.watch(toolsProvider);
    final summaryAsync = ref.watch(toolsSummaryProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final statusFilter = ref.watch(toolStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المعدات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionLogsScreen()),
            ),
            tooltip: 'سجل العمليات',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Summary Cards
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => _buildSummaryRow(context, summary),
          ),
          // Category Dropdown
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (categories) => _buildCategoryDropdown(
              context,
              ref,
              categories,
              selectedCategoryId,
            ),
          ),
          // Status Filter
          _buildStatusFilter(context, ref, statusFilter),
          // Tools List
          Expanded(
            child: toolsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (tools) {
                if (tools.isEmpty) {
                  return _buildEmptyState(context);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(toolsProvider);
                    ref.invalidate(toolsSummaryProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tools.length,
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return ToolCard(
                        tool: tool,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ToolDetailsScreen(toolId: tool.id!),
                          ),
                        ),
                        onLongPress: () => _showToolOptions(context, ref, tool),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddEditToolDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('إضافة معدة'),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, Map<String, dynamic> summary) {
    final totalInvestment =
        (summary['totalInvestment'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'الكل',
                  '${summary['totalTools']}',
                  Icons.construction,
                  AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'متوفر',
                  '${summary['availableTools']}',
                  Icons.check_circle,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'مؤجر',
                  '${summary['rentedTools']}',
                  Icons.attach_money,
                  AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'متأخر',
                  '${summary['overdueTransactions']}',
                  Icons.warning,
                  AppTheme.error,
                ),
              ),
            ],
          ),
          // Total Investment
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'إجمالي التكلفة: ${totalInvestment.toStringAsFixed(0)} د.ل',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
    BuildContext context,
    WidgetRef ref,
    List<ToolCategoryModel> categories,
    int? selectedId,
  ) {
    // Find selected category name
    String selectedName = 'كل الفئات';
    String? selectedIcon;
    if (selectedId != null) {
      final selected = categories.where((c) => c.id == selectedId).firstOrNull;
      if (selected != null) {
        selectedName = selected.nameAr;
        selectedIcon = selected.icon;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('الفئة:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderDivider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedId,
                  isExpanded: true,
                  hint: Row(
                    children: [
                      if (selectedIcon != null) ...[
                        Text(
                          selectedIcon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(selectedName),
                    ],
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل الفئات'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Row(
                          children: [
                            if (category.icon != null) ...[
                              Text(
                                category.icon!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(category.nameAr),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(selectedCategoryIdProvider.notifier).state = value;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final statuses = [
      {'id': 'all', 'name': 'الكل'},
      ...ToolModel.allStatuses,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('الحالة:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = status['id'] == current;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(status['name']!),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(toolStatusFilterProvider.notifier).state =
                            status['id']!;
                      },
                      selectedColor: AppTheme.primaryLight.withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 80,
            color: AppTheme.textDisabled,
          ),
          const SizedBox(height: 16),
          Text('لا توجد معدات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة معداتك للبدء',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showToolOptions(BuildContext context, WidgetRef ref, ToolModel tool) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AddEditToolDialog(tool: tool),
                );
              },
            ),
            if (tool.isAvailable)
              ListTile(
                leading: const Icon(Icons.handshake, color: AppTheme.accent),
                title: const Text('تأجير / إعارة'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ToolDetailsScreen(toolId: tool.id!),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('حذف', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, tool);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ToolModel tool) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المعدة'),
        content: Text('هل أنت متأكد من حذف "${tool.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(toolsNotifierProvider.notifier)
                    .deleteTool(tool.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المعدة بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
