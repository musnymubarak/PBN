class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final String role;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        email: json['email'],
        fullName: json['full_name'] ?? '',
        role: json['role'] ?? 'prospect',
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
