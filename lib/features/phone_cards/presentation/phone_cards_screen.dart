import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sim_card_model.dart';
import '../providers/sim_cards_providers.dart';
import 'sim_cards_list_screen.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/utils/arabic_numbers.dart';

/// Main screen for phone cards management - shows provider selection
class PhoneCardsScreen extends ConsumerWidget {
  const PhoneCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(simCardsStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بطاقات الهاتف'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: statisticsAsync.when(
        data: (statistics) => _buildProviderCards(context, statistics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildProviderCards(
      BuildContext context, Map<String, int> statistics) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'اختر المزود',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'يمكنك حفظ حتى 10 بطاقات لكل مزود',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 24),

        // Provider cards
        _buildProviderCard(
          context,
          ProviderInfo.libyana,
          statistics['libyana'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProviderCard(
          context,
          ProviderInfo.almadar,
          statistics['almadar'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProviderCard(
          context,
          ProviderInfo.ltt,
          statistics['ltt'] ?? 0,
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    ProviderInfo provider,
    int count,
  ) {
    // Parse color from hex
    final color = Color(
      int.parse(provider.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimCardsListScreen(provider: provider),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Icon/Logo area
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sim_card,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),

              // Provider info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.nameArabic,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.nameEnglish,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sim_card_outlined,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ArabicNumbers.convert(count.toString())} / ${ArabicNumbers.convert('10')}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
