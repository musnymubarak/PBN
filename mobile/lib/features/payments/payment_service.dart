import 'package:dio/dio.dart';
import 'package:pbn/core/services/api_client.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final response = await _dio.get('/payments/my');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> uploadPaymentProof(
    String paymentId,
    String proofType,
    String? referenceNumber,
    String? filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'proof_type': proofType,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        if (filePath != null)
          'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/payments/$paymentId/proof',
        data: formData,
      );
      
      return response.data['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to upload payment proof');
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String paymentType,
    required double amount,
    String? eventId,
  }) async {
    try {
      final response = await _dio.post('/payments/initiate', data: {
        'payment_type': paymentType,
        'amount': amount,
        if (eventId != null) 'event_id': eventId,
      });
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to initiate payment');
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }
}
