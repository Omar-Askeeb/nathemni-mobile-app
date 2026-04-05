import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meal_model.dart';
import '../providers/meals_providers.dart';
import 'meal_details_screen.dart';

class SuggestMealDialog extends ConsumerStatefulWidget {
  const SuggestMealDialog({super.key});

  @override
  ConsumerState<SuggestMealDialog> createState() => _SuggestMealDialogState();
}

class _SuggestMealDialogState extends ConsumerState<SuggestMealDialog> {
  String _selectedCategory = 'Lunch';
  Meal? _suggestedMeal;
  bool _isLoading = false;

  final List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Appetizers/Sides'
  ];

  final Map<String, String> _categoryTranslations = {
    'Breakfast': 'فطور',
    'Lunch': 'غذاء',
    'Dinner': 'عشاء',
    'Appetizers/Sides': 'مقبلات',
  };

  void _suggestMeal() async {
    setState(() {
      _isLoading = true;
      _suggestedMeal = null;
    });

    // Determine category based on current time if first load? 
    // No, user selects category.

    // Fetch all meals (we could filter by category in query, but provider caches 'all')
    // Or fetch by category using provider family if we want.
    // Let's use the repository directly or a provider call.
    // Provider specific to category is cached.
    
    // We'll use the provider with category filter
    // But since the provider is AsyncValue, we need to read it.
    // If it's not loaded, we wait.
    
    try {
      final meals = await ref.read(mealsProvider(_selectedCategory).future);
      
      if (meals.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد وجبات في هذا التصنيف')),
          );
        }
      } else {
        final random = Random();
        setState(() {
          _suggestedMeal = meals[random.nextInt(meals.length)];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ماذا آكل اليوم؟'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Selector
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'اختر الوجبة',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(_categoryTranslations[cat] ?? cat),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  _suggestedMeal = null; // Reset suggestion on category change
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Suggestion Area
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_suggestedMeal != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'نقترح عليك:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _suggestedMeal!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealDetailsScreen(meal: _suggestedMeal!),
                          ),
                        );
                      },
                      child: const Text('عرض التفاصيل'),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'اضغط على الزر للحصول على اقتراح',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _suggestMeal,
          icon: const Icon(Icons.refresh),
          label: const Text('اقتراح'),
        ),
      ],
    );
  }
}
