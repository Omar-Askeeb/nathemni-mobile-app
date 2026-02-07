import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sim_card_model.dart';
import '../providers/sim_cards_providers.dart';
import '../../../core/utils/arabic_numbers.dart';

/// Screen showing SIM cards list for a specific provider
class SimCardsListScreen extends ConsumerStatefulWidget {
  final ProviderInfo provider;

  const SimCardsListScreen({super.key, required this.provider});

  @override
  ConsumerState<SimCardsListScreen> createState() =>
      _SimCardsListScreenState();
}

class _SimCardsListScreenState extends ConsumerState<SimCardsListScreen> {
  @override
  Widget build(BuildContext context) {
    final simCardsAsync = ref.watch(filteredSimCardsProvider(widget.provider.id));
    final searchQuery = ref.watch(searchQueryProvider);

    // Parse color from hex
    final color = Color(
      int.parse(widget.provider.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider.nameArabic),
        centerTitle: true,
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: color.withOpacity(0.1),
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'بحث برقم البطاقة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),

          // SIM cards list
          Expanded(
            child: simCardsAsync.when(
              data: (simCards) {
                if (simCards.isEmpty) {
                  return _buildEmptyState(context, color);
                }
                return _buildSimCardsList(context, simCards, color);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('خطأ: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, color, null),
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color color) {
    final searchQuery = ref.watch(searchQueryProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.sim_card_outlined : Icons.search_off,
            size: 80,
            color: color.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'لا توجد بطاقات مسجلة'
                : 'لا توجد نتائج للبحث',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'اضغط على + لإضافة بطاقة جديدة'
                : 'جرب البحث برقم آخر',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimCardsList(
      BuildContext context, List<SimCardModel> simCards, Color color) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: simCards.length,
      itemBuilder: (context, index) {
        final simCard = simCards[index];
        return _buildSimCardItem(context, simCard, color);
      },
    );
  }

  Widget _buildSimCardItem(
      BuildContext context, SimCardModel simCard, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.sim_card,
            color: color,
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ArabicNumbers.convert(simCard.formattedNumber),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (simCard.notes != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      simCard.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        subtitle: null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Copy button
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyToClipboard(context, simCard.simNumber),
              tooltip: 'نسخ',
            ),
            // More options
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditDialog(context, color, simCard);
                } else if (value == 'delete') {
                  _confirmDelete(context, simCard);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرقم'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddEditDialog(
      BuildContext context, Color color, SimCardModel? simCard) {
    final isEdit = simCard != null;
    final simNumberController =
        TextEditingController(text: simCard?.simNumber ?? '');
    final notesController = TextEditingController(text: simCard?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'تعديل البطاقة' : 'إضافة بطاقة جديدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SIM Number field
              TextFormField(
                controller: simNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة',
                  hintText: '0912345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم البطاقة';
                  }
                  if (value.length != 10) {
                    return 'الرقم يجب أن يكون 10 أرقام';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes field
              Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (مستلم البطاقة)',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 2,
                  maxLength: 100,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                await _saveSimCard(
                  simCard,
                  simNumberController.text,
                  notesController.text.isEmpty ? null : notesController.text,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: color),
            child: Text(isEdit ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSimCard(
      SimCardModel? existingCard, String simNumber, String? notes) async {
    try {
      final repository = ref.read(simCardsRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      if (existingCard != null) {
        // Update existing
        await repository.updateSimCard(
          existingCard.copyWith(
            simNumber: simNumber,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث البطاقة بنجاح')),
          );
        }
      } else {
        // Add new
        final newCard = SimCardModel(
          userId: userId,
          simNumber: simNumber,
          provider: widget.provider.id,
          notes: notes,
        );
        
        await repository.addSimCard(newCard);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة البطاقة بنجاح')),
          );
        }
      }
      
      // Refresh the list
      ref.invalidate(filteredSimCardsProvider(widget.provider.id));
      ref.invalidate(simCardsStatisticsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, SimCardModel simCard) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف البطاقة'),
        content: Text(
          'هل أنت متأكد من حذف البطاقة ${ArabicNumbers.convert(simCard.formattedNumber)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteSimCard(simCard.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSimCard(int id) async {
    try {
      final repository = ref.read(simCardsRepositoryProvider);
      await repository.deleteSimCard(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البطاقة بنجاح')),
        );
      }
      
      // Refresh the list
      ref.invalidate(filteredSimCardsProvider(widget.provider.id));
      ref.invalidate(simCardsStatisticsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
