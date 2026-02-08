import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database_helper.dart';
import '../data/meal_model.dart';
import '../data/meals_repository.dart';

// Repository Provider
final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  return MealsRepository(DatabaseHelper.instance);
});

// Meals List Provider
final mealsProvider = FutureProvider.autoDispose.family<List<Meal>, String?>((ref, category) async {
  final repository = ref.watch(mealsRepositoryProvider);
  return repository.getMeals(category: category);
});

// Meal Logs Provider
final mealLogsProvider = FutureProvider.autoDispose<List<MealLog>>((ref) async {
  final repository = ref.watch(mealsRepositoryProvider);
  return repository.getMealLogs();
});

// Last Eaten Date Provider
final lastEatenProvider = FutureProvider.autoDispose.family<DateTime?, int>((ref, mealId) async {
  final repository = ref.watch(mealsRepositoryProvider);
  return repository.getLastEatenDate(mealId);
});
