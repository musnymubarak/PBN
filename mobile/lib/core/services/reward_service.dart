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

  /// Legacy direct redemption
  Future<void> redeemOffer(String offerId) async {
    await _api.post('/rewards/offers/$offerId/redeem');
  }

  /// Initiate QR-based redemption — returns token + QR URL
  Future<RedeemTokenResult> initiateRedeem(String offerId) async {
    final res = await _api.post('/rewards/offers/$offerId/initiate-redeem');
    final data = _api.unwrap(res);
    return RedeemTokenResult.fromJson(data);
  }

  /// Poll redemption status (mobile calls this every few seconds)
  Future<RedemptionStatus> checkRedemptionStatus(String token) async {
    final res = await _api.get('/rewards/redemptions/status/$token');
    final data = _api.unwrap(res);
    return RedemptionStatus.fromJson(data);
  }

  /// Generate coupon code for online purchase offers
  Future<CouponResult> generateCoupon(String offerId) async {
    final res = await _api.post('/rewards/offers/$offerId/generate-coupon');
    final data = _api.unwrap(res);
    return CouponResult.fromJson(data);
  }
}
