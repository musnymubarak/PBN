import 'package:dio/dio.dart';
import 'package:pbn/core/config/api_config.dart';

class PaymentService {
  final Dio _dio = ApiConfig.client;

  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final response = await _dio.get('/payments/my');
      if (response.data['success'] == true) {
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
      
      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to upload payment proof');
    }
  }
}
