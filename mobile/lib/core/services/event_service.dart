import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/event.dart';

class EventService {
  final _api = ApiClient();

  Future<List<Event>> listEvents({String? chapterId}) async {
    final res = await _api.get('/events', queryParams: {
      if (chapterId != null) 'chapter_id': chapterId,
      'published_only': true,
    });
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Event.fromJson(j)).toList();
  }

  Future<void> updateRSVP(String eventId, String status) async {
    await _api.post('/events/$eventId/rsvp', data: {'status': status});
  }
}
