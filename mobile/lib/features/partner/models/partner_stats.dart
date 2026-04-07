class PartnerRedemptionItem {
  final String id;
  final String offerTitle;
  final String userName;
  final String userPhone;
  final String? userEmail;
  final String redeemedAt;
  final String? signerName;

  PartnerRedemptionItem({
    required this.id,
    required this.offerTitle,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.redeemedAt,
    this.signerName,
  });

  factory PartnerRedemptionItem.fromJson(Map<String, dynamic> json) {
    return PartnerRedemptionItem(
      id: json['id'] ?? '',
      offerTitle: json['offer_title'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userEmail: json['user_email'],
      redeemedAt: json['redeemed_at'] ?? '',
      signerName: json['signer_name'],
    );
  }
}

class PartnerDashboardStats {
  final String partnerName;
  final int totalRedemptions;
  final int activeOffers;
  final List<PartnerRedemptionItem> recentRedemptions;

  PartnerDashboardStats({
    required this.partnerName,
    required this.totalRedemptions,
    required this.activeOffers,
    required this.recentRedemptions,
  });

  factory PartnerDashboardStats.fromJson(Map<String, dynamic> json) {
    return PartnerDashboardStats(
      partnerName: json['partner_name'] ?? '',
      totalRedemptions: json['total_redemptions'] ?? 0,
      activeOffers: json['active_offers'] ?? 0,
      recentRedemptions: (json['recent_redemptions'] as List? ?? [])
          .map((i) => PartnerRedemptionItem.fromJson(i))
          .toList(),
    );
  }
}
