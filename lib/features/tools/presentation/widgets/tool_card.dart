import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tool_model.dart';

class ToolCard extends StatelessWidget {
  final ToolModel tool;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ToolCard({
    super.key,
    required this.tool,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tool Icon/Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          tool.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.construction,
                            color: _getStatusColor(),
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.construction,
                        color: _getStatusColor(),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              // Tool Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(context),
                        if (tool.dailyPrice > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${tool.dailyPrice.toStringAsFixed(0)} د.ل/يوم',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tool.statusArabic,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (tool.status) {
      case 'available':
        return AppTheme.success;
      case 'rented':
        return AppTheme.primaryDark;
      case 'lent':
        return AppTheme.accent;
      case 'maintenance':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }
}
