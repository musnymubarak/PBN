class DashboardData {
  final ReferralStats referrals;
  final RoiStats roi;
  final EventStats events;
  final MembershipStats membership;
  final int? leaderboardPosition;

  DashboardData({
    required this.referrals,
    required this.roi,
    required this.events,
    required this.membership,
    this.leaderboardPosition,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        referrals: ReferralStats.fromJson(json['referrals'] ?? {}),
        roi: RoiStats.fromJson(json['roi'] ?? {}),
        events: EventStats.fromJson(json['events'] ?? {}),
        membership: MembershipStats.fromJson(json['membership'] ?? {}),
        leaderboardPosition: json['leaderboard_position'],
      );
}

class ReferralStats {
  final int sentTotal;
  final int sentThisMonth;
  final int receivedTotal;
  final int receivedThisMonth;
  final int pendingFollowup;
  final double conversionRate;

  ReferralStats({
    this.sentTotal = 0, this.sentThisMonth = 0,
    this.receivedTotal = 0, this.receivedThisMonth = 0,
    this.pendingFollowup = 0, this.conversionRate = 0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        sentTotal: json['sent_total'] ?? 0,
        sentThisMonth: json['sent_this_month'] ?? 0,
        receivedTotal: json['received_total'] ?? 0,
        receivedThisMonth: json['received_this_month'] ?? 0,
        pendingFollowup: json['pending_followup'] ?? 0,
        conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      );
}

class RoiStats {
  final double totalValue;
  final double thisMonthValue;
  final double avgDealValue;

  RoiStats({this.totalValue = 0, this.thisMonthValue = 0, this.avgDealValue = 0});

  factory RoiStats.fromJson(Map<String, dynamic> json) => RoiStats(
        totalValue: (json['total_value_generated'] ?? 0).toDouble(),
        thisMonthValue: (json['this_month_value'] ?? 0).toDouble(),
        avgDealValue: (json['avg_deal_value'] ?? 0).toDouble(),
      );
}

class EventStats {
  final NextEvent? nextVirtual;
  final NextEvent? nextPhysical;
  final int attendedThisYear;

  EventStats({this.nextVirtual, this.nextPhysical, this.attendedThisYear = 0});

  factory EventStats.fromJson(Map<String, dynamic> json) => EventStats(
        nextVirtual: json['next_virtual'] != null ? NextEvent.fromJson(json['next_virtual']) : null,
        nextPhysical: json['next_physical'] != null ? NextEvent.fromJson(json['next_physical']) : null,
        attendedThisYear: json['attended_this_year'] ?? 0,
      );
}

class NextEvent {
  final String id;
  final String title;
  final String startAt;
  final String? location;
  final String? meetingLink;
  final String? imageUrl;

  NextEvent({required this.id, required this.title, required this.startAt, this.location, this.meetingLink, this.imageUrl});

  factory NextEvent.fromJson(Map<String, dynamic> json) => NextEvent(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        startAt: json['start_at'] ?? '',
        location: json['location'],
        meetingLink: json['meeting_link'],
        imageUrl: json['image_url'],
      );
}

class MembershipStats {
  final String status;
  final String type;
  final String? expiresAt;
  final int? daysUntilExpiry;

  MembershipStats({this.status = 'Inactive', this.type = 'None', this.expiresAt, this.daysUntilExpiry});

  factory MembershipStats.fromJson(Map<String, dynamic> json) => MembershipStats(
        status: json['status'] ?? 'Inactive',
        type: json['type'] ?? 'None',
        expiresAt: json['expires_at'],
        daysUntilExpiry: json['days_until_expiry'],
      );
}
