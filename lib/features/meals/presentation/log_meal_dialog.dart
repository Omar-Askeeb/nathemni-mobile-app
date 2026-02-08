import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/meal_model.dart';
import '../providers/meals_providers.dart';

class LogMealDialog extends ConsumerStatefulWidget {
  final Meal meal;

  const LogMealDialog({super.key, required this.meal});

  @override
  ConsumerState<LogMealDialog> createState() => _LogMealDialogState();
}

class _LogMealDialogState extends ConsumerState<LogMealDialog> {
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Lunch'; // Default
  final TextEditingController _notesController = TextEditingController();

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  final Map<String, String> _typeTranslations = {
    'Breakfast': 'فطور',
    'Lunch': 'غذاء',
    'Dinner': 'عشاء',
    'Snack': 'وجبة خفيفة',
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveLog() async {
    final log = MealLog(
      userId: 1, // Default user
      mealId: widget.meal.id!,
      mealType: _selectedType,
      eatenAt: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    final repository = ref.read(mealsRepositoryProvider);
    await repository.insertMealLog(log);
    
    // Refresh logs provider
    ref.refresh(mealLogsProvider);
    ref.refresh(lastEatenProvider(widget.meal.id!));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الوجبة بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تسجيل وجبة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوجبة: ${widget.meal.name}'),
            const SizedBox(height: 16),
            
            // Date Picker
            ListTile(
              title: const Text('التاريخ والوقت'),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () {
                _selectDate(context).then((_) => _selectTime(context));
              },
            ),
            const SizedBox(height: 16),

            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الوجبة',
                border: OutlineInputBorder(),
              ),
              items: _mealTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_typeTranslations[type] ?? type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saveLog,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
