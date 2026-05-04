import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/matchmaking.dart';

class MatchmakingService {
  final ApiClient _api = ApiClient();

  Future<MatchingProfile> getProfile() async {
    final response = await _api.get('/matchmaking/profile');
    return MatchingProfile.fromJson(_api.unwrap(response));
  }

  Future<MatchingProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put('/matchmaking/profile', data: data);
    return MatchingProfile.fromJson(_api.unwrap(response));
  }

  Future<List<MatchSuggestion>> computeMatches() async {
    final response = await _api.post('/matchmaking/compute');
    final List data = _api.unwrap(response);
    return data.map((e) => MatchSuggestion.fromJson(e)).toList();
  }

  Future<List<MatchSuggestion>> getSuggestions() async {
    final response = await _api.get('/matchmaking/suggestions');
    final List data = _api.unwrap(response);
    return data.map((e) => MatchSuggestion.fromJson(e)).toList();
  }

  Future<String> getAiStrategy(String matchId) async {
    final response = await _api.post('/matchmaking/suggestions/$matchId/strategy');
    return _api.unwrap(response)['strategy'];
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    await _api.post('/matchmaking/suggestions/$matchId/status?status=$status');
  }
}
