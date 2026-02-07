import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/commitment_model.dart';
import '../providers/commitments_providers.dart';
import '../../../core/utils/arabic_numbers.dart';

class CommitmentDetailsScreen extends ConsumerWidget {
  final int commitmentId;

  const CommitmentDetailsScreen({super.key, required this.commitmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitmentAsync = ref.watch(commitmentProvider(commitmentId));
    final paymentsAsync = ref.watch(paymentsProvider(commitmentId));

    return commitmentAsync.when(
      data: (commitment) {
        if (commitment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل الدين')),
            body: const Center(child: Text('الدين غير موجود')),
          );
        }

        final isDebtToMe = commitment.type == 'debt_to_me';
        final color = isDebtToMe ? Colors.green : Colors.red;

        return Scaffold(
          appBar: AppBar(
            title: const Text('تفاصيل الدين'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, ref, commitment),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header
              _buildHeader(context, commitment, color),
              // Payments list
              Expanded(
                child: paymentsAsync.when(
                  data: (payments) => _buildPaymentsList(context, ref, commitment, payments),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                ),
              ),
            ],
          ),
          floatingActionButton: commitment.isFullyPaid
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showAddPaymentDialog(context, ref, commitment),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دفعة'),
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الدين')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الدين')),
        body: Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CommitmentModel commitment, Color color) {
    final paidAmount = commitment.paidAmount ?? 0;
    final progress = commitment.progressPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
      ),
      child: Column(
        children: [
          // Person info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  commitment.person?.name.isNotEmpty == true
                      ? commitment.person!.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commitment.person?.name ?? 'غير معروف',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      commitment.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        commitment.typeArabic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Amount info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAmountItem('المبلغ الكلي', commitment.amount),
              _buildAmountItem('المدفوع', paidAmount),
              _buildAmountItem('المتبقي', commitment.remainingAmount),
            ],
          ),
          const SizedBox(height: 16),
          // Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ArabicNumbers.convert(progress.toStringAsFixed(0))}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    commitment.statusArabic,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
          if (commitment.description != null && commitment.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                commitment.description!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ArabicNumbers.convert(amount.toStringAsFixed(2)),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Text(
          'د.ل',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    WidgetRef ref,
    CommitmentModel commitment,
    List<DebtPaymentModel> payments,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد دفعات',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على + لإضافة دفعة',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'سجل الدفعات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
        }

        final payment = payments[index - 1];
        final dateFormat = DateFormat('yyyy/MM/dd');

        return Dismissible(
          key: Key('payment_${payment.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('حذف الدفعة'),
                content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ref.read(commitmentsNotifierProvider.notifier).deletePayment(
                  payment.id!,
                  commitment.id!,
                ).then((_) {
              // Refresh related providers
              ref.invalidate(paymentsProvider(commitment.id!));
              ref.invalidate(commitmentProvider(commitment.id!));
              ref.invalidate(commitmentsProvider);
              ref.invalidate(debtsToMeProvider);
              ref.invalidate(debtsFromMeProvider);
              ref.invalidate(totalDebtToMeProvider);
              ref.invalidate(totalDebtFromMeProvider);
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              title: Text(
                '${ArabicNumbers.convert(payment.amount.toStringAsFixed(2))} د.ل',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicNumbers.formatDate(dateFormat.format(payment.paymentDate)),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (payment.notes != null && payment.notes!.isNotEmpty)
                    Text(
                      payment.notes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: Text(
                payment.paymentMethodArabic,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    CommitmentModel commitment,
  ) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';
    DateTime paymentDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة دفعة'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Remaining amount info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المتبقي:'),
                        Text(
                          '${ArabicNumbers.convert(commitment.remainingAmount.toStringAsFixed(2))} د.ل',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (د.ل) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل المبلغ';
                      final amount = double.tryParse(v);
                      if (amount == null) return 'مبلغ غير صحيح';
                      if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
                      if (amount > commitment.remainingAmount) {
                        return 'المبلغ أكبر من المتبقي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Payment method
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Row(
                          children: [
                            Text('💵', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('نقداً'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'card',
                        child: Row(
                          children: [
                            Text('💳', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('بطاقة'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Row(
                          children: [
                            Text('🏦', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('تحويل'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => paymentMethod = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('ar'),
                      );
                      if (date != null) setState(() => paymentDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الدفع',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        ArabicNumbers.formatDate(
                            DateFormat('yyyy/MM/dd').format(paymentDate)),
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
                    maxLines: 2,
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
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  final payment = DebtPaymentModel(
                    commitmentId: commitment.id!,
                    amount: double.parse(amountController.text),
                    paymentDate: paymentDate,
                    paymentMethod: paymentMethod,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                  await ref
                      .read(commitmentsNotifierProvider.notifier)
                      .addPayment(payment);
                  
                  // Refresh related providers
                  ref.invalidate(paymentsProvider(commitment.id!));
                  ref.invalidate(commitmentProvider(commitment.id!));
                  ref.invalidate(commitmentsProvider); // Also refresh the main list
                  ref.invalidate(debtsToMeProvider);
                  ref.invalidate(debtsFromMeProvider);
                  ref.invalidate(totalDebtToMeProvider);
                  ref.invalidate(totalDebtFromMeProvider);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CommitmentModel commitment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الدين'),
        content: const Text('هل أنت متأكد من حذف هذا الدين وجميع دفعاته؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(commitmentsNotifierProvider.notifier)
                  .deleteCommitment(commitment.id!);
              
              // Refresh related providers
              ref.invalidate(commitmentsProvider);
              ref.invalidate(debtsToMeProvider);
              ref.invalidate(debtsFromMeProvider);
              ref.invalidate(totalDebtToMeProvider);
              ref.invalidate(totalDebtFromMeProvider);
              
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
