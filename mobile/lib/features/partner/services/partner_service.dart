import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/features/partner/models/partner_stats.dart';

class PartnerService {

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PartnerDashboardStats> getDashboardStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rewards/partner/dashboard'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PartnerDashboardStats.fromJson(data['data']);
    } else {
      final error = json.decode(response.body)['message'] ?? 'Failed to load partner dashboard';
      throw Exception(error);
    }
  }

  Future<List<PartnerRedemptionItem>> getRedemptions() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rewards/partner/redemptions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((i) => PartnerRedemptionItem.fromJson(i)).toList();
    } else {
      final error = json.decode(response.body)['message'] ?? 'Failed to load redemptions';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> scanToken(String tokenStr) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rewards/partner/scan'),
      headers: headers,
      body: json.encode({'token': tokenStr}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to scan QR code');
    }
  }
}
