import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tool_transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final ToolTransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onReturn;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = transaction.isActive;
    final isOverdue = transaction.isOverdue;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue ? AppTheme.error.withOpacity(0.05) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      transaction.isRental ? Icons.attach_money : Icons.handshake,
                      color: _getTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.toolName ?? 'معدة',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          transaction.personName ?? 'شخص',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const Divider(height: 24),
              // Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'من',
                      dateFormat.format(transaction.startDate),
                      Icons.play_arrow,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'إلى',
                      dateFormat.format(transaction.dueDate),
                      Icons.flag,
                    ),
                  ),
                  if (transaction.isRental)
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'المبلغ',
                        '${transaction.currentTotalAmount.toStringAsFixed(0)} د.ل',
                        Icons.payments,
                      ),
                    ),
                ],
              ),
              // Overdue Warning
              if (isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'متأخر بـ ${transaction.daysOverdue} يوم',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              // Return Button
              if (isActive && onReturn != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('إرجاع المعدة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: const BorderSide(color: AppTheme.success),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        transaction.statusArabic,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    return transaction.isRental ? AppTheme.primaryDark : AppTheme.accent;
  }

  Color _getStatusColor() {
    if (transaction.isOverdue) return AppTheme.error;
    switch (transaction.status) {
      case 'active':
        return AppTheme.success;
      case 'returned':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }
}
