class Application {
  final String id;
  final String fullName;
  final String businessName;
  final String contactNumber;
  final String email;
  final String district;
  final String industryCategoryId;
  final String status;
  final String? fitCallDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<AppHistory> history;

  Application({
    required this.id,
    required this.fullName,
    required this.businessName,
    required this.contactNumber,
    required this.email,
    required this.district,
    required this.industryCategoryId,
    required this.status,
    this.fitCallDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] ?? '',
        fullName: json['full_name'] ?? '',
        businessName: json['business_name'] ?? '',
        contactNumber: json['contact_number'] ?? '',
        email: json['email'] ?? '',
        district: json['district'] ?? '',
        industryCategoryId: json['industry_category_id'] ?? '',
        status: json['status'] ?? 'submitted',
        fitCallDate: json['fit_call_date'],
        notes: json['notes'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        history: (json['history'] as List<dynamic>?)
                ?.map((h) => AppHistory.fromJson(h))
                .toList() ??
            [],
      );

  String get statusLabel {
    switch (status) {
      case 'submitted': return 'Submitted';
      case 'fit_call_scheduled': return 'Fit Call Scheduled';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'waitlisted': return 'Waitlisted';
      default: return status;
    }
  }
}

class AppHistory {
  final String id;
  final String? oldStatus;
  final String newStatus;
  final String? notes;
  final String createdAt;

  AppHistory({required this.id, this.oldStatus, required this.newStatus, this.notes, required this.createdAt});

  factory AppHistory.fromJson(Map<String, dynamic> json) => AppHistory(
        id: json['id'] ?? '',
        oldStatus: json['old_status'],
        newStatus: json['new_status'] ?? '',
        notes: json['notes'],
        createdAt: json['created_at'] ?? '',
      );
}
