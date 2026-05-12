class PrivilegeCard {
  final String id;
  final String cardNumber;
  final String tier;
  final int points;
  final bool isActive;
  final String? nfcUid;
  final String? memberName;
  final String? memberEmail;
  final String? membershipType;
  final String? chapterName;
  final String? businessName;
  final String? industryName;
  final String? verificationLevel;
  final String cardStatus;
  final int cardVersion;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? qrCodeData;

  PrivilegeCard({
    required this.id,
    required this.cardNumber,
    required this.tier,
    required this.points,
    this.isActive = true,
    this.nfcUid,
    this.memberName,
    this.memberEmail,
    this.membershipType,
    this.chapterName,
    this.businessName,
    this.industryName,
    this.verificationLevel,
    this.cardStatus = 'active',
    this.cardVersion = 1,
    this.issuedAt,
    this.expiresAt,
    this.qrCodeData,
  });

  factory PrivilegeCard.fromJson(Map<String, dynamic> json) => PrivilegeCard(
        id: json['id'] ?? '',
        cardNumber: json['card_number'] ?? '',
        tier: json['membership_type'] ?? json['tier'] ?? 'standard',
        points: json['points'] ?? 0,
        isActive: json['is_active'] ?? true,
        nfcUid: json['nfc_uid'],
        memberName: json['member_name'],
        memberEmail: json['member_email'],
        membershipType: json['membership_type'],
        chapterName: json['chapter_name'],
        businessName: json['business_name'],
        industryName: json['industry_name'],
        verificationLevel: json['verification_level'],
        cardStatus: json['card_status'] ?? 'active',
        cardVersion: json['card_version'] ?? 1,
        issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at']) : null,
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
        qrCodeData: json['qr_code_data'],
      );
}

class Partner {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final List<Offer> offers;

  Partner({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.isActive = true,
    this.offers = const [],
  });

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        logoUrl: json['logo_url'],
        isActive: json['is_active'] ?? true,
        offers: (json['offers'] as List<dynamic>?)
                ?.map((o) => Offer.fromJson(o))
                .toList() ??
            [],
      );
}

class Offer {
  final String id;
  final String title;
  final String? description;
  final double discountPercent;
  final bool isActive;
  final bool isRedeemedByMe;
  final String redemptionMethod; // 'qr' or 'coupon'

  Offer({
    required this.id,
    required this.title,
    this.description,
    required this.discountPercent,
    this.isActive = true,
    this.isRedeemedByMe = false,
    this.redemptionMethod = 'qr',
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        discountPercent: (json['discount_percentage'] ?? json['discount_percent'] ?? 0).toDouble(),
        isActive: json['is_active'] ?? true,
        isRedeemedByMe: json['is_redeemed_by_me'] ?? false,
        redemptionMethod: json['redemption_method'] ?? 'qr',
      );
}


/// Result from initiating a QR redemption
class RedeemTokenResult {
  final String token;
  final String qrUrl;
  final DateTime expiresAt;
  final String offerTitle;
  final String partnerName;

  RedeemTokenResult({
    required this.token,
    required this.qrUrl,
    required this.expiresAt,
    required this.offerTitle,
    required this.partnerName,
  });

  factory RedeemTokenResult.fromJson(Map<String, dynamic> json) => RedeemTokenResult(
        token: json['token'] ?? '',
        qrUrl: json['qr_url'] ?? '',
        expiresAt: DateTime.parse(json['expires_at']),
        offerTitle: json['offer_title'] ?? '',
        partnerName: json['partner_name'] ?? '',
      );
}


/// Status of a QR redemption token (mobile polls this)
class RedemptionStatus {
  final String status; // pending | confirmed | expired | cancelled
  final String? confirmedAt;
  final String? signerName;

  RedemptionStatus({
    required this.status,
    this.confirmedAt,
    this.signerName,
  });

  factory RedemptionStatus.fromJson(Map<String, dynamic> json) => RedemptionStatus(
        status: json['status'] ?? 'pending',
        confirmedAt: json['confirmed_at'],
        signerName: json['signer_name'],
      );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
}


/// Result from generating a coupon code
class CouponResult {
  final String code;
  final String offerTitle;
  final String partnerName;
  final int? discountPercentage;
  final DateTime expiresAt;

  CouponResult({
    required this.code,
    required this.offerTitle,
    required this.partnerName,
    this.discountPercentage,
    required this.expiresAt,
  });

  factory CouponResult.fromJson(Map<String, dynamic> json) => CouponResult(
        code: json['code'] ?? '',
        offerTitle: json['offer_title'] ?? '',
        partnerName: json['partner_name'] ?? '',
        discountPercentage: json['discount_percentage'],
        expiresAt: DateTime.parse(json['expires_at']),
      );
}
