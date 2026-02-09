import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/common_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../people/data/person_model.dart';
import '../../people/providers/people_providers.dart';
import '../data/tool_extension_model.dart';
import '../data/tool_model.dart';
import '../data/tool_transaction_model.dart';
import '../providers/tools_providers.dart';
import 'widgets/extension_list_item.dart';

class RentLendScreen extends ConsumerStatefulWidget {
  final int toolId;

  const RentLendScreen({super.key, required this.toolId});

  @override
  ConsumerState<RentLendScreen> createState() => _RentLendScreenState();
}

class _RentLendScreenState extends ConsumerState<RentLendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _dailyRateController = TextEditingController();

  int? _selectedPersonId;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  final Set<int> _selectedExtensionIds = {};
  bool _isLoading = false;
  String _transactionType = 'rent'; // rent or lend

  @override
  void dispose() {
    _notesController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolAsync = ref.watch(toolByIdProvider(widget.toolId));
    final extensionsAsync = ref.watch(availableExtensionsProvider(widget.toolId));
    final peopleAsync = ref.watch(peopleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأجير / إعارة'),
      ),
      body: toolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (tool) {
          if (tool == null) {
            return const Center(child: Text('المعدة غير موجودة'));
          }
          if (!tool.isAvailable) {
            return const Center(child: Text('المعدة غير متوفرة حالياً'));
          }

                final isRental = _transactionType == 'rent';
                final dailyRate = double.tryParse(_dailyRateController.text) ?? 0;
                final totalDays = _dueDate.difference(_startDate).inDays;
                final days = totalDays < 1 ? 1 : totalDays;
                final totalPrice = dailyRate * days;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tool Info
                _buildToolInfoCard(context, tool),
                const SizedBox(height: 16),

                // Transaction Type Selection
                Text(
                  'نوع العملية *',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeOption(
                        context,
                        'تأجير',
                        'بمقابل مادي',
                        Icons.attach_money,
                        'rent',
                        AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeOption(
                        context,
                        'إعارة',
                        'مجانية',
                        Icons.handshake,
                        'lend',
                        AppTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Daily Rate (only for rental)
                if (isRental) ...[
                  TextFormField(
                    controller: _dailyRateController,
                    decoration: const InputDecoration(
                      labelText: 'سعر الإيجار اليومي (د.ل) *',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'أدخل سعر الإيجار اليومي',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (_transactionType == 'rent') {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال سعر الإيجار';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'يجب أن يكون السعر أكبر من صفر';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Person Selection
                Text(
                  'الشخص المستلم *',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                peopleAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ: $e'),
                  data: (people) {
                    if (people.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.person_off, size: 32, color: AppTheme.textDisabled),
                              const SizedBox(height: 8),
                              const Text('لا يوجد أشخاص مسجلون'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  // Navigate to add person
                                },
                                child: const Text('أضف شخصاً جديداً'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: _selectedPersonId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: 'اختر الشخص',
                      ),
                      items: people.map((person) {
                        return DropdownMenuItem(
                          value: person.id,
                          child: Text(person.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPersonId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار الشخص';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        context,
                        'تاريخ البداية',
                        _startDate,
                        (date) {
                          setState(() {
                            _startDate = date;
                            if (_dueDate.isBefore(_startDate)) {
                              _dueDate = _startDate.add(const Duration(days: 1));
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        context,
                        'تاريخ الإرجاع المتوقع',
                        _dueDate,
                        (date) {
                          setState(() => _dueDate = date);
                        },
                        firstDate: _startDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Extensions Selection
                extensionsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (extensions) {
                    if (extensions.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الملحقات المتوفرة',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...extensions.map((ext) => ExtensionListItem(
                              extension: ext,
                              selectable: true,
                              selected: _selectedExtensionIds.contains(ext.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedExtensionIds.add(ext.id!);
                                  } else {
                                    _selectedExtensionIds.remove(ext.id);
                                  }
                                });
                              },
                            )),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

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

                // Price Summary (for rentals)
                if (isRental) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملخص التكلفة',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Divider(),
                          _buildPriceRow(context, 'سعر المعدة اليومي', dailyRate),
                          _buildPriceRow(context, 'عدد الأيام', days.toDouble(), isCount: true),
                          const Divider(),
                          _buildPriceRow(context, 'الإجمالي', totalPrice, isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _submitTransaction(tool),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isRental ? Icons.attach_money : Icons.handshake),
                    label: Text(isRental ? 'تأكيد التأجير' : 'تأكيد الإعارة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String type,
    Color color,
  ) {
    final isSelected = _transactionType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _transactionType = type;
          if (type == 'lend') {
            _dailyRateController.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? color : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? color : AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolInfoCard(BuildContext context, ToolModel tool) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.construction, color: AppTheme.primaryDark),
        ),
        title: Text(tool.name),
        subtitle: tool.cost > 0
            ? Text('التكلفة: ${tool.cost.toStringAsFixed(0)} د.ل')
            : null,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged, {
    DateTime? firstDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('yyyy-MM-dd').format(value)),
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

  Future<void> _submitTransaction(ToolModel tool) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPersonId == null) return;

    setState(() => _isLoading = true);

    final userId = ref.read(currentUserIdProvider);
    final dailyRate = double.tryParse(_dailyRateController.text) ?? 0;

    // Extensions cost is purchase cost, not rental price, so we don't add it to the daily rate
    double extensionsPrice = 0;

    final transaction = ToolTransactionModel(
      userId: userId,
      toolId: widget.toolId,
      personId: _selectedPersonId!,
      transactionType: _transactionType,
      startDate: _startDate,
      dueDate: _dueDate,
      dailyPrice: dailyRate,
      extensionsPrice: extensionsPrice,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await ref.read(transactionsNotifierProvider.notifier).createTransaction(
            transaction,
            _selectedExtensionIds.toList(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tool.isRental ? 'تم تسجيل التأجير بنجاح' : 'تم تسجيل الإعارة بنجاح',
            ),
          ),
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
