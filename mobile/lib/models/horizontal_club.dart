class HorizontalClub {
  final String id;
  final String name;
  final String? description;
  final List<String> industries;
  final bool isActive;
  final int minMembers;
  final bool isMember;
  final bool isEligible;

  HorizontalClub({
    required this.id,
    required this.name,
    this.description,
    required this.industries,
    this.isActive = true,
    this.minMembers = 10,
    this.isMember = false,
    this.isEligible = true,
  });

  factory HorizontalClub.fromJson(Map<String, dynamic> json) => HorizontalClub(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        industries: List<String>.from(json['industries'] ?? []),
        isActive: json['is_active'] ?? true,
        minMembers: json['min_members'] ?? 10,
        isMember: json['is_member'] ?? false,
        isEligible: json['is_eligible'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'industries': industries,
        'is_active': isActive,
        'min_members': minMembers,
        'is_member': isMember,
      };
}
