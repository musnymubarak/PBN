import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/reward.dart';

class RewardService {
  final _api = ApiClient();

  Future<PrivilegeCard?> getMyCard() async {
    try {
      final res = await _api.get('/rewards/my-card');
      final data = _api.unwrap(res);
      if (data == null) return null;
      return PrivilegeCard.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Partner>> listPartners() async {
    final res = await _api.get('/rewards/partners');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Partner.fromJson(j)).toList();
  }

  Future<void> redeemOffer(String offerId) async {
    await _api.post('/rewards/offers/$offerId/redeem');
  }
}
