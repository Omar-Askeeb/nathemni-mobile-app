import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/data/expense_local_model.dart';
import '../data/oil_change_model.dart';
import '../providers/car_providers.dart';

class OilChangeScreen extends ConsumerStatefulWidget {
  final int carId;

  const OilChangeScreen({super.key, required this.carId});

  @override
  ConsumerState<OilChangeScreen> createState() => _OilChangeScreenState();
}

class _OilChangeScreenState extends ConsumerState<OilChangeScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(oilChangeHistoryProvider(widget.carId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تغيير الزيت'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('خطأ: $error')),
        data: (history) {
          return Column(
            children: [
              Expanded(
                child: history.isEmpty
                    ? _buildEmptyState(context)
                    : _buildHistoryList(context, history),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOilChangeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('تسجيل تغيير زيت'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.oil_barrel_outlined,
            size: 80,
            color: AppTheme.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات لتغيير الزيت',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتسجيل أول عملية تغيير زيت',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<OilChange> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final oilChange = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.oil_barrel,
                        color: AppTheme.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd').format(oilChange.changeDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${oilChange.odometer.toStringAsFixed(0)} كم',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${oilChange.cost.toStringAsFixed(2)} ${oilChange.currency}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (oilChange.oilType != null || oilChange.oilViscosity != null) ...[
                  const Divider(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (oilChange.oilType != null)
                        _buildChip(context, 'النوع: ${oilChange.oilType}'),
                      if (oilChange.oilViscosity != null)
                        _buildChip(context, 'اللزوجة: ${oilChange.oilViscosity}'),
                      if (oilChange.filterChanged)
                        _buildChip(context, 'تم تغيير الفلتر', color: AppTheme.success),
                    ],
                  ),
                ],
                if (oilChange.expectedDistance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'المسافة المتوقعة: ${oilChange.expectedDistance!.toStringAsFixed(0)} كم',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(BuildContext context, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryLight).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryDark,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  void _showAddOilChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddOilChangeDialog(carId: widget.carId),
    );
  }
}

class AddOilChangeDialog extends ConsumerStatefulWidget {
  final int carId;

  const AddOilChangeDialog({super.key, required this.carId});

  @override
  ConsumerState<AddOilChangeDialog> createState() => _AddOilChangeDialogState();
}

class _AddOilChangeDialogState extends ConsumerState<AddOilChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _oilTypeController = TextEditingController(text: 'Gastrol');
  final _viscosityController = TextEditingController(text: '10W40');
  final _expectedDistanceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _filterChanged = false;
  String _paymentMethod = 'cash';
  String _selectedCategory = 'fuel'; // Default expense category

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _oilTypeController.dispose();
    _viscosityController.dispose();
    _expectedDistanceController.dispose();
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
                    'تسجيل تغيير زيت',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  
                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('التاريخ'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Odometer
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'المسافة بالعداد (كم) *',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال المسافة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Cost
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (LYD) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال المبلغ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Oil Type
                  TextFormField(
                    controller: _oilTypeController,
                    decoration: const InputDecoration(
                      labelText: 'نوع الزيت',
                      prefixIcon: Icon(Icons.oil_barrel),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Viscosity
                  TextFormField(
                    controller: _viscosityController,
                    decoration: const InputDecoration(
                      labelText: 'درجة اللزوجة',
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Changed
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تم تغيير الفلتر مع الزيت'),
                    value: _filterChanged,
                    onChanged: (value) {
                      setState(() => _filterChanged = value ?? false);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Expected Distance
                  TextFormField(
                    controller: _expectedDistanceController,
                    decoration: const InputDecoration(
                      labelText: 'المسافة التي يقطعها الزيت (كم)',
                      prefixIcon: Icon(Icons.route),
                    ),
                    keyboardType: TextInputType.number,
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
                        onPressed: _saveOilChange,
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

  Future<void> _saveOilChange() async {
    if (!_formKey.currentState!.validate()) return;

    final odometer = double.parse(_odometerController.text);
    final cost = double.parse(_costController.text);
    final expectedDistance = _expectedDistanceController.text.isNotEmpty
        ? double.parse(_expectedDistanceController.text)
        : null;

    final oilChange = OilChange(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      carId: widget.carId,
      userId: 1, // TODO: Get from provider
      changeDate: _selectedDate,
      odometer: odometer,
      cost: cost,
      oilType: _oilTypeController.text.isNotEmpty ? _oilTypeController.text : null,
      oilViscosity: _viscosityController.text.isNotEmpty ? _viscosityController.text : null,
      filterChanged: _filterChanged,
      expectedDistance: expectedDistance,
      nextChangeOdometer: expectedDistance != null ? odometer + expectedDistance : null,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    try {
      await ref.read(carManagementNotifierProvider.notifier).addOilChange(
            oilChange: oilChange,
            expenseCategoryId: _selectedCategory,
          );

      if (mounted) {
        Navigator.pop(context);
        // Refresh history and the main dashboard stats
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(oilChangeHistoryProvider(widget.carId));
          ref.invalidate(carsProvider);
          ref.invalidate(expiringSoonDocumentsProvider);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل تغيير الزيت بنجاح')),
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
