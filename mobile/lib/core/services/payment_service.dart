import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/payment.dart';

class PaymentService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentType,
    required double amount,
    String? eventId,
  }) async {
    final res = await _api.post('/payments/initiate', data: {
      'payment_type': paymentType,
      'amount': amount,
      if (eventId != null) 'event_id': eventId,
    });
    return _api.unwrap(res) as Map<String, dynamic>;
  }

  Future<List<Payment>> getMyPayments() async {
    final res = await _api.get('/payments/my');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Payment.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final res = await _api.get('/payments/$paymentId/status');
    return _api.unwrap(res) as Map<String, dynamic>;
  }
}
