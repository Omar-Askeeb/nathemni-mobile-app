import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/commitment_model.dart';
import '../providers/commitments_providers.dart';
import '../../people/data/person_model.dart';
import '../../people/providers/people_providers.dart' hide currentUserIdProvider;
import '../../../core/navigation/app_drawer.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/providers/common_providers.dart';
import 'commitment_details_screen.dart';

class CommitmentsScreen extends ConsumerStatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  ConsumerState<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends ConsumerState<CommitmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDebtToMe = ref.watch(totalDebtToMeProvider);
    final totalDebtFromMe = ref.watch(totalDebtFromMeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الالتزامات والديون'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'ديون لي', icon: Icon(Icons.arrow_downward)),
            Tab(text: 'ديون علي', icon: Icon(Icons.arrow_upward)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Totals Card
          _buildTotalsCard(totalDebtToMe, totalDebtFromMe),
          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDebtsList(ref.watch(debtsToMeProvider), 'debt_to_me'),
                _buildDebtsList(ref.watch(debtsFromMeProvider), 'debt_from_me'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCommitmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalsCard(AsyncValue<double> toMe, AsyncValue<double> fromMe) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTotalItem(
              title: 'لي عند الناس',
              amount: toMe,
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTotalItem(
              title: 'علي للناس',
              amount: fromMe,
              color: Colors.red,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem({
    required String title,
    required AsyncValue<double> amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          amount.when(
            data: (value) => Text(
              '${ArabicNumbers.convert(value.toStringAsFixed(2))} د.ل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('خطأ'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(AsyncValue<List<CommitmentModel>> debtsAsync, String type) {
    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return _buildEmptyState(type);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) => _buildDebtCard(debts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
    );
  }

  Widget _buildEmptyState(String type) {
    final isDebtToMe = type == 'debt_to_me';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDebtToMe ? Icons.arrow_downward : Icons.arrow_upward,
            size: 80,
            color: (isDebtToMe ? Colors.green : Colors.red).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isDebtToMe ? 'لا توجد ديون لك' : 'لا توجد ديون عليك',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة دين',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(CommitmentModel commitment) {
    final isDebtToMe = commitment.type == 'debt_to_me';
    final color = isDebtToMe ? Colors.green : Colors.red;
    final paidAmount = commitment.paidAmount ?? 0;
    final progress = commitment.progressPercentage / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDetails(commitment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Text(
                      commitment.person?.name.isNotEmpty == true
                          ? commitment.person!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commitment.person?.name ?? 'غير معروف',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          commitment.title,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ArabicNumbers.convert(paidAmount.toStringAsFixed(0))}/${ArabicNumbers.convert(commitment.amount.toStringAsFixed(0))}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      Text(
                        'د.ل',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المتبقي: ${ArabicNumbers.convert(commitment.remainingAmount.toStringAsFixed(2))} د.ل',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(commitment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      commitment.statusArabic,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(commitment.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openDetails(CommitmentModel commitment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitmentDetailsScreen(commitmentId: commitment.id!),
      ),
    );
  }

  void _showAddCommitmentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = _tabController.index == 0 ? 'debt_to_me' : 'debt_from_me';
    PersonModel? selectedPerson;
    DateTime? selectedDueDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final peopleAsync = ref.watch(peopleProvider);
          
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('إضافة دين جديد'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Type
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'نوع الدين',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'debt_to_me',
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('دين لي (شخص مديون لي)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'debt_from_me',
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('دين علي (أنا مديون)'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => selectedType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Person
                        peopleAsync.when(
                          data: (people) {
                            if (people.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'لا يوجد أشخاص. أضف شخصاً من إدارة الأشخاص أولاً.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return DropdownButtonFormField<PersonModel>(
                              value: selectedPerson,
                              decoration: const InputDecoration(
                                labelText: 'الشخص *',
                                border: OutlineInputBorder(),
                              ),
                              items: people.map((person) {
                                return DropdownMenuItem(
                                  value: person,
                                  child: Text(person.name),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => selectedPerson = value),
                              validator: (v) => v == null ? 'اختر شخصاً' : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('خطأ في تحميل الأشخاص'),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان/السبب *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'أدخل العنوان' : null,
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
                            if (double.tryParse(v) == null) return 'مبلغ غير صحيح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Due date
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              locale: const Locale('ar'),
                            );
                            if (date != null) setState(() => selectedDueDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الاستحقاق (اختياري)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              selectedDueDate != null
                                  ? ArabicNumbers.formatDate(
                                      DateFormat('yyyy/MM/dd').format(selectedDueDate!))
                                  : 'غير محدد',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        TextFormField(
                          controller: descriptionController,
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
                    onPressed: selectedPerson == null
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(dialogContext);
                              final userId = ref.read(currentUserIdProvider);
                              final commitment = CommitmentModel(
                                userId: userId,
                                personId: selectedPerson!.id!,
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                type: selectedType,
                                amount: double.parse(amountController.text),
                                dueDate: selectedDueDate,
                              );
                              await ref
                                  .read(commitmentsNotifierProvider.notifier)
                                  .addCommitment(commitment);
                              
                              // Refresh related providers
                              ref.invalidate(debtsToMeProvider);
                              ref.invalidate(debtsFromMeProvider);
                              ref.invalidate(totalDebtToMeProvider);
                              ref.invalidate(totalDebtFromMeProvider);
                            }
                          },
                    child: const Text('إضافة'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
