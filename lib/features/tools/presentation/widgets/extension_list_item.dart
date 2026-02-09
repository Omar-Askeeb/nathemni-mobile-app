import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tool_extension_model.dart';

class ExtensionListItem extends StatelessWidget {
  final ToolExtensionModel extension;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExtensionListItem({
    super.key,
    required this.extension,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = extension.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: selectable
            ? Checkbox(
                value: selected,
                onChanged: isAvailable
                    ? (value) => onSelected?.call(value ?? false)
                    : null,
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.textDisabled.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: isAvailable ? AppTheme.success : AppTheme.textDisabled,
                  size: 20,
                ),
              ),
        title: Text(
          extension.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isAvailable ? null : AppTheme.textDisabled,
              ),
        ),
        subtitle: Row(
          children: [
            Text(
              extension.statusArabic,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isAvailable ? AppTheme.success : AppTheme.textDisabled,
                  ),
            ),
            if (extension.cost > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${extension.cost.toStringAsFixed(0)} د.ل',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
        trailing: !selectable && (onEdit != null || onDelete != null)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
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
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppTheme.error),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        onTap: selectable && isAvailable
            ? () => onSelected?.call(!selected)
            : null,
      ),
    );
  }
}
