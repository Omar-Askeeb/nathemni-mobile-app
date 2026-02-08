import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meal_model.dart';
import '../providers/meals_providers.dart';

class AddEditMealScreen extends ConsumerStatefulWidget {
  final Meal? meal;

  const AddEditMealScreen({super.key, this.meal});

  @override
  ConsumerState<AddEditMealScreen> createState() => _AddEditMealScreenState();
}

class _AddEditMealScreenState extends ConsumerState<AddEditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  // Custom Lists
  List<String> _selectedCategories = [];
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];

  final List<String> _availableCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Appetizers/Sides'
  ];

  final Map<String, String> _categoryTranslations = {
    'Breakfast': 'فطور',
    'Lunch': 'غذاء',
    'Dinner': 'عشاء',
    'Appetizers/Sides': 'مقبلات وجوانب',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal?.name ?? '');
    
    // Initialize Categories
    if (widget.meal != null) {
      _selectedCategories = List.from(widget.meal!.categories);
    }

    // Initialize Ingredients
    if (widget.meal != null && widget.meal!.ingredients.isNotEmpty) {
      for (var ingredient in widget.meal!.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }
    } else {
      _ingredientControllers.add(TextEditingController());
    }

    // Initialize Recipe Steps
    if (widget.meal != null && widget.meal!.recipeSteps.isNotEmpty) {
      for (var step in widget.meal!.recipeSteps) {
        _stepControllers.add(TextEditingController(text: step));
      }
    } else {
      _stepControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _ingredientControllers) c.dispose();
    for (var c in _stepControllers) c.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        final controller = _ingredientControllers.removeAt(index);
        controller.dispose();
      });
    } else {
      // Clear if it's the last one
      _ingredientControllers[0].clear();
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        final controller = _stepControllers.removeAt(index);
        controller.dispose();
      });
    } else {
      _stepControllers[0].clear();
    }
  }

  void _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تصنيف واحد على الأقل')),
      );
      return;
    }

    // Filter empty ingredients/steps
    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final recipeSteps = _stepControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final meal = Meal(
      id: widget.meal?.id,
      userId: 1, // Default user
      name: _nameController.text.trim(),
      categories: _selectedCategories,
      ingredients: ingredients,
      recipeSteps: recipeSteps,
      createdAt: widget.meal?.createdAt,
      updatedAt: DateTime.now(),
    );

    final repository = ref.read(mealsRepositoryProvider);

    try {
      if (widget.meal == null) {
        await repository.insertMeal(meal);
      } else {
        await repository.updateMeal(meal);
      }
      
      // Refresh list
      ref.refresh(mealsProvider(null)); // Refresh 'all'
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.meal == null ? 'تمت إضافة الوجبة' : 'تم تعديل الوجبة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal == null ? 'إضافة وجبة' : 'تعديل وجبة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الوجبة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم الوجبة';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Categories
            const Text(
              'التصنيف',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(_categoryTranslations[category] ?? category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Ingredients
            _buildDynamicList(
              title: 'المكونات',
              controllers: _ingredientControllers,
              onAdd: _addIngredient,
              onRemove: _removeIngredient,
              hintText: 'أضف مكون...',
              icon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(height: 24),

            // Recipe Steps
            _buildDynamicList(
              title: 'طريقة التحضير',
              controllers: _stepControllers,
              onAdd: _addStep,
              onRemove: _removeStep,
              hintText: 'أضف خطوة...',
              icon: Icons.format_list_numbered,
              isMultiLine: true,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveMeal,
              icon: const Icon(Icons.save),
              label: const Text('حفظ الوجبة'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicList({
    required String title,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required String hintText,
    required IconData icon,
    bool isMultiLine = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              tooltip: 'إضافة',
            ),
          ],
        ),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      hintText: hintText,
                      prefixIcon: Icon(icon, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: isMultiLine ? 3 : 1,
                    minLines: 1,
                    textInputAction: isMultiLine ? TextInputAction.newline : TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
