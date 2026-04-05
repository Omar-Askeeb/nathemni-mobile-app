import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/car_document_model.dart';
import '../data/car_repository.dart';
import '../providers/car_providers.dart';

class DocumentHistoryScreen extends ConsumerWidget {
  final int carId;
  final CarDocumentType documentType;

  const DocumentHistoryScreen({
    super.key,
    required this.carId,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سجل ${documentType.nameAr}'),
      ),
      body: FutureBuilder<List<CarDocument>>(
        future: ref.read(carRepositoryProvider).getDocumentsByType(carId, documentType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppTheme.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد سجلات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = documents[index];
              return _buildDocumentCard(context, doc);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, CarDocument doc) {
    final isExpiringSoon = doc.isExpiringSoon;
    final isExpired = doc.isExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ التجديد',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd').format(doc.renewalDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الانتهاء',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd').format(doc.expiryDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? AppTheme.error
                                  : isExpiringSoon
                                      ? AppTheme.warning
                                      : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القيمة',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${doc.currency} ${doc.cost.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (doc.placeName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المكان',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          doc.placeName!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (doc.notes != null && doc.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ملاحظات',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                doc.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (isExpiringSoon || isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isExpired ? AppTheme.error : AppTheme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error : Icons.warning_amber,
                      size: 16,
                      color: isExpired ? AppTheme.error : AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired ? 'منتهي الصلاحية' : 'ينتهي قريباً',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isExpired ? AppTheme.error : AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
