import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tool_extension_model.dart';
import '../providers/tools_providers.dart';

class AddExtensionDialog extends ConsumerStatefulWidget {
  final int toolId;
  final ToolExtensionModel? extension;

  const AddExtensionDialog({
    super.key,
    required this.toolId,
    this.extension,
  });

  @override
  ConsumerState<AddExtensionDialog> createState() => _AddExtensionDialogState();
}

class _AddExtensionDialogState extends ConsumerState<AddExtensionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  bool get isEdit => widget.extension != null;

  @override
  void initState() {
    super.initState();
    if (widget.extension != null) {
      _nameController.text = widget.extension!.name;
      _costController.text = widget.extension!.cost > 0
          ? widget.extension!.cost.toStringAsFixed(0)
          : '';
      _notesController.text = widget.extension!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'تعديل الملحق' : 'إضافة ملحق',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الملحق *',
                    prefixIcon: Icon(Icons.extension),
                    hintText: 'مثال: ريشة حفر 10مم',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الملحق';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Purchase Price
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء (د.ل)',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'اختياري',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveExtension,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'حفظ' : 'إضافة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveExtension() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cost = _costController.text.isNotEmpty
        ? double.tryParse(_costController.text) ?? 0
        : 0.0;

    final extension = ToolExtensionModel(
      id: widget.extension?.id,
      toolId: widget.toolId,
      name: _nameController.text.trim(),
      cost: cost,
      status: widget.extension?.status ?? 'available',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      if (isEdit) {
        await ref.read(extensionsNotifierProvider.notifier).updateExtension(extension);
      } else {
        await ref.read(extensionsNotifierProvider.notifier).addExtension(extension);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'تم تحديث الملحق بنجاح' : 'تمت إضافة الملحق بنجاح'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
