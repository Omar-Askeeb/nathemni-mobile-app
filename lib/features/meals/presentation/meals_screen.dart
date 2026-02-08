import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/navigation/app_drawer.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../data/meal_model.dart';
import '../providers/meals_providers.dart';
import 'add_edit_meal_screen.dart';
import 'meal_details_screen.dart';
import 'suggest_meal_dialog.dart';

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Appetizers/Sides'
  ];

  final Map<String, String> _categoryTranslations = {
    'All': 'الكل',
    'Breakfast': 'فطور',
    'Lunch': 'غذاء',
    'Dinner': 'عشاء',
    'Appetizers/Sides': 'مقبلات',
    'Snack': 'وجبة خفيفة',
  };

  // History Filters
  String _historyTypeFilter = 'All';
  DateTimeRange? _historyDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوجبات'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'الوجبات'),
            Tab(text: 'السجل والتاريخ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino), // Dice icon for random
            tooltip: 'ماذا آكل؟',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SuggestMealDialog(),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealsListTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMealScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة وجبة',
      ),
    );
  }

  Widget _buildMealsListTab() {
    final mealsAsync = ref.watch(mealsProvider(null)); // Load all

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'بحث عن وجبة...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(_categoryTranslations[cat] ?? cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryFilter = cat;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: mealsAsync.when(
            data: (meals) {
              // Client-side filtering
              var filtered = meals;
              
              // Filter by category
              if (_selectedCategoryFilter != 'All') {
                filtered = filtered.where((m) => m.categories.contains(_selectedCategoryFilter)).toList();
              }

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                filtered = filtered.where((m) => m.name.toLowerCase().contains(_searchQuery)).toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_meals, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد وجبات مطابقة',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildMealCard(filtered[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailsScreen(meal: meal),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Placeholder
            Expanded(
              child: Container(
                color: Colors.orange.shade100,
                child: meal.imagePath != null
                    ? Image.network(
                        meal.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      )
                    : const Center(
                        child: Icon(Icons.restaurant, size: 40, color: Colors.orange),
                      ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.categories.map((c) => _categoryTranslations[c] ?? c).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final logsAsync = ref.watch(mealLogsProvider);

    return Column(
      children: [
        // History Filter Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Type Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _historyTypeFilter,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    labelText: 'النوع',
                  ),
                  items: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_categoryTranslations[type] ?? type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _historyTypeFilter = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date Filter
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _historyDateRange,
                    );
                    if (picked != null) {
                      setState(() => _historyDateRange = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _historyDateRange == null
                        ? 'التاريخ'
                        : '${DateFormat('MM/dd').format(_historyDateRange!.start)} - ${DateFormat('MM/dd').format(_historyDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_historyDateRange != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _historyDateRange = null),
                ),
            ],
          ),
        ),

        // List
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              // Apply Filters
              var filtered = logs;
              
              if (_historyTypeFilter != 'All') {
                filtered = filtered.where((l) => l.mealType == _historyTypeFilter).toList();
              }

              if (_historyDateRange != null) {
                filtered = filtered.where((l) {
                  final date = l.eatenAt;
                  return date.isAfter(_historyDateRange!.start.subtract(const Duration(days: 1))) &&
                         date.isBefore(_historyDateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }

              if (filtered.isEmpty) {
                return const Center(child: Text('لا توجد سجلات مطابقة'));
              }
              
              // Group by Date
              final grouped = <String, List<MealLog>>{};
              for (var log in filtered) {
                final dateKey = DateFormat('yyyy-MM-dd').format(log.eatenAt);
                if (grouped[dateKey] == null) grouped[dateKey] = [];
                grouped[dateKey]!.add(log);
              }

              // Sort keys descending
              final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final dateStr = sortedKeys[index];
                  final dayLogs = grouped[dateStr]!;
                  final formattedDate = DateFormat('EEEE, d MMMM', 'ar').format(DateTime.parse(dateStr));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...dayLogs.map((log) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(
                                _getIconForType(log.mealType),
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            title: Text(log.mealName ?? 'وجبة محذوفة'),
                            subtitle: Text(
                              '${_categoryTranslations[log.mealType] ?? log.mealType} • ${DateFormat('HH:mm').format(log.eatenAt)}',
                            ),
                            trailing: log.notes != null
                                ? const Icon(Icons.sticky_note_2_outlined, color: Colors.grey)
                                : null,
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Breakfast': return Icons.wb_sunny_outlined; // Morning
      case 'Lunch': return Icons.restaurant;
      case 'Dinner': return Icons.nights_stay_outlined;
      case 'Snack': return Icons.cookie_outlined;
      default: return Icons.fastfood;
    }
  }
}
