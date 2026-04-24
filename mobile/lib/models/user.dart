class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? profilePhoto;
  final String fullName;
  final String role;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final bool mustChangePassword;
  final String? chapterId;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.profilePhoto,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.mustChangePassword,
    this.chapterId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        email: json['email'],
        profilePhoto: json['profile_photo'],
        fullName: json['full_name'] ?? '',
        role: json['role'] ?? 'prospect',
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        mustChangePassword: json['must_change_password'] ?? false,
        chapterId: json['chapter_id'],
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? profilePhoto,
    String? fullName,
    String? role,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    bool? mustChangePassword,
    String? chapterId,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      chapterId: chapterId ?? this.chapterId,
    );
  }
}
