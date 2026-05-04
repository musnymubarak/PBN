import 'package:json_annotation/json_annotation.dart';

part 'marketplace.g.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

enum ListingCategory {
  @JsonValue('product')
  product,
  @JsonValue('service')
  service,
  @JsonValue('consultation')
  consultation,
}

enum ListingStatus {
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('sold_out')
  sold_out,
  @JsonValue('flagged')
  flagged,
  @JsonValue('removed')
  removed,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MarketplaceListing {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final ListingCategory category;
  final String industryCategoryId;
  
  @JsonKey(fromJson: _parseDouble)
  final double? regularPrice;
  @JsonKey(fromJson: _parseDouble)
  final double? memberPrice;
  final String currency;
  final String? priceNote;
  
  final List<String> imageUrls;
  final bool isFeatured;
  final ListingStatus status;
  
  final String? whatsappNumber;
  final String? contactEmail;
  final String? contactPhone;
  
  final int viewCount;
  final int interestCount;
  final bool isApproved;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final String? sellerName;
  final String? industryName;

  MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.industryCategoryId,
    this.regularPrice,
    this.memberPrice,
    required this.currency,
    this.priceNote,
    required this.imageUrls,
    required this.isFeatured,
    required this.status,
    this.whatsappNumber,
    this.contactEmail,
    this.contactPhone,
    required this.viewCount,
    required this.interestCount,
    required this.isApproved,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.sellerName,
    this.industryName,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) => _$MarketplaceListingFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceListingToJson(this);
}

enum InterestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('deal_confirmed')
  deal_confirmed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MarketplaceInterest {
  final String id;
  final String listingId;
  final String interestedUserId;
  final String interestedUserName;
  final String? message;
  final bool isRead;
  final InterestStatus status;
  @JsonKey(fromJson: _parseDouble)
  final double? businessValue;
  final DateTime createdAt;

  MarketplaceInterest({
    required this.id,
    required this.listingId,
    required this.interestedUserId,
    required this.interestedUserName,
    this.message,
    required this.isRead,
    required this.status,
    this.businessValue,
    required this.createdAt,
  });

  factory MarketplaceInterest.fromJson(Map<String, dynamic> json) => _$MarketplaceInterestFromJson(json);
  Map<String, dynamic> toJson() => _$MarketplaceInterestToJson(this);
}
