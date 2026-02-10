import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../data/income_model.dart';
import '../providers/income_providers.dart';
import 'widgets/add_income_dialog.dart';
import '../../bank_accounts/data/bank_account_model.dart';
import '../../bank_accounts/providers/bank_accounts_providers.dart';
import '../../../core/navigation/app_drawer.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh when screen opens
    Future.microtask(() {
      ref.invalidate(incomeProvider);
      ref.invalidate(totalIncomeProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomesAsync = ref.watch(incomeProvider);
    final totalIncomeAsync = ref.watch(totalIncomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإيرادات'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildTotalCard(totalIncomeAsync),
          _buildActiveFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(incomeProvider);
                ref.invalidate(totalIncomeProvider);
                await ref.read(incomeProvider.future);
              },
              child: incomesAsync.when(
                data: (incomes) {
                  if (incomes.isEmpty) return _buildEmptyState(context);
                  return _buildIncomeList(context, incomes);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(AsyncValue<double> totalAsync) {
    return totalAsync.when(
      data: (total) => Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'إجمالي الإيرادات',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '${ArabicNumbers.convert(total.toStringAsFixed(2))} د.ل',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFilters() {
    final startDate = ref.watch(incomeStartDateProvider);
    final endDate = ref.watch(incomeEndDateProvider);
    final sourceType = ref.watch(incomeSourceTypeFilterProvider);
    final paymentMethod = ref.watch(incomePaymentMethodFilterProvider);
    final bankAccountId = ref.watch(incomeBankAccountIdFilterProvider);

    final hasFilters = startDate != null || endDate != null || sourceType != 'all' || paymentMethod != 'all' || bankAccountId != null;

    if (!hasFilters) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (startDate != null || endDate != null)
            _buildFilterChip(
              'التاريخ',
              onDeleted: () {
                ref.read(incomeStartDateProvider.notifier).state = null;
                ref.read(incomeEndDateProvider.notifier).state = null;
              },
            ),
          if (sourceType != 'all')
            _buildFilterChip(
              _getSourceTypeArabic(sourceType),
              onDeleted: () => ref.read(incomeSourceTypeFilterProvider.notifier).state = 'all',
            ),
          if (paymentMethod != 'all')
            _buildFilterChip(
              paymentMethod == 'cash' ? 'نقداً' : 'مصرفي',
              onDeleted: () => ref.read(incomePaymentMethodFilterProvider.notifier).state = 'all',
            ),
          if (bankAccountId != null)
            _buildFilterChip(
              'حساب مصرفي',
              onDeleted: () => ref.read(incomeBankAccountIdFilterProvider.notifier).state = null,
            ),
          TextButton(
            onPressed: () {
              ref.read(incomeStartDateProvider.notifier).state = null;
              ref.read(incomeEndDateProvider.notifier).state = null;
              ref.read(incomeSourceTypeFilterProvider.notifier).state = 'all';
              ref.read(incomePaymentMethodFilterProvider.notifier).state = 'all';
              ref.read(incomeBankAccountIdFilterProvider.notifier).state = null;
            },
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 14),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('لا توجد إيرادات مسجلة', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeList(BuildContext context, List<IncomeModel> incomes) {
    final grouped = <String, List<IncomeModel>>{};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var income in incomes) {
      final key = dateFormat.format(income.entryDate);
      grouped.putIfAbsent(key, () => []).add(income);
    }

    final dates = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateKey = dates[index];
        final dayIncomes = grouped[dateKey]!;
        final dayTotal = dayIncomes.fold(0.0, (sum, item) => sum + item.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ArabicNumbers.formatDate(DateFormat('EEEE, d MMMM yyyy', 'ar').format(DateTime.parse(dateKey))),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${ArabicNumbers.convert(dayTotal.toStringAsFixed(2))} د.ل',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ...dayIncomes.map((income) => _buildIncomeCard(context, income)),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildIncomeCard(BuildContext context, IncomeModel income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(
            income.sourceType == 'tool_rental' ? Icons.handyman : Icons.attach_money,
            color: AppTheme.success,
          ),
        ),
        title: Text(income.sourceTypeArabic, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (income.description != null) Text(income.description!),
            Row(
              children: [
                Icon(income.paymentMethod == 'cash' ? Icons.money : Icons.account_balance, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(income.paymentMethodArabic, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${ArabicNumbers.convert(income.amount.toStringAsFixed(2))} د.ل',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success),
        ),
        onTap: () => _showIncomeOptions(context, income),
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, [IncomeModel? income]) {
    showDialog(context: context, builder: (context) => AddIncomeDialog(income: income));
  }

  void _showIncomeOptions(BuildContext context, IncomeModel income) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('تعديل'),
            onTap: () {
              Navigator.pop(context);
              _showAddIncomeDialog(context, income);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppTheme.error),
            title: const Text('حذف', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد من حذف هذا الإيراد؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: AppTheme.error))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await ref.read(incomeNotifierProvider.notifier).deleteIncome(income.id!);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const IncomeFilterSheet(),
    );
  }

  String _getSourceTypeArabic(String type) {
    switch (type) {
      case 'salary': return 'راتب';
      case 'business': return 'عمل خاص';
      case 'tool_rental': return 'إيجار معدات';
      default: return 'أخرى';
    }
  }
}

class IncomeFilterSheet extends ConsumerWidget {
  const IncomeFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final sourceType = ref.watch(incomeSourceTypeFilterProvider);
    final paymentMethod = ref.watch(incomePaymentMethodFilterProvider);
    final bankAccountId = ref.watch(incomeBankAccountIdFilterProvider);
    final bankAccountsAsync = ref.watch(bankAccountsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, right: 16, left: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تصفية الإيرادات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          const Text('فترة التاريخ:'),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _selectDate(context, ref, true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(ref.watch(incomeStartDateProvider) != null 
                    ? ArabicNumbers.formatDate(DateFormat('yyyy/MM/dd').format(ref.read(incomeStartDateProvider)!))
                    : 'من'),
                ),
              ),
              const Text(' - '),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _selectDate(context, ref, false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(ref.watch(incomeEndDateProvider) != null 
                    ? ArabicNumbers.formatDate(DateFormat('yyyy/MM/dd').format(ref.read(incomeEndDateProvider)!))
                    : 'إلى'),
                ),
              ),
            ],
          ),
          const Divider(),

          const Text('مصدر الإيراد:'),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip(ref, incomeSourceTypeFilterProvider, 'all', 'الكل'),
              _buildChoiceChip(ref, incomeSourceTypeFilterProvider, 'salary', 'راتب'),
              _buildChoiceChip(ref, incomeSourceTypeFilterProvider, 'business', 'عمل خاص'),
              _buildChoiceChip(ref, incomeSourceTypeFilterProvider, 'tool_rental', 'إيجار معدات'),
              _buildChoiceChip(ref, incomeSourceTypeFilterProvider, 'other', 'أخرى'),
            ],
          ),
          const Divider(),

          const Text('طريقة الدفع:'),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip(ref, incomePaymentMethodFilterProvider, 'all', 'الكل'),
              _buildChoiceChip(ref, incomePaymentMethodFilterProvider, 'cash', 'نقداً'),
              _buildChoiceChip(ref, incomePaymentMethodFilterProvider, 'bank_transfer', 'مصرفي'),
            ],
          ),
          
          if (paymentMethod == 'bank_transfer') ...[
            const SizedBox(height: 8),
            const Text('الحساب المصرفي:'),
            bankAccountsAsync.when(
              data: (accounts) => DropdownButtonFormField<int?>(
                value: bankAccountId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الحسابات')),
                  ...accounts.map((acc) {
                    final bank = BankInfo.fromId(acc.bankId);
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text('${bank?.nameArabic ?? acc.bankId} - ${acc.accountNumber}'),
                    );
                  }),
                ],
                onChanged: (val) => ref.read(incomeBankAccountIdFilterProvider.notifier).state = val,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('خطأ في تحميل الحسابات'),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إظهار النتائج'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(WidgetRef ref, StateProvider<String> provider, String value, String label) {
    final selected = ref.watch(provider) == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) ref.read(provider.notifier).state = value;
      },
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref, bool isStart) async {
    final initialDate = (isStart ? ref.read(incomeStartDateProvider) : ref.read(incomeEndDateProvider)) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (date != null) {
      if (isStart) {
        ref.read(incomeStartDateProvider.notifier).state = date;
      } else {
        ref.read(incomeEndDateProvider.notifier).state = date;
      }
    }
  }
}
