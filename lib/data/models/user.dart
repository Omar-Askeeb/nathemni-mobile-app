import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? username;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final bool isActive;
  final String? language;
  final String? createdAt;
  final String? updatedAt;

  const User({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.username,
    this.email,
    this.phone,
    this.profileImage,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.isActive = true,
    this.language,
    this.createdAt,
    this.updatedAt,
  });

  /// Display name: returns nameAr if in Arabic context, nameEn otherwise, or fallback to name
  String get displayName => nameAr ?? nameEn ?? name;

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle is_active as either bool or int (SQLite stores as int)
    bool isActive = true;
    final isActiveValue = json['is_active'];
    if (isActiveValue is bool) {
      isActive = isActiveValue;
    } else if (isActiveValue is int) {
      isActive = isActiveValue == 1;
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['name_ar'] as String? ?? 'User',
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImage: (json['profile_image'] as String?) ?? (json['avatar'] as String?),
      emailVerifiedAt: json['email_verified_at'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      isActive: isActive,
      language: (json['language'] as String?) ?? (json['preferred_mode'] == 'en' ? 'en' : 'ar'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profile_image': profileImage,
      if (emailVerifiedAt != null) 'email_verified_at': emailVerifiedAt,
      if (phoneVerifiedAt != null) 'phone_verified_at': phoneVerifiedAt,
      'is_active': isActive ? 1 : 0,  // Store as int for SQLite compatibility
      if (language != null) 'language': language,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  User merge(User other) {
    return User(
      id: id,
      name: (other.name.isNotEmpty && other.name != 'User') ? other.name : name,
      nameAr: other.nameAr ?? nameAr,
      nameEn: other.nameEn ?? nameEn,
      username: other.username ?? username,
      email: other.email ?? email,
      phone: other.phone ?? phone,
      profileImage: other.profileImage ?? profileImage,
      emailVerifiedAt: other.emailVerifiedAt ?? emailVerifiedAt,
      phoneVerifiedAt: other.phoneVerifiedAt ?? phoneVerifiedAt,
      isActive: other.isActive,
      language: other.language ?? language,
      createdAt: other.createdAt ?? createdAt,
      updatedAt: other.updatedAt ?? updatedAt,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? nameAr,
    String? nameEn,
    String? username,
    String? email,
    String? phone,
    String? profileImage,
    String? emailVerifiedAt,
    String? phoneVerifiedAt,
    bool? isActive,
    String? language,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      isActive: isActive ?? this.isActive,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        nameEn,
        username,
        email,
        phone,
        profileImage,
        emailVerifiedAt,
        phoneVerifiedAt,
        isActive,
        language,
        createdAt,
        updatedAt,
      ];
}
