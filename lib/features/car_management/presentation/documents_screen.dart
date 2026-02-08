import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/car_document_model.dart';
import '../providers/car_providers.dart';
import 'document_history_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  final int carId;

  const DocumentsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(carDocumentsProvider(carId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('أوراق السيارة'),
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('خطأ: $error')),
        data: (documents) {
          // Group documents by type
          final insurance = documents.where((d) => d.documentType == CarDocumentType.insurance).toList();
          final tax = documents.where((d) => d.documentType == CarDocumentType.tax).toList();
          final inspection = documents.where((d) => d.documentType == CarDocumentType.inspection).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDocumentSection(
                  context,
                  ref,
                  'التأمين الإجباري',
                  CarDocumentType.insurance,
                  insurance,
                  Icons.shield,
                  AppTheme.primaryDark,
                ),
                const SizedBox(height: 16),
                _buildDocumentSection(
                  context,
                  ref,
                  'البل (ضريبة الطريق)',
                  CarDocumentType.tax,
                  tax,
                  Icons.receipt_long,
                  AppTheme.warning,
                ),
                const SizedBox(height: 16),
                _buildDocumentSection(
                  context,
                  ref,
                  'الفحص الفني',
                  CarDocumentType.inspection,
                  inspection,
                  Icons.build,
                  AppTheme.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    CarDocumentType type,
    List<CarDocument> documents,
    IconData icon,
    Color color,
  ) {
    final latest = documents.isNotEmpty ? documents.first : null;

    return Card(
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAddDocumentDialog(context, ref, type),
                ),
              ],
            ),
            if (latest != null) ...[
              const Divider(height: 24),
              _buildDocumentInfo(context, latest),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'لا توجد سجلات',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
            if (documents.length > 1) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentHistoryScreen(
                        carId: carId,
                        documentType: type,
                      ),
                    ),
                  );
                },
                child: Text('عرض السجل الكامل (${documents.length})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentInfo(BuildContext context, CarDocument doc) {
    final isExpiringSoon = doc.isExpiringSoon;
    final isExpired = doc.isExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ التجديد',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(doc.renewalDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ الانتهاء',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(doc.expiryDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? AppTheme.error
                              : isExpiringSoon
                                  ? AppTheme.warning
                                  : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'القيمة',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${doc.cost.toStringAsFixed(2)} ${doc.currency}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            if (doc.placeName != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المكان',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      doc.placeName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (isExpiringSoon || isExpired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isExpired ? AppTheme.error : AppTheme.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isExpired ? Icons.error : Icons.warning_amber,
                  size: 16,
                  color: isExpired ? AppTheme.error : AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpired ? 'منتهي الصلاحية' : 'ينتهي قريباً',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired ? AppTheme.error : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddDocumentDialog(
    BuildContext context,
    WidgetRef ref,
    CarDocumentType type,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddDocumentDialog(carId: carId, documentType: type),
    );
  }
}

class AddDocumentDialog extends ConsumerStatefulWidget {
  final int carId;
  final CarDocumentType documentType;

  const AddDocumentDialog({
    super.key,
    required this.carId,
    required this.documentType,
  });

  @override
  ConsumerState<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends ConsumerState<AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _placeContactController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _renewalDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  String _paymentMethod = 'cash';
  String _selectedCategory = 'fuel'; // Default expense category

  @override
  void dispose() {
    _costController.dispose();
    _placeNameController.dispose();
    _placeContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة ${widget.documentType.nameAr}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Renewal Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('تاريخ التجديد'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_renewalDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _renewalDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _renewalDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Expiry Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('تاريخ الانتهاء'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_expiryDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _expiryDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cost
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'القيمة (LYD) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال القيمة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Place Name
                  TextFormField(
                    controller: _placeNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المكتب/المكان',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Place Contact
                  TextFormField(
                    controller: _placeContactController,
                    decoration: const InputDecoration(
                      labelText: 'رقم المكتب/التواصل',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('كاش 💵')),
                      DropdownMenuItem(value: 'card', child: Text('بطاقة 💳')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveDocument,
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.parse(_costController.text);

    final document = CarDocument(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      carId: widget.carId,
      userId: 1, // TODO: Get from provider
      documentType: widget.documentType,
      renewalDate: _renewalDate,
      expiryDate: _expiryDate,
      cost: cost,
      placeName: _placeNameController.text.isNotEmpty ? _placeNameController.text : null,
      placeContact: _placeContactController.text.isNotEmpty ? _placeContactController.text : null,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    try {
      await ref.read(carManagementNotifierProvider.notifier).addCarDocument(
            document: document,
            expenseCategoryId: _selectedCategory,
          );

      if (mounted) {
        Navigator.pop(context);
        // Refresh documents and the main dashboard expiring soon alerts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(carDocumentsProvider(widget.carId));
          ref.invalidate(expiringSoonDocumentsProvider);
          ref.invalidate(carsProvider);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الوثيقة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
