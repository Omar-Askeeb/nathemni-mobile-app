import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../auth/presentation/widgets/auth_button.dart';

/// Edit profile screen with image picker
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final user = ref.read(profileProvider).user;
    if (user != null) {
      _nameArController.text = user.nameAr ?? '';
      _nameEnController.text = user.nameEn ?? '';
      _usernameController.text = user.username ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الصورة: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || ref.read(profileProvider).user?.profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'إزالة الصورة',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(profileProvider.notifier);
    bool success = true;

    // Update image if selected
    if (_selectedImage != null) {
      success = await notifier.updateProfileImage(_selectedImage!);
    }

    // Update profile data
    if (success) {
      success = await notifier.updateProfile(
        nameAr: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التغييرات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildProfileImagePicker() {
    final user = ref.watch(profileProvider).user;
    final theme = Theme.of(context);

    Widget imageWidget;
    if (_selectedImage != null) {
      imageWidget = Image.file(
        File(_selectedImage!.path),
        fit: BoxFit.cover,
      );
    } else if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
      if (user.profileImage!.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: user.profileImage!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            size: 50,
            color: Colors.white70,
          ),
        );
      } else {
        imageWidget = Image.file(
          File(user.profileImage!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person,
            size: 50,
            color: Colors.white70,
          ),
        );
      }
    } else {
      imageWidget = Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.onPrimary.withOpacity(0.7),
      );
    }

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.2),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 3,
              ),
            ),
            child: ClipOval(child: imageWidget),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (value.trim().length < 9) {
      return 'رقم الهاتف غير صالح';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.trim().length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isUpdating = profileState.isUpdating;
    final theme = Theme.of(context);

    // Listen for errors
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(profileProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Picker
              _buildProfileImagePicker(),
              const SizedBox(height: 8),
              Text(
                'اضغط لتغيير الصورة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Arabic Name
              AuthTextField(
                label: 'الاسم بالعربية',
                hint: 'أدخل اسمك بالعربية',
                controller: _nameArController,
                enabled: !isUpdating,
                validator: (v) => _validateRequired(v, 'الاسم بالعربية'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // English Name
              AuthTextField(
                label: 'الاسم بالإنجليزية',
                hint: 'Enter your name in English',
                controller: _nameEnController,
                enabled: !isUpdating,
                validator: (v) => _validateRequired(v, 'الاسم بالإنجليزية'),
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),

              // Username
              AuthTextField(
                label: 'اسم المستخدم (النك نيم)',
                hint: 'username',
                controller: _usernameController,
                enabled: !isUpdating,
                validator: _validateUsername,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              const SizedBox(height: 16),

              // Phone
              PhoneInputField(
                controller: _phoneController,
                enabled: !isUpdating,
                validator: _validatePhone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Email
              AuthTextField(
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isUpdating,
                validator: _validateEmail,
                textInputAction: TextInputAction.done,
                textDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 32),

              // Save Button
              AuthButton(
                text: 'حفظ التغييرات',
                onPressed: _handleSave,
                isLoading: isUpdating,
                icon: Icons.save,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              AuthOutlineButton(
                text: 'إلغاء',
                onPressed: isUpdating ? null : () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
