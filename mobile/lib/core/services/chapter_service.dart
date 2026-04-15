import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/member.dart';

class ChapterService {
  final _api = ApiClient();

  Future<List<Chapter>> listChapters() async {
    final res = await _api.get('/chapters');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Chapter.fromJson(j)).toList();
  }

  Future<List<Membership>> getMyMemberships() async {
    final res = await _api.get('/chapters/my-memberships');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Membership.fromJson(j)).toList();
  }

  Future<List<Member>> getChapterMembers(String chapterId) async {
    final res = await _api.get('/chapters/$chapterId/members');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Member.fromJson(j)).toList();
  }

  Future<List<Member>> getAllMembers() async {
    final res = await _api.get('/chapters/members/all');
    final list = _api.unwrap(res) as List<dynamic>;
    return list.map((j) => Member.fromJson(j)).toList();
  }
}
