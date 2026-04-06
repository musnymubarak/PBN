import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/referral.dart';

class ReferralService {
  final _api = ApiClient();

  Future<void> createReferral({
    required String targetUserId,
    required String leadName,
    required String leadContact,
    required String leadEmail,
    required String description,
  }) async {
    await _api.post('/referrals', data: {
      'target_user_id': targetUserId,
      'lead_name': leadName,
      'lead_contact': leadContact,
      'lead_email': leadEmail,
      'description': description,
    });
  }

  Future<List<Referral>> getGivenReferrals() async {
    final res = await _api.get('/referrals/my/given');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Referral.fromJson(j)).toList();
  }

  Future<List<Referral>> getReceivedReferrals() async {
    final res = await _api.get('/referrals/my/received');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Referral.fromJson(j)).toList();
  }

  Future<void> updateStatus(String refId, String status, {String? description}) async {
    await _api.patch('/referrals/$refId/status', data: {
      'status': status,
      if (description != null) 'description': description,
    });
  }
}
