import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/tool_model.dart';
import '../providers/tools_providers.dart';
import 'add_edit_tool_dialog.dart';
import 'add_extension_dialog.dart';
import 'rent_lend_screen.dart';
import 'return_tool_dialog.dart';
import 'widgets/extension_list_item.dart';
import 'widgets/transaction_card.dart';

class ToolDetailsScreen extends ConsumerWidget {
  final int toolId;

  const ToolDetailsScreen({super.key, required this.toolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolAsync = ref.watch(toolByIdProvider(toolId));
    final extensionsAsync = ref.watch(toolExtensionsProvider(toolId));
    final transactionsAsync = ref.watch(toolTransactionsProvider(toolId));
    final activeTransactionAsync = ref.watch(activeTransactionProvider(toolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المعدة'),
        actions: [
          toolAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tool) {
              if (tool == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AddEditToolDialog(tool: tool),
                ),
                tooltip: 'تعديل',
              );
            },
          ),
        ],
      ),
      body: toolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (tool) {
          if (tool == null) {
            return const Center(child: Text('المعدة غير موجودة'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(toolByIdProvider(toolId));
              ref.invalidate(toolExtensionsProvider(toolId));
              ref.invalidate(toolTransactionsProvider(toolId));
              ref.invalidate(activeTransactionProvider(toolId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool Info Card
                  _buildToolInfoCard(context, tool),
                  const SizedBox(height: 16),

                  // Active Transaction Alert
                  activeTransactionAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (transaction) {
                      if (transaction == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          TransactionCard(
                            transaction: transaction,
                            onReturn: () => showDialog(
                              context: context,
                              builder: (_) => ReturnToolDialog(
                                transaction: transaction,
                                toolId: toolId,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Quick Actions
                  if (tool.isAvailable) ...[
                    _buildQuickActions(context, tool),
                    const SizedBox(height: 24),
                  ],

                  // Extensions Section
                  _buildSectionHeader(context, 'الملحقات', onAdd: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddExtensionDialog(toolId: toolId),
                    );
                  }),
                  const SizedBox(height: 8),
                  extensionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ: $e'),
                    data: (extensions) {
                      if (extensions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.extension_outlined,
                                    size: 48,
                                    color: AppTheme.textDisabled,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لا توجد ملحقات',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: extensions
                            .map((ext) => ExtensionListItem(
                                  extension: ext,
                                  onEdit: () => showDialog(
                                    context: context,
                                    builder: (_) => AddExtensionDialog(
                                      toolId: toolId,
                                      extension: ext,
                                    ),
                                  ),
                                  onDelete: () =>
                                      _confirmDeleteExtension(context, ref, ext.id!, toolId),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Transaction History Section
                  _buildSectionHeader(context, 'سجل العمليات'),
                  const SizedBox(height: 8),
                  transactionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ: $e'),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history_outlined,
                                    size: 48,
                                    color: AppTheme.textDisabled,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لا توجد عمليات سابقة',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: transactions.take(5).map((t) {
                          return TransactionCard(
                            transaction: t,
                            onReturn: t.isActive
                                ? () => showDialog(
                                      context: context,
                                      builder: (_) => ReturnToolDialog(
                                        transaction: t,
                                        toolId: toolId,
                                      ),
                                    )
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80), // FAB space
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: toolAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (tool) {
          if (tool == null || !tool.isAvailable) return null;
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentLendScreen(toolId: toolId),
              ),
            ),
            icon: const Icon(Icons.handshake),
            label: Text(tool.isRental ? 'تأجير' : 'إعارة'),
          );
        },
      ),
    );
  }

  Widget _buildToolInfoCard(BuildContext context, ToolModel tool) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _getStatusColor(tool.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.construction,
                    color: _getStatusColor(tool.status),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(context, tool),
                          const SizedBox(width: 8),
                          if (tool.dailyPrice > 0)
                            Text(
                              '${tool.dailyPrice.toStringAsFixed(0)} د.ل/يوم',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tool.description != null) ...[
              const Divider(height: 24),
              Text(
                tool.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (tool.notes != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tool.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ToolModel tool) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(tool.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tool.statusArabic,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(tool.status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ToolModel tool) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentLendScreen(toolId: toolId),
              ),
            ),
            icon: Icon(
              tool.isRental ? Icons.attach_money : Icons.handshake,
              color: tool.isRental ? AppTheme.primaryDark : AppTheme.accent,
            ),
            label: Text(tool.isRental ? 'تأجير' : 'إعارة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tool.isRental ? AppTheme.primaryDark : AppTheme.accent,
              side: BorderSide(
                color: tool.isRental ? AppTheme.primaryDark : AppTheme.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
            color: AppTheme.primaryDark,
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.success;
      case 'rented':
        return AppTheme.primaryDark;
      case 'lent':
        return AppTheme.accent;
      case 'maintenance':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _confirmDeleteExtension(
      BuildContext context, WidgetRef ref, int extensionId, int toolId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الملحق'),
        content: const Text('هل أنت متأكد من حذف هذا الملحق؟'),
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
                    .read(extensionsNotifierProvider.notifier)
                    .deleteExtension(extensionId, toolId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الملحق بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
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
