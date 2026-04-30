class Member {
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePhoto;
  final String industryName;
  final String? chapterName;
  final String? businessName;
  final String? companyName;
   final bool isSameChapter;
   final String verificationLevel;
 
   Member({
     required this.userId,
     required this.fullName,
     this.email,
     this.phoneNumber,
     this.profilePhoto,
     required this.industryName,
     this.chapterName,
     this.businessName,
     this.companyName,
     this.isSameChapter = false,
     this.verificationLevel = 'none',
   });
 
   factory Member.fromJson(Map<String, dynamic> json) => Member(
         userId: json['user_id'] ?? '',
         fullName: json['full_name'] ?? '',
         email: json['email'],
         phoneNumber: json['phone_number'],
         profilePhoto: json['profile_photo'],
         industryName: json['industry_category']?['name'] ?? 'Unknown',
         chapterName: json['chapter_name'],
         businessName: json['business']?['name'],
         companyName: json['business']?['name'],
         isSameChapter: json['is_same_chapter'] ?? false,
         verificationLevel: json['verification_level'] ?? 'none',
       );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'profile_photo': profilePhoto,
        'industry_category': {'name': industryName},
        'chapter_name': chapterName,
        'business': {'name': businessName},
        'is_same_chapter': isSameChapter,
      };

  String get displayName => fullName;
  String get industry => industryName;
  String get company => businessName ?? companyName ?? '-';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
