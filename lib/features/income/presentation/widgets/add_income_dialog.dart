import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/income_model.dart';
import '../../providers/income_providers.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../bank_accounts/providers/bank_accounts_providers.dart';
import '../../../bank_accounts/data/bank_account_model.dart';
import '../../../../core/theme/app_theme.dart';

class AddIncomeDialog extends ConsumerStatefulWidget {
  final IncomeModel? income;

  const AddIncomeDialog({super.key, this.income});

  @override
  ConsumerState<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _sourceType = 'other';
  String _paymentMethod = 'cash';
  int? _selectedBankAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      _amountController.text = widget.income!.amount.toString();
      _descriptionController.text = widget.income!.description ?? '';
      _selectedDate = widget.income!.entryDate;
      _sourceType = widget.income!.sourceType;
      _paymentMethod = widget.income!.paymentMethod;
      _selectedBankAccountId = widget.income!.bankAccountId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.income != null;
    final bankAccountsAsync = ref.watch(bankAccountsProvider);

    return AlertDialog(
      title: Text(isEdit ? 'تعديل إيراد' : 'إضافة إيراد جديد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (د.ل)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال المبلغ';
                  if (double.tryParse(value) == null) return 'مبلغ غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Source Type
              DropdownButtonFormField<String>(
                value: _sourceType,
                decoration: const InputDecoration(
                  labelText: 'المصدر',
                  prefixIcon: Icon(Icons.source),
                ),
                items: const [
                  DropdownMenuItem(value: 'salary', child: Text('راتب')),
                  DropdownMenuItem(value: 'business', child: Text('عمل خاص')),
                  DropdownMenuItem(value: 'tool_rental', child: Text('إيجار معدات')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (value) => setState(() => _sourceType = value!),
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ar'),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(ArabicNumbers.formatDate(DateFormat('yyyy/MM/dd').format(_selectedDate))),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('نقداً'), icon: Icon(Icons.money)),
                  ButtonSegment(value: 'bank_transfer', label: Text('مصرفي'), icon: Icon(Icons.account_balance)),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (set) => setState(() => _paymentMethod = set.first),
              ),
              const SizedBox(height: 16),

              // Bank Account
              if (_paymentMethod == 'bank_transfer') ...[
                bankAccountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const Text(
                        'لا توجد حسابات مصرفية مسجلة',
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: _selectedBankAccountId,
                      decoration: const InputDecoration(
                        labelText: 'الحساب المصرفي',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      items: accounts.map((acc) {
                        final bank = BankInfo.fromId(acc.bankId);
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Text('${bank?.nameArabic ?? acc.bankId} - ${acc.accountNumber}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBankAccountId = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل الحسابات'),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'التوضيح / ملاحظات',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentMethod == 'bank_transfer' && _selectedBankAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الحساب المصرفي')));
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    final income = IncomeModel(
      id: widget.income?.id,
      userId: userId,
      amount: double.parse(_amountController.text),
      sourceType: _sourceType,
      entryDate: _selectedDate,
      paymentMethod: _paymentMethod,
      bankAccountId: _paymentMethod == 'bank_transfer' ? _selectedBankAccountId : null,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    try {
      if (widget.income == null) {
        await ref.read(incomeNotifierProvider.notifier).addIncome(income);
      } else {
        await ref.read(incomeNotifierProvider.notifier).updateIncome(income);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}
