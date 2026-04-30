class HorizontalClub {
  final String id;
  final String name;
  final String? description;
  final String targetVertical;
  final String? coordinatorUserId;
  final bool isActive;
  final int minMembers;
  final bool isMember;

  HorizontalClub({
    required this.id,
    required this.name,
    this.description,
    required this.targetVertical,
    this.coordinatorUserId,
    this.isActive = true,
    this.minMembers = 10,
    this.isMember = false,
  });

  factory HorizontalClub.fromJson(Map<String, dynamic> json) => HorizontalClub(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        targetVertical: json['target_vertical'] ?? '',
        coordinatorUserId: json['coordinator_user_id'],
        isActive: json['is_active'] ?? true,
        minMembers: json['min_members'] ?? 10,
        isMember: json['is_member'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'target_vertical': targetVertical,
        'coordinator_user_id': coordinatorUserId,
        'is_active': isActive,
        'min_members': minMembers,
        'is_member': isMember,
      };
}
