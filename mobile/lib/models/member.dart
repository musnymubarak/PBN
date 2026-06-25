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

  // New Portfolio fields
  final String? businessLogoUrl;
  final String? businessDescription;
  final String? businessAddress;
  final String? businessEstablishedYear;
  final String? businessBrNumber;
  final String? businessBrochureUrl;
  final String? businessGoogleMapsUrl;
  final String? businessLinkedinUrl;
  final String? businessFacebookUrl;
  final String? businessInstagramUrl;
  final String? businessWebsite;

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
    this.businessLogoUrl,
    this.businessDescription,
    this.businessAddress,
    this.businessEstablishedYear,
    this.businessBrNumber,
    this.businessBrochureUrl,
    this.businessGoogleMapsUrl,
    this.businessLinkedinUrl,
    this.businessFacebookUrl,
    this.businessInstagramUrl,
    this.businessWebsite,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    final biz = json['business'];
    return Member(
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      profilePhoto: json['profile_photo'],
      industryName: json['industry_category']?['name'] ?? 'Unknown',
      chapterName: json['chapter_name'],
      businessName: biz?['name'] ?? biz?['business_name'],
      companyName: biz?['name'] ?? biz?['business_name'],
      isSameChapter: json['is_same_chapter'] ?? false,
      verificationLevel: json['verification_level'] ?? 'none',
      businessLogoUrl: biz?['logo_url'],
      businessDescription: biz?['description'],
      businessAddress: biz?['address'],
      businessEstablishedYear: biz?['established_year'],
      businessBrNumber: biz?['br_number'],
      businessBrochureUrl: biz?['brochure_url'],
      businessGoogleMapsUrl: biz?['google_maps_url'],
      businessLinkedinUrl: biz?['linkedin_url'],
      businessFacebookUrl: biz?['facebook_url'],
      businessInstagramUrl: biz?['instagram_url'],
      businessWebsite: biz?['website'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'profile_photo': profilePhoto,
        'industry_category': {'name': industryName},
        'chapter_name': chapterName,
        'is_same_chapter': isSameChapter,
        'verification_level': verificationLevel,
        'business': {
          'name': businessName,
          'business_name': businessName,
          'logo_url': businessLogoUrl,
          'description': businessDescription,
          'address': businessAddress,
          'established_year': businessEstablishedYear,
          'br_number': businessBrNumber,
          'brochure_url': businessBrochureUrl,
          'google_maps_url': businessGoogleMapsUrl,
          'linkedin_url': businessLinkedinUrl,
          'facebook_url': businessFacebookUrl,
          'instagram_url': businessInstagramUrl,
          'website': businessWebsite,
        },
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
