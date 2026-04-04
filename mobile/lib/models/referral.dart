class Referral {
  final String id;
  final ReferralUser fromUser;
  final ReferralUser targetUser;
  final String leadName;
  final String leadContact;
  final String? leadEmail;
  final String? notes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<ReferralHistory> history;

  Referral({
    required this.id,
    required this.fromUser,
    required this.targetUser,
    required this.leadName,
    required this.leadContact,
    this.leadEmail,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
  });

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
        id: json['id'] ?? '',
        fromUser: ReferralUser.fromJson(json['from_user'] ?? {}),
        targetUser: ReferralUser.fromJson(json['target_user'] ?? {}),
        leadName: json['lead_name'] ?? '',
        leadContact: json['lead_contact'] ?? '',
        leadEmail: json['lead_email'],
        notes: json['notes'],
        status: json['status'] ?? 'submitted',
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        history: (json['history'] as List<dynamic>?)
                ?.map((h) => ReferralHistory.fromJson(h))
                .toList() ??
            [],
      );

  String get statusLabel {
    switch (status) {
      case 'submitted': return 'Submitted';
      case 'contacted': return 'Contacted';
      case 'in_progress': return 'In Progress';
      case 'closed_won': return 'Won';
      case 'closed_lost': return 'Lost';
      default: return status;
    }
  }
}

class ReferralUser {
  final String id;
  final String fullName;
  final String phoneNumber;

  ReferralUser({required this.id, required this.fullName, required this.phoneNumber});

  factory ReferralUser.fromJson(Map<String, dynamic> json) => ReferralUser(
        id: json['id'] ?? '',
        fullName: json['full_name'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
      );
}

class ReferralHistory {
  final String id;
  final String oldStatus;
  final String newStatus;
  final String? notes;
  final String createdAt;

  ReferralHistory({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    this.notes,
    required this.createdAt,
  });

  factory ReferralHistory.fromJson(Map<String, dynamic> json) => ReferralHistory(
        id: json['id'] ?? '',
        oldStatus: json['old_status'] ?? '',
        newStatus: json['new_status'] ?? '',
        notes: json['notes'],
        createdAt: json['created_at'] ?? '',
      );
}
