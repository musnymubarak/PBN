import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/application.dart';
import 'package:pbn/models/chapter.dart';

class ApplicationService {
  final _api = ApiClient();

  Future<List<IndustryCategory>> getIndustryCategories() async {
    final res = await _api.get('/industry-categories');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => IndustryCategory.fromJson(j)).toList();
  }

  Future<void> submitApplication({
    required String fullName,
    required String businessName,
    required String contactNumber,
    required String email,
    required String district,
    required String industryCategoryId,
  }) async {
    await _api.post('/applications', data: {
      'full_name': fullName,
      'business_name': businessName,
      'contact_number': contactNumber,
      'email': email,
      'district': district,
      'industry_category_id': industryCategoryId,
    });
  }

  Future<List<Application>> getMyApplications() async {
    final res = await _api.get('/applications/my');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Application.fromJson(j)).toList();
  }
}
