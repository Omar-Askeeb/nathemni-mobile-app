import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../data/meal_model.dart';
import '../data/meals_repository.dart';
import '../providers/meals_providers.dart';
import 'log_meal_dialog.dart';
import 'add_edit_meal_screen.dart';

class MealDetailsScreen extends ConsumerWidget {
  final Meal meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEatenAsync = ref.watch(lastEatenProvider(meal.id!));

    final Map<String, String> categoryTranslations = {
      'Breakfast': 'فطور',
      'Lunch': 'غذاء',
      'Dinner': 'عشاء',
      'Appetizers/Sides': 'مقبلات وجوانب',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditMealScreen(meal: meal),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header / Image placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
              image: meal.imagePath != null
                  ? DecorationImage(
                      image: NetworkImage(meal.imagePath!), // Or FileImage if local
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: meal.imagePath == null
                ? const Center(
                    child: Icon(Icons.restaurant, size: 64, color: Colors.orange),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Title & Last Eaten
          Text(
            meal.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          lastEatenAsync.when(
            data: (date) => Text(
              date != null
                  ? 'آخر مرة: ${ArabicNumbers.convert(date.toString().split(' ')[0])}'
                  : 'لم يتم تناولها من قبل',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.categories.map((cat) {
              return Chip(
                label: Text(categoryTranslations[cat] ?? cat),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Log Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => LogMealDialog(meal: meal),
              );
            },
            icon: const Icon(Icons.history_edu),
            label: const Text('تسجيل تناول الوجبة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Ingredients
          if (meal.ingredients.isNotEmpty) ...[
            Text(
              'المكونات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: meal.ingredients
                      .map((ing) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ing)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recipe Steps
          if (meal.recipeSteps.isNotEmpty) ...[
            Text(
              'طريقة التحضير',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: meal.recipeSteps.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              ArabicNumbers.convert(index.toString()),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
