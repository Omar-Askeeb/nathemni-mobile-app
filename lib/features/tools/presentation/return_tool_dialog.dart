import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tool_transaction_model.dart';
import '../providers/tools_providers.dart';

class ReturnToolDialog extends ConsumerStatefulWidget {
  final ToolTransactionModel transaction;
  final int toolId;

  const ReturnToolDialog({
    super.key,
    required this.transaction,
    required this.toolId,
  });

  @override
  ConsumerState<ReturnToolDialog> createState() => _ReturnToolDialogState();
}

class _ReturnToolDialogState extends ConsumerState<ReturnToolDialog> {
  final _lateFeeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.transaction.notes ?? '';
  }

  @override
  void dispose() {
    _lateFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final now = DateTime.now();
    final actualDays = now.difference(transaction.startDate).inDays;
    final days = actualDays < 1 ? 1 : actualDays;
    final subtotal = transaction.combinedDailyRate * days;
    final lateFee = double.tryParse(_lateFeeController.text) ?? 0;
    final totalAmount = subtotal + lateFee;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إرجاع المعدة',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Transaction Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: transaction.isRental
                                    ? AppTheme.primaryDark.withOpacity(0.1)
                                    : AppTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                transaction.isRental ? Icons.attach_money : Icons.handshake,
                                color: transaction.isRental ? AppTheme.primaryDark : AppTheme.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.toolName ?? 'معدة',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    transaction.personName ?? 'شخص',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(context, 'تاريخ البداية', dateFormat.format(transaction.startDate)),
                        _buildInfoRow(context, 'تاريخ الإرجاع المتوقع', dateFormat.format(transaction.dueDate)),
                        _buildInfoRow(context, 'تاريخ الإرجاع الفعلي', dateFormat.format(now)),
                        _buildInfoRow(context, 'عدد الأيام', '$days يوم'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Overdue Warning
                if (transaction.isOverdue) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تأخير ${transaction.daysOverdue} يوم عن موعد الإرجاع',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price Summary (for rentals)
                if (transaction.isRental) ...[
                  Text(
                    'ملخص التكلفة',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPriceRow(context, 'السعر اليومي (معدة + ملحقات)',
                              transaction.combinedDailyRate),
                          _buildPriceRow(context, 'عدد الأيام', days.toDouble(), isCount: true),
                          _buildPriceRow(context, 'المجموع الفرعي', subtotal),
                          const Divider(),
                          // Late Fee Input
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'رسوم التأخير',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  controller: _lateFeeController,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    suffixText: 'د.ل',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildPriceRow(context, 'الإجمالي', totalAmount, isTotal: true),
                          
                          // Payment Confirmation Checkbox
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('تأكيد استلام المبلغ'),
                            subtitle: const Text('سيتم تسجيل المبلغ في الإيرادات فقط عند التحديد'),
                            value: _isPaid,
                            onChanged: (val) => setState(() => _isPaid = val ?? false),
                            activeColor: AppTheme.success,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _returnTool,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('تأكيد الإرجاع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double value,
      {bool isTotal = false, bool isCount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            isCount ? '${value.toInt()}' : '${value.toStringAsFixed(0)} د.ل',
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _returnTool() async {
    setState(() => _isLoading = true);

    final lateFee = double.tryParse(_lateFeeController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    try {
      await ref.read(transactionsNotifierProvider.notifier).returnTool(
            widget.transaction.id!,
            widget.toolId,
            lateFee: lateFee,
            notes: notes,
            isPaid: _isPaid,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرجاع المعدة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
