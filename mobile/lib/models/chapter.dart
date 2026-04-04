class Chapter {
  final String id;
  final String name;
  final String? description;
  final String? meetingSchedule;
  final bool isActive;

  Chapter({
    required this.id,
    required this.name,
    this.description,
    this.meetingSchedule,
    this.isActive = true,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        meetingSchedule: json['meeting_schedule'],
        isActive: json['is_active'] ?? true,
      );
}

class Membership {
  final String id;
  final Chapter chapter;
  final IndustryCategory industryCategory;
  final String membershipType;
  final String startDate;
  final String? endDate;
  final bool isActive;

  Membership({
    required this.id,
    required this.chapter,
    required this.industryCategory,
    required this.membershipType,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        id: json['id'] ?? '',
        chapter: Chapter.fromJson(json['chapter'] ?? {}),
        industryCategory: IndustryCategory.fromJson(json['industry_category'] ?? {}),
        membershipType: json['membership_type'] ?? 'standard',
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'],
        isActive: json['is_active'] ?? true,
      );
}

class IndustryCategory {
  final String id;
  final String name;
  final String? slug;
  final String? description;

  IndustryCategory({required this.id, required this.name, this.slug, this.description});

  factory IndustryCategory.fromJson(Map<String, dynamic> json) => IndustryCategory(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'],
        description: json['description'],
      );
}
