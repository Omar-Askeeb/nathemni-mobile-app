import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/common_providers.dart';
import '../data/tool_category_model.dart';
import '../data/tool_model.dart';
import '../providers/tools_providers.dart';

class AddEditToolDialog extends ConsumerStatefulWidget {
  final ToolModel? tool;

  const AddEditToolDialog({super.key, this.tool});

  @override
  ConsumerState<AddEditToolDialog> createState() => _AddEditToolDialogState();
}

class _AddEditToolDialogState extends ConsumerState<AddEditToolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedCategoryId;
  bool _isLoading = false;

  bool get isEdit => widget.tool != null;

  @override
  void initState() {
    super.initState();
    if (widget.tool != null) {
      _nameController.text = widget.tool!.name;
      _descriptionController.text = widget.tool!.description ?? '';
      _costController.text = widget.tool!.cost > 0
          ? widget.tool!.cost.toStringAsFixed(0)
          : '';
      _notesController.text = widget.tool!.notes ?? '';
      _selectedCategoryId = widget.tool!.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(toolCategoriesProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'تعديل المعدة' : 'إضافة معدة',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المعدة *',
                      prefixIcon: Icon(Icons.construction),
                      hintText: 'مثال: هلتي بوش',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المعدة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('خطأ: $e'),
                    data: (categories) {
                      // Set default category if not selected
                      if (_selectedCategoryId == null && categories.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedCategoryId = categories.first.id;
                          });
                        });
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'الفئة *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Row(
                              children: [
                                if (cat.icon != null)
                                  Text(cat.icon!,
                                      style: const TextStyle(fontSize: 18)),
                                if (cat.icon != null) const SizedBox(width: 8),
                                Text(cat.nameAr),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'الرجاء اختيار الفئة';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purchase Cost
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'سعر الشراء / التكلفة (د.ل)',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'كم دفعت لشراء هذه المعدة؟',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
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
                        onPressed: _isLoading ? null : _saveTool,
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
      ),
    );
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    setState(() => _isLoading = true);

    final userId = ref.read(currentUserIdProvider);
    final cost = _costController.text.isNotEmpty
        ? double.tryParse(_costController.text) ?? 0
        : 0.0;

    final tool = ToolModel(
      id: widget.tool?.id,
      userId: userId,
      categoryId: _selectedCategoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      cost: cost,
      status: widget.tool?.status ?? 'available',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      if (isEdit) {
        await ref.read(toolsNotifierProvider.notifier).updateTool(tool);
      } else {
        await ref.read(toolsNotifierProvider.notifier).addTool(tool);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'تم تحديث المعدة بنجاح' : 'تمت إضافة المعدة بنجاح'),
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
