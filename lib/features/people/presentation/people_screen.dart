import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/person_model.dart';
import '../providers/people_providers.dart';
import '../../../core/navigation/app_drawer.dart';
import '../../../core/providers/common_providers.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأشخاص'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: peopleAsync.when(
        data: (people) {
          if (people.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPeopleList(context, ref, people);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref, null),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد أشخاص',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة شخص',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleList(BuildContext context, WidgetRef ref, List<PersonModel> people) {
    // Group by type
    final Map<String, List<PersonModel>> groupedPeople = {};
    for (var person in people) {
      if (!groupedPeople.containsKey(person.type)) {
        groupedPeople[person.type] = [];
      }
      groupedPeople[person.type]!.add(person);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedPeople.length,
      itemBuilder: (context, index) {
        final type = groupedPeople.keys.elementAt(index);
        final typePeople = groupedPeople[type]!;
        final typeInfo = PersonModel.allTypes.firstWhere(
          (t) => t['id'] == type,
          orElse: () => {'id': 'other', 'name': 'آخر', 'icon': '👥'},
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(typeInfo['icon']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${typeInfo['name']} (${typePeople.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...typePeople.map((person) => _buildPersonCard(context, ref, person)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildPersonCard(BuildContext context, WidgetRef ref, PersonModel person) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.phone != null && person.phone!.isNotEmpty)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('📞 ${person.phone}'),
              ),
            if (person.notes != null && person.notes!.isNotEmpty)
              Text(
                person.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (person.phone != null && person.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _callPerson(person.phone!),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context, ref, person),
            ),
          ],
        ),
        onTap: () => _showAddEditDialog(context, ref, person),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, PersonModel person) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                _showAddEditDialog(context, ref, person);
              },
            ),
            if (person.phone != null && person.phone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('اتصال'),
                onTap: () {
                  Navigator.pop(context);
                  _callPerson(person.phone!);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, person);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, PersonModel? person) {
    final isEdit = person != null;
    final nameController = TextEditingController(text: person?.name ?? '');
    final phoneController = TextEditingController(text: person?.phone ?? '');
    final notesController = TextEditingController(text: person?.notes ?? '');
    String selectedType = person?.type ?? 'friend';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل الشخص' : 'إضافة شخص'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.name,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل الاسم' : null,
                  ),
                  const SizedBox(height: 16),
                  // Type
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'النوع',
                      border: OutlineInputBorder(),
                    ),
                    items: PersonModel.allTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['id'],
                        child: Row(
                          children: [
                            Text(type['icon']!, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(type['name']!),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
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
                  final userId = ref.read(currentUserIdProvider);
                  final newPerson = PersonModel(
                    id: person?.id,
                    userId: userId,
                    name: nameController.text.trim(),
                    type: selectedType,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );

                  if (isEdit) {
                    await ref.read(peopleNotifierProvider.notifier).updatePerson(newPerson);
                  } else {
                    await ref.read(peopleNotifierProvider.notifier).addPerson(newPerson);
                  }
                }
              },
              child: Text(isEdit ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PersonModel person) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الشخص'),
        content: Text('هل أنت متأكد من حذف "${person.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(peopleNotifierProvider.notifier).deletePerson(person.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _callPerson(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
