import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/horizontal_club.dart';

class ClubService {
  final _api = ApiClient();

  Future<List<HorizontalClub>> listClubs() async {
    final res = await _api.get('/horizontal-clubs');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => HorizontalClub.fromJson(j)).toList();
  }

  Future<void> joinClub(String clubId) async {
    await _api.post('/horizontal-clubs/$clubId/join');
  }

  Future<void> leaveClub(String clubId) async {
    await _api.post('/horizontal-clubs/$clubId/leave');
  }
}
