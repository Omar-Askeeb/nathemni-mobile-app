import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/car_providers.dart';
import '../data/car_model.dart';
import '../data/car_document_model.dart';
import 'oil_change_screen.dart';
import 'documents_screen.dart';

class CarDashboardScreen extends ConsumerWidget {
  const CarDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(carsProvider);
    final expiringSoonAsync = ref.watch(expiringSoonDocumentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السيارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddCarDialog(context),
            tooltip: 'إضافة سيارة',
          ),
        ],
      ),
      body: carsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ: $error'),
        ),
        data: (cars) {
          if (cars.isEmpty) {
            return _buildEmptyState(context);
          }

          // Manage selected car state
          final selectedCarId = ref.watch(selectedCarIdProvider);
          final car = cars.firstWhere(
            (c) => c.id == selectedCarId,
            orElse: () => cars.first,
          );

          // Update provider if not set or if car was deleted/changed
          if (selectedCarId == null || !cars.any((c) => c.id == selectedCarId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedCarIdProvider.notifier).state = car.id;
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(carsProvider);
              ref.invalidate(expiringSoonDocumentsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cars.length > 1) ...[
                    _buildCarSelector(context, ref, cars, car.id),
                    const SizedBox(height: 16),
                  ],
                  // Car Info Card
                  _buildCarInfoCard(context, car),
                  const SizedBox(height: 16),

                  // Expiring Soon Alerts
                  expiringSoonAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (expiring) {
                      if (expiring.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _buildExpiringAlerts(context, expiring, cars),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Quick Actions
                  Text(
                    'الإجراءات السريعة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, car.id),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCarDialog(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: AppTheme.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد سيارات مسجلة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة سيارتك للبدء',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCarDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة سيارة'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarSelector(
      BuildContext context, WidgetRef ref, List<Car> cars, int? selectedId) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cars.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final car = cars[index];
          final isSelected = car.id == selectedId;
          return ChoiceChip(
            label: Text(car.name),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(selectedCarIdProvider.notifier).state = car.id;
              }
            },
            selectedColor: AppTheme.primaryDark.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarInfoCard(BuildContext context, Car car) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppTheme.primaryDark,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (car.model != null)
                        Text(
                          car.model!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (car.plateNumber != null || car.currentOdometer != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (car.plateNumber != null)
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'رقم اللوحة',
                        car.plateNumber!,
                        Icons.pin,
                      ),
                    ),
                  if (car.currentOdometer != null)
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'العداد الحالي',
                        '${car.currentOdometer!.toStringAsFixed(0)} كم',
                        Icons.speed,
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

  Widget _buildInfoItem(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpiringAlerts(
      BuildContext context, List<CarDocument> documents, List<Car> cars) {
    return Card(
      color: AppTheme.warning.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text(
                  'تنبيهات قريبة الانتهاء',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.warning,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...documents.map((doc) {
              final car = cars.firstWhere((c) => c.id == doc.carId,
                  orElse: () => cars.first);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${doc.documentType.nameAr} (${car.name}) ينتهي في ${doc.expiryDate.toIso8601String().split('T')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, int carId) {
    return Column(
      children: [
        _buildActionCard(
          context,
          title: 'تغيير الزيت',
          subtitle: 'سجل عملية تغيير زيت جديدة',
          icon: Icons.oil_barrel,
          color: AppTheme.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OilChangeScreen(carId: carId),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context,
          title: 'أوراق السيارة',
          subtitle: 'إدارة التأمين والفحص والضرائب',
          icon: Icons.description,
          color: AppTheme.primaryLight,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentsScreen(carId: carId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class AddCarDialog extends ConsumerStatefulWidget {
  const AddCarDialog({super.key});

  @override
  ConsumerState<AddCarDialog> createState() => _AddCarDialogState();
}

class _AddCarDialogState extends ConsumerState<AddCarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _odometerController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateNumberController.dispose();
    _odometerController.dispose();
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
                    'إضافة سيارة',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Car Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم السيارة *',
                      prefixIcon: Icon(Icons.directions_car),
                      hintText: 'مثال: تويوتا كورولا',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم السيارة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Model
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'الموديل',
                      prefixIcon: Icon(Icons.category),
                      hintText: 'مثال: 2020',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Year
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'سنة الصنع',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Plate Number
                  TextFormField(
                    controller: _plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.pin),
                      hintText: 'مثال: أ ب ج 1234',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Odometer
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'العداد الحالي (كم)',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
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
                        onPressed: _saveCar,
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

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    final car = Car(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1, // TODO: Get from auth provider
      name: _nameController.text,
      model: _modelController.text.isNotEmpty ? _modelController.text : null,
      year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
      plateNumber: _plateNumberController.text.isNotEmpty ? _plateNumberController.text : null,
      currentOdometer: _odometerController.text.isNotEmpty ? double.tryParse(_odometerController.text) : null,
    );

    try {
      await ref.read(carManagementNotifierProvider.notifier).addCar(car);

      if (mounted) {
        Navigator.pop(context);
        // Schedule provider invalidation for after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(carsProvider);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة السيارة بنجاح')),
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
