import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bank_account_model.dart';
import '../providers/bank_accounts_providers.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/providers/common_providers.dart';

class BankAccountsScreen extends ConsumerStatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  ConsumerState<BankAccountsScreen> createState() =>
      _BankAccountsScreenState();
}

class _BankAccountsScreenState extends ConsumerState<BankAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(bankAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحسابات المصرفية'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildAccountsList(context, accounts);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حسابات مصرفية',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة حساب جديد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(
      BuildContext context, List<BankAccountModel> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final bankInfo = BankInfo.fromId(account.bankId);
        return _buildAccountCard(context, account, bankInfo);
      },
    );
  }

  Widget _buildAccountCard(
      BuildContext context, BankAccountModel account, BankInfo? bankInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank name and logo
            Row(
              children: [
                if (bankInfo != null)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        bankInfo.logoPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.account_balance,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankInfo?.nameArabic ?? 'مصرف',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (account.branch != null)
                        Text(
                          'فرع: ${account.branch}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditDialog(context, account);
                    } else if (value == 'delete') {
                      _confirmDelete(context, account);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Account number
            _buildInfoRow(
              context,
              'رقم الحساب',
              ArabicNumbers.convert(account.accountNumber),
              () => _copyToClipboard(context, account.accountNumber, 'رقم الحساب'),
            ),
            
            // IBAN
            if (account.iban != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'IBAN',
                account.iban!,
                () => _copyToClipboard(context, account.iban!, 'IBAN'),
              ),
            ],
            
            // Notes
            if (account.notes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.notes!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, VoidCallback onCopy) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: 'نسخ',
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, BankAccountModel? account) {
    final isEdit = account != null;
    String? selectedBankId = account?.bankId;
    final branchController = TextEditingController(text: account?.branch ?? '');
    final accountNumberController =
        TextEditingController(text: account?.accountNumber ?? '');
    final ibanController = TextEditingController(text: account?.iban ?? '');
    final notesController = TextEditingController(text: account?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل الحساب' : 'إضافة حساب جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bank dropdown with logo
                  DropdownButtonFormField<String>(
                    value: selectedBankId,
                    decoration: const InputDecoration(
                      labelText: 'المصرف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return BankInfo.allBanks.map<Widget>((bank) {
                        return Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  bank.logoPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.account_balance,
                                    size: 20,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bank.nameArabic,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    items: BankInfo.allBanks.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank.id,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  bank.logoPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.account_balance,
                                    size: 20,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bank.nameArabic,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBankId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المصرف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Branch
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextFormField(
                      controller: branchController,
                      decoration: const InputDecoration(
                        labelText: 'الفرع (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      keyboardType: TextInputType.text,
                      maxLength: 50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Number
                  TextFormField(
                    controller: accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الحساب',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 30,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الحساب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // IBAN
                  TextFormField(
                    controller: ibanController,
                    decoration: const InputDecoration(
                      labelText: 'IBAN (اختياري)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.text,
                    maxLength: 34,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      maxLength: 200,
                    ),
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
                  await _saveBankAccount(
                    account,
                    selectedBankId!,
                    branchController.text.isEmpty
                        ? null
                        : branchController.text,
                    accountNumberController.text,
                    ibanController.text.isEmpty ? null : ibanController.text,
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

  void _confirmDelete(BuildContext context, BankAccountModel account) {
    final bankInfo = BankInfo.fromId(account.bankId);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text(
          'هل أنت متأكد من حذف الحساب ${ArabicNumbers.convert(account.accountNumber)} في ${bankInfo?.nameArabic ?? "المصرف"}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAccount(account.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBankAccount(
    BankAccountModel? existingAccount,
    String bankId,
    String? branch,
    String accountNumber,
    String? iban,
    String? notes,
  ) async {
    try {
      final repository = ref.read(bankAccountsRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      if (existingAccount != null) {
        // Update existing
        await repository.updateBankAccount(
          existingAccount.copyWith(
            bankId: bankId,
            branch: branch,
            accountNumber: accountNumber,
            iban: iban,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الحساب بنجاح')),
          );
        }
      } else {
        // Add new
        final newAccount = BankAccountModel(
          userId: userId,
          bankId: bankId,
          branch: branch,
          accountNumber: accountNumber,
          iban: iban,
          notes: notes,
        );

        await repository.addBankAccount(newAccount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الحساب بنجاح')),
          );
        }
      }

      // Refresh the list
      ref.invalidate(bankAccountsProvider);
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

  Future<void> _deleteAccount(int id) async {
    try {
      final repository = ref.read(bankAccountsRepositoryProvider);
      await repository.deleteBankAccount(id);
      ref.invalidate(bankAccountsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب بنجاح')),
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
}
