import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../data/expense_local_model.dart';
import '../providers/expenses_providers.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/providers/common_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final totalAsync = ref.watch(totalExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المصاريف'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportToPDF(context),
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFiltersSection(context),
          _buildTotalCard(totalAsync),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildExpensesList(context, expenses);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('خطأ: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    final categoryFilter = ref.watch(selectedCategoryFilterProvider);
    final paymentMethodFilter = ref.watch(selectedPaymentMethodFilterProvider);
    final startDate = ref.watch(startDateFilterProvider);
    final endDate = ref.watch(endDateFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        children: [
          Row(
            children: [
              // Category filter
              Expanded(
                child: _buildCategoryFilterButton(context, categoryFilter),
              ),
              const SizedBox(width: 8),
              // Date filter
              Expanded(
                child: _buildDateFilterButton(context, startDate, endDate),
              ),
              // Clear filters
              if (categoryFilter != null || startDate != null || paymentMethodFilter != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state = null;
                    ref.read(selectedPaymentMethodFilterProvider.notifier).state = null;
                    ref.read(startDateFilterProvider.notifier).state = null;
                    ref.read(endDateFilterProvider.notifier).state = null;
                  },
                  tooltip: 'مسح الفلاتر',
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Payment method filter row
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodFilterButton(context, paymentMethodFilter),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterButton(BuildContext context, String? selectedCategory) {
    final category = selectedCategory != null
        ? ExpenseCategoryInfo.fromId(selectedCategory)
        : null;

    return OutlinedButton.icon(
      onPressed: () => _showCategoryPicker(context),
      icon: category != null 
          ? Text(category.icon, style: const TextStyle(fontSize: 20))
          : const Icon(Icons.folder_open, size: 20),
      label: Text(category?.nameArabic ?? 'كل الفئات'),
      style: OutlinedButton.styleFrom(
        backgroundColor: category != null ? Colors.blue.withOpacity(0.1) : null,
      ),
    );
  }

  Widget _buildDateFilterButton(BuildContext context, DateTime? start, DateTime? end) {
    final hasDate = start != null && end != null;
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return OutlinedButton.icon(
      onPressed: () => _showDateRangePicker(context),
      icon: const Icon(Icons.date_range),
      label: Text(hasDate
          ? '${ArabicNumbers.formatDate(dateFormat.format(start!))} - ${ArabicNumbers.formatDate(dateFormat.format(end!))}'
          : 'كل التواريخ'),
      style: OutlinedButton.styleFrom(
        backgroundColor: hasDate ? Colors.blue.withOpacity(0.1) : null,
      ),
    );
  }

  Widget _buildPaymentMethodFilterButton(BuildContext context, String? selectedMethod) {
    final method = selectedMethod != null
        ? PaymentMethodInfo.fromId(selectedMethod)
        : null;

    return OutlinedButton.icon(
      onPressed: () => _showPaymentMethodPicker(context),
      icon: method != null 
          ? Text(method.icon, style: const TextStyle(fontSize: 20))
          : const Icon(Icons.payment, size: 20),
      label: Text(method?.nameArabic ?? 'كل طرق الدفع'),
      style: OutlinedButton.styleFrom(
        backgroundColor: method != null ? Colors.green.withOpacity(0.1) : null,
      ),
    );
  }

  void _showPaymentMethodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.payment, size: 28, color: Colors.green),
            title: const Text('كل طرق الدفع'),
            onTap: () {
              ref.read(selectedPaymentMethodFilterProvider.notifier).state = null;
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ...PaymentMethodInfo.allMethods.map((method) {
            return ListTile(
              leading: Text(method.icon, style: const TextStyle(fontSize: 24)),
              title: Text(method.nameArabic),
              onTap: () {
                ref.read(selectedPaymentMethodFilterProvider.notifier).state = method.id;
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalCard(AsyncValue<double> totalAsync) {
    return totalAsync.when(
      data: (total) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'إجمالي المصاريف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${ArabicNumbers.convert(total.toStringAsFixed(2))} د.ل',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مصاريف',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة مصروف',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context, List<ExpenseLocalModel> expenses) {
    // Group by date
    final Map<String, List<ExpenseLocalModel>> groupedExpenses = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var expense in expenses) {
      final dateKey = dateFormat.format(expense.expenseDate);
      if (!groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey] = [];
      }
      groupedExpenses[dateKey]!.add(expense);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateKey = groupedExpenses.keys.elementAt(index);
        final dayExpenses = groupedExpenses[dateKey]!;
        final dayTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);

        return _buildDaySection(context, dateKey, dayExpenses, dayTotal);
      },
    );
  }

  Widget _buildDaySection(
      BuildContext context, String dateKey, List<ExpenseLocalModel> expenses, double total) {
    final date = DateTime.parse(dateKey);
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ArabicNumbers.formatDate(dateFormat.format(date)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${ArabicNumbers.convert(total.toStringAsFixed(2))} د.ل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...expenses.map((expense) => _buildExpenseCard(context, expense)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseLocalModel expense) {
    final category = ExpenseCategoryInfo.fromId(expense.categoryId);
    final color = category != null
        ? Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000)
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              category?.icon ?? '📦',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          category?.nameArabic ?? 'أخرى',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: expense.notes != null
            ? Text(
                expense.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${ArabicNumbers.convert(expense.amount.toStringAsFixed(2))} د.ل',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        onTap: () => _showExpenseOptions(context, expense),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open, size: 28, color: Colors.amber),
            title: const Text('كل الفئات'),
            onTap: () {
              ref.read(selectedCategoryFilterProvider.notifier).state = null;
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ...ExpenseCategoryInfo.allCategories.map((category) {
            return ListTile(
              leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
              title: Text(category.nameArabic),
              onTap: () {
                ref.read(selectedCategoryFilterProvider.notifier).state = category.id;
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      ref.read(startDateFilterProvider.notifier).state = picked.start;
      ref.read(endDateFilterProvider.notifier).state = picked.end;
    }
  }

  void _showExpenseOptions(BuildContext context, ExpenseLocalModel expense) {
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
                _showAddExpenseDialog(context, expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, expense);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseLocalModel? expense) {
    final isEdit = expense != null;
    String? selectedCategoryId = expense?.categoryId;
    String selectedPaymentMethod = expense?.paymentMethod ?? 'cash';
    final amountController = TextEditingController(
        text: expense?.amount.toString() ?? '');
    DateTime selectedDate = expense?.expenseDate ?? DateTime.now();
    final notesController = TextEditingController(text: expense?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل المصروف' : 'إضافة مصروف'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      border: OutlineInputBorder(),
                    ),
                    items: ExpenseCategoryInfo.allCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(cat.nameArabic),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategoryId = value),
                    validator: (v) => v == null ? 'اختر فئة' : null,
                  ),
                  const SizedBox(height: 16),
                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: PaymentMethodInfo.allMethods.map((method) {
                      return DropdownMenuItem(
                        value: method.id,
                        child: Row(
                          children: [
                            Text(method.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(method.nameArabic),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPaymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (د.ل)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل المبلغ';
                      if (double.tryParse(v) == null) return 'مبلغ غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('ar'),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        ArabicNumbers.formatDate(
                            DateFormat('yyyy/MM/dd').format(selectedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: 2,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedCategoryId != null) {
                  Navigator.pop(dialogContext);
                  await _saveExpense(
                    expense,
                    selectedCategoryId!,
                    selectedPaymentMethod,
                    double.parse(amountController.text),
                    selectedDate,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                }
              },
              child: Text(isEdit ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseLocalModel expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteExpense(expense.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    try {
      final repository = ref.read(expensesRepositoryProvider);
      await repository.deleteExpense(id);
      ref.invalidate(expensesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المصروف بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveExpense(
    ExpenseLocalModel? existing,
    String categoryId,
    String paymentMethod,
    double amount,
    DateTime date,
    String? notes,
  ) async {
    try {
      final repository = ref.read(expensesRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      if (existing != null) {
        await repository.updateExpense(
          existing.copyWith(
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            amount: amount,
            expenseDate: date,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المصروف')),
          );
        }
      } else {
        await repository.addExpense(
          ExpenseLocalModel(
            userId: userId,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            amount: amount,
            expenseDate: date,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة المصروف')),
          );
        }
      }

      ref.invalidate(expensesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF(BuildContext context) async {
    final expenses = await ref.read(expensesProvider.future);
    final total = await ref.read(totalExpensesProvider.future);
    final categoryFilter = ref.read(selectedCategoryFilterProvider);
    final startDate = ref.read(startDateFilterProvider);
    final endDate = ref.read(endDateFilterProvider);

    if (expenses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد مصاريف للتصدير')),
        );
      }
      return;
    }

    try {
      // Load Arabic font
      final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load('fonts/Cairo-Bold.ttf');
      final boldTtf = pw.Font.ttf(boldFontData);

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy/MM/dd');

      // Group expenses by category
      final Map<String, List<ExpenseLocalModel>> groupedByCategory = {};
      final Map<String, double> categoryTotals = {};

      for (var expense in expenses) {
        if (!groupedByCategory.containsKey(expense.categoryId)) {
          groupedByCategory[expense.categoryId] = [];
          categoryTotals[expense.categoryId] = 0.0;
        }
        groupedByCategory[expense.categoryId]!.add(expense);
        categoryTotals[expense.categoryId] = 
            (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: boldTtf,
          ),
          build: (context) => [
            // Header
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    'تقرير المصاريف',
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 24,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (startDate != null && endDate != null)
                    pw.Text(
                      'من ${dateFormat.format(startDate)} إلى ${dateFormat.format(endDate)}',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    )
                  else
                    pw.Text(
                      'جميع المصاريف',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                  if (categoryFilter != null)
                    pw.Text(
                      'الفئة: ${ExpenseCategoryInfo.fromId(categoryFilter)?.nameArabic ?? categoryFilter}',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),

            // Total
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'إجمالي المصاريف',
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.Text(
                    '${total.toStringAsFixed(2)} د.ل',
                    style: pw.TextStyle(font: boldTtf, fontSize: 18),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Category Summary
            pw.Text(
              'ملخص حسب الفئات',
              style: pw.TextStyle(font: boldTtf, fontSize: 16),
            ),
            pw.SizedBox(height: 8),
            ...groupedByCategory.keys.map((categoryId) {
              final category = ExpenseCategoryInfo.fromId(categoryId);
              final categoryTotal = categoryTotals[categoryId] ?? 0.0;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${category?.icon ?? "📦"} ${category?.nameArabic ?? "أخرى"}',
                      style: pw.TextStyle(font: ttf),
                    ),
                    pw.Text(
                      '${categoryTotal.toStringAsFixed(2)} د.ل',
                      style: pw.TextStyle(font: ttf),
                    ),
                  ],
                ),
              );
            }),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Details
            pw.Text(
              'التفاصيل',
              style: pw.TextStyle(font: boldTtf, fontSize: 16),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الفئة', style: pw.TextStyle(font: boldTtf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('المبلغ', style: pw.TextStyle(font: boldTtf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('التاريخ', style: pw.TextStyle(font: boldTtf)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('ملاحظات', style: pw.TextStyle(font: boldTtf)),
                    ),
                  ],
                ),
                // Data rows
                ...expenses.map((expense) {
                  final category = ExpenseCategoryInfo.fromId(expense.categoryId);
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          category?.nameArabic ?? 'أخرى',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${expense.amount.toStringAsFixed(2)} د.ل',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          dateFormat.format(expense.expenseDate),
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          expense.notes ?? '-',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'تم إنشاء التقرير بواسطة تطبيق نظمني - ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      );

      // Share PDF
      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'تقرير_المصاريف_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
