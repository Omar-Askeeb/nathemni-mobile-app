import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tool_category_model.dart';
import '../../people/data/person_model.dart';
import '../../people/providers/people_providers.dart';
import '../providers/tools_providers.dart';
import 'return_tool_dialog.dart';
import 'widgets/transaction_card.dart';

class TransactionLogsScreen extends ConsumerWidget {
  const TransactionLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final periodStatsAsync = ref.watch(filteredPeriodStatsProvider);
    final categoriesAsync = ref.watch(toolCategoriesProvider);
    final peopleAsync = ref.watch(peopleNotifierProvider);
    final statusFilter = ref.watch(transactionStatusFilterProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final personFilter = ref.watch(transactionPersonFilterProvider);
    final startDate = ref.watch(transactionStartDateProvider);
    final endDate = ref.watch(transactionEndDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
            tooltip: 'تصفية',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Stats
          periodStatsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _buildPeriodStatsBar(context, stats, startDate, endDate),
          ),
          // Filters Row
          _buildFiltersRow(context, ref, statusFilter, categoryFilter, personFilter, categoriesAsync, peopleAsync),
          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _buildEmptyState(context);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(filteredPeriodStatsProvider);
                    ref.invalidate(toolsSummaryProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        onReturn: transaction.isActive
                            ? () => showDialog(
                                  context: context,
                                  builder: (_) => ReturnToolDialog(
                                    transaction: transaction,
                                    toolId: transaction.toolId,
                                  ),
                                )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodStatsBar(
    BuildContext context,
    Map<String, double> stats,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final hasFilter = startDate != null || endDate != null;
    final dateFormat = DateFormat('MM/dd');
    String periodText = 'كل الفترات';
    if (startDate != null && endDate != null) {
      periodText = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    } else if (startDate != null) {
      periodText = 'من ${dateFormat.format(startDate)}';
    } else if (endDate != null) {
      periodText = 'حتى ${dateFormat.format(endDate)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDivider),
        ),
      ),
      child: Column(
        children: [
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                periodText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDark,
                    ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'عدد العمليات',
                '${stats['transactionCount']?.toInt() ?? 0}',
                AppTheme.primaryLight,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'إجمالي الدخل',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.success,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(stats['totalIncome'] ?? 0).toStringAsFixed(0)} د.ل',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(
    BuildContext context, 
    WidgetRef ref, 
    String statusFilter,
    int? categoryFilter,
    int? personFilter,
    AsyncValue<List<ToolCategoryModel>> categoriesAsync,
    AsyncValue<List<PersonModel>> peopleAsync,
  ) {
    final statuses = [
      {'id': 'all', 'name': 'الكل', 'icon': Icons.list},
      {'id': 'active', 'name': 'نشطة', 'icon': Icons.pending},
      {'id': 'returned', 'name': 'مرجعة', 'icon': Icons.check_circle},
    ];

    return Column(
      children: [
        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: statuses.map((status) {
              final isSelected = status['id'] == statusFilter;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  avatar: Icon(
                    status['icon'] as IconData,
                    size: 18,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                  ),
                  label: Text(status['name'] as String),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(transactionStatusFilterProvider.notifier).state =
                        status['id'] as String;
                  },
                  selectedColor: AppTheme.primaryDark.withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ),
        // Category & Person Filter Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Category Filter
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => _buildDropdownFilter(
                    context,
                    'الفئة',
                    categoryFilter,
                    [
                      const DropdownMenuItem<int?>(value: null, child: Text('كل الفئات')),
                      ...categories.map((cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Row(
                          children: [
                            if (cat.icon != null) ...[
                              Text(cat.icon!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                            ],
                            Flexible(child: Text(cat.nameAr, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
                    ],
                    (value) => ref.read(transactionCategoryFilterProvider.notifier).state = value,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Person Filter
              Expanded(
                child: peopleAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (people) => _buildDropdownFilter(
                    context,
                    'الشخص',
                    personFilter,
                    [
                      const DropdownMenuItem<int?>(value: null, child: Text('كل الأشخاص')),
                      ...people.map((person) => DropdownMenuItem<int?>(
                        value: person.id,
                        child: Text(person.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    (value) => ref.read(transactionPersonFilterProvider.notifier).state = value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    BuildContext context,
    String label,
    int? value,
    List<DropdownMenuItem<int?>> items,
    ValueChanged<int?> onChanged,
  ) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(label, style: const TextStyle(fontSize: 12)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppTheme.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عمليات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تسجيل أي عمليات تأجير أو إعارة بعد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _DateFilterSheet(ref: ref),
    );
  }
}

// Separate StatefulWidget for date filter to properly manage local state
class _DateFilterSheet extends StatefulWidget {
  final WidgetRef ref;

  const _DateFilterSheet({required this.ref});

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.ref.read(transactionStartDateProvider);
    _tempEndDate = widget.ref.read(transactionEndDateProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية حسب التاريخ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDateField('من', _tempStartDate, (date) {
                    setState(() => _tempStartDate = date);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField('إلى', _tempEndDate, (date) {
                    setState(() => _tempEndDate = date);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.ref.read(transactionStartDateProvider.notifier).state = null;
                      widget.ref.read(transactionEndDateProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                    child: const Text('مسح الفلتر'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.ref.read(transactionStartDateProvider.notifier).state = _tempStartDate;
                      widget.ref.read(transactionEndDateProvider.notifier).state = _tempEndDate;
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null ? DateFormat('yyyy-MM-dd').format(value) : 'اختر',
        ),
      ),
    );
  }
}
