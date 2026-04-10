import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/dashboard_data.dart';

class DashboardService {
  final _api = ApiClient();

  Future<DashboardData> getDashboard() async {
    final res = await _api.get('/dashboard');
    return DashboardData.fromJson(_api.unwrap(res));
  }

  Future<List<dynamic>> getLeaderboard({String? chapterId, String period = 'this_month'}) async {
    final res = await _api.get('/leaderboard', queryParams: {
      if (chapterId != null) 'chapter_id': chapterId,
      'period': period,
    });
    final data = _api.unwrap(res);
    return (data['entries'] as List?)?.cast<dynamic>() ?? [];
  }

  Future<List<dynamic>> getRoi({String period = 'last_6_months'}) async {
    final res = await _api.get('/analytics/roi', queryParams: {'period': period});
    return _api.unwrap(res) as List<dynamic>;
  }
}
