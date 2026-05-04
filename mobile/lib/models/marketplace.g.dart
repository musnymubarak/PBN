// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketplaceListing _$MarketplaceListingFromJson(Map<String, dynamic> json) =>
    MarketplaceListing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$ListingCategoryEnumMap, json['category']),
      industryCategoryId: json['industry_category_id'] as String,
      regularPrice: _parseDouble(json['regular_price']),
      memberPrice: _parseDouble(json['member_price']),
      currency: json['currency'] as String,
      priceNote: json['price_note'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isFeatured: json['is_featured'] as bool,
      status: $enumDecode(_$ListingStatusEnumMap, json['status']),
      whatsappNumber: json['whatsapp_number'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      viewCount: (json['view_count'] as num).toInt(),
      interestCount: (json['interest_count'] as num).toInt(),
      isApproved: json['is_approved'] as bool,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sellerName: json['seller_name'] as String?,
      industryName: json['industry_name'] as String?,
    );

Map<String, dynamic> _$MarketplaceListingToJson(MarketplaceListing instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seller_id': instance.sellerId,
      'title': instance.title,
      'description': instance.description,
      'category': _$ListingCategoryEnumMap[instance.category]!,
      'industry_category_id': instance.industryCategoryId,
      'regular_price': instance.regularPrice,
      'member_price': instance.memberPrice,
      'currency': instance.currency,
      'price_note': instance.priceNote,
      'image_urls': instance.imageUrls,
      'is_featured': instance.isFeatured,
      'status': _$ListingStatusEnumMap[instance.status]!,
      'whatsapp_number': instance.whatsappNumber,
      'contact_email': instance.contactEmail,
      'contact_phone': instance.contactPhone,
      'view_count': instance.viewCount,
      'interest_count': instance.interestCount,
      'is_approved': instance.isApproved,
      'rejection_reason': instance.rejectionReason,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'seller_name': instance.sellerName,
      'industry_name': instance.industryName,
    };

const _$ListingCategoryEnumMap = {
  ListingCategory.product: 'product',
  ListingCategory.service: 'service',
  ListingCategory.consultation: 'consultation',
};

const _$ListingStatusEnumMap = {
  ListingStatus.active: 'active',
  ListingStatus.paused: 'paused',
  ListingStatus.sold_out: 'sold_out',
  ListingStatus.flagged: 'flagged',
  ListingStatus.removed: 'removed',
};

MarketplaceInterest _$MarketplaceInterestFromJson(Map<String, dynamic> json) =>
    MarketplaceInterest(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      interestedUserId: json['interested_user_id'] as String,
      interestedUserName: json['interested_user_name'] as String,
      message: json['message'] as String?,
      isRead: json['is_read'] as bool,
      status: $enumDecode(_$InterestStatusEnumMap, json['status']),
      businessValue: _parseDouble(json['business_value']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MarketplaceInterestToJson(
  MarketplaceInterest instance,
) => <String, dynamic>{
  'id': instance.id,
  'listing_id': instance.listingId,
  'interested_user_id': instance.interestedUserId,
  'interested_user_name': instance.interestedUserName,
  'message': instance.message,
  'is_read': instance.isRead,
  'status': _$InterestStatusEnumMap[instance.status]!,
  'business_value': instance.businessValue,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$InterestStatusEnumMap = {
  InterestStatus.pending: 'pending',
  InterestStatus.deal_confirmed: 'deal_confirmed',
  InterestStatus.cancelled: 'cancelled',
};
