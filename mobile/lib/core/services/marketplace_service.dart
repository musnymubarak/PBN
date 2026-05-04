import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/marketplace.dart';

class MarketplaceService {
  final ApiClient _client = ApiClient();

  Future<List<MarketplaceListing>> getListings({
    ListingCategory? category,
    String? industryId,
    String? search,
    bool featuredOnly = false,
    String? sellerId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = StringBuffer('limit=$limit&offset=$offset');
    if (category != null) queryParams.write('&category=${category.name}');
    if (industryId != null) queryParams.write('&industry_id=$industryId');
    if (search != null && search.isNotEmpty) queryParams.write('&search=$search');
    if (featuredOnly) queryParams.write('&featured_only=true');
    if (sellerId != null) queryParams.write('&seller_id=$sellerId');

    final response = await _client.get('/marketplace/listings?$queryParams');
    final List data = response.data;
    return data.map((json) => MarketplaceListing.fromJson(json)).toList();
  }

  Future<MarketplaceListing> getListing(String id) async {
    final response = await _client.get('/marketplace/listings/$id');
    return MarketplaceListing.fromJson(response.data);
  }

  Future<MarketplaceListing> createListing({
    required String title,
    required String description,
    required ListingCategory category,
    required String industryCategoryId,
    double? regularPrice,
    double? memberPrice,
    String currency = 'LKR',
    String? priceNote,
    List<String> imageUrls = const [],
    String? whatsappNumber,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final response = await _client.post('/marketplace/listings', data: {
      'title': title,
      'description': description,
      'category': category.name,
      'industry_category_id': industryCategoryId,
      'regular_price': regularPrice,
      'member_price': memberPrice,
      'currency': currency,
      'price_note': priceNote,
      'image_urls': imageUrls,
      'whatsapp_number': whatsappNumber,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
    });
    return MarketplaceListing.fromJson(response.data);
  }

  Future<MarketplaceListing> updateListing(
    String id, {
    String? title,
    String? description,
    ListingCategory? category,
    String? industryCategoryId,
    double? regularPrice,
    double? memberPrice,
    String? currency,
    String? priceNote,
    List<String>? imageUrls,
    String? whatsappNumber,
    String? contactEmail,
    String? contactPhone,
    ListingStatus? status,
  }) async {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category.name;
    if (industryCategoryId != null) data['industry_category_id'] = industryCategoryId;
    if (regularPrice != null) data['regular_price'] = regularPrice;
    if (memberPrice != null) data['member_price'] = memberPrice;
    if (currency != null) data['currency'] = currency;
    if (priceNote != null) data['price_note'] = priceNote;
    if (imageUrls != null) data['image_urls'] = imageUrls;
    if (whatsappNumber != null) data['whatsapp_number'] = whatsappNumber;
    if (contactEmail != null) data['contact_email'] = contactEmail;
    if (contactPhone != null) data['contact_phone'] = contactPhone;
    if (status != null) data['status'] = status.name;

    final response = await _client.patch('/marketplace/listings/$id', data: data);
    return MarketplaceListing.fromJson(response.data);
  }

  Future<void> deleteListing(String id) async {
    await _client.delete('/marketplace/listings/$id');
  }

  Future<MarketplaceInterest> expressInterest(String listingId, {String? message}) async {
    final response = await _client.post('/marketplace/listings/$listingId/interest', data: {
      'message': message,
    });
    return MarketplaceInterest.fromJson(response.data);
  }

  Future<List<MarketplaceInterest>> getInterests(String listingId) async {
    final response = await _client.get('/marketplace/listings/$listingId/interests');
    final List data = response.data;
    return data.map((json) => MarketplaceInterest.fromJson(json)).toList();
  }

  Future<bool> toggleFeature(String listingId) async {
    final response = await _client.post('/marketplace/listings/$listingId/feature');
    return response.data as bool;
  }

  Future<List<MarketplaceListing>> getMyListings() async {
    // We can use getListings but need to know the current user ID
    // or the backend supports a 'my' endpoint.
    // For now, let's assume we use getListings with a special flag if needed
    // but the backend router for /listings already supports seller_id
    final response = await _client.get('/marketplace/listings?my=true');
    final List data = response.data;
    return data.map((json) => MarketplaceListing.fromJson(json)).toList();
  }

  Future<MarketplaceInterest> updateInterestStatus(String interestId, {required String status, double? businessValue}) async {
    final response = await _client.patch('/marketplace/interests/$interestId', data: {
      'status': status,
      if (businessValue != null) 'business_value': businessValue,
    });
    return MarketplaceInterest.fromJson(response.data);
  }

  Future<String> uploadImage(String filePath) async {
    final response = await _client.upload('/marketplace/listings/upload', filePath);
    return response.data['data']['image_url'];
  }
}
