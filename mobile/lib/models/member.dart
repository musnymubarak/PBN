class Member {
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String industryName;
  final String? businessName;
  final String? companyName;

  Member({
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.industryName,
    this.businessName,
    this.companyName,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        userId: json['user_id'] ?? '',
        fullName: json['full_name'] ?? '',
        email: json['email'],
        phoneNumber: json['phone_number'],
        industryName: json['industry_category']?['name'] ?? 'Unknown',
        businessName: json['business']?['name'],
        companyName: json['business']?['name'],
      );

  String get displayName => fullName;
  String get industry => industryName;
  String get company => companyName ?? businessName ?? 'Independent';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
