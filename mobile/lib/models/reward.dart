class PrivilegeCard {
  final String id;
  final String cardNumber;
  final String tier;
  final int points;
  final bool isActive;

  PrivilegeCard({
    required this.id,
    required this.cardNumber,
    required this.tier,
    required this.points,
    this.isActive = true,
  });

  factory PrivilegeCard.fromJson(Map<String, dynamic> json) => PrivilegeCard(
        id: json['id'] ?? '',
        cardNumber: json['card_number'] ?? '',
        tier: json['tier'] ?? 'standard',
        points: json['points'] ?? 0,
        isActive: json['is_active'] ?? true,
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

  Offer({
    required this.id,
    required this.title,
    this.description,
    required this.discountPercent,
    this.isActive = true,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        discountPercent: (json['discount_percent'] ?? 0).toDouble(),
        isActive: json['is_active'] ?? true,
      );
}
