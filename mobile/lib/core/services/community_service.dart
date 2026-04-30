import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/community.dart';

class CommunityService {
  final ApiClient _client = ApiClient();

  Future<List<CommunityPost>> getFeed({int limit = 20, int offset = 0, String? search, String filter = 'all', bool networkWide = false}) async {
    final queryParams = StringBuffer('limit=$limit&offset=$offset');
    if (search != null && search.isNotEmpty) queryParams.write('&search=$search');
    queryParams.write('&filter=$filter');
    queryParams.write('&network_wide=$networkWide');

    final response = await _client.get('/community/posts?$queryParams');
    final List data = response.data['data'];
    return data.map((json) => CommunityPost.fromJson(json)).toList();
  }

  Future<CommunityPost> createPost(
    String content, {
    String? imageUrl,
    String postType = 'general',
    String visibility = 'chapter',
    String? budgetRange,
    DateTime? deadline,
    String? targetClubId,
    String? targetIndustryId,
  }) async {
    final response = await _client.post('/community/posts', data: {
      'content': content,
      'image_url': imageUrl,
      'post_type': postType,
      'visibility': visibility,
      'budget_range': budgetRange,
      'deadline': deadline?.toIso8601String(),
      'target_club_id': targetClubId,
      'target_industry_id': targetIndustryId,
    });
    return CommunityPost.fromJson(response.data['data']);
  }

  Future<void> deletePost(String postId) async {
    await _client.delete('/community/posts/$postId');
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _client.post('/community/posts/$postId/like');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> togglePin(String postId) async {
    final response = await _client.post('/community/posts/$postId/pin');
    return response.data['data'];
  }

  Future<List<PostComment>> getComments(String postId) async {
    final response = await _client.get('/community/posts/$postId/comments');
    final List data = response.data['data'];
    return data.map((json) => PostComment.fromJson(json)).toList();
  }

  Future<PostComment> addComment(String postId, String content) async {
    final response = await _client.post('/community/posts/$postId/comments', data: {
      'content': content,
    });
    return PostComment.fromJson(response.data['data']);
  }

  Future<void> updateLeadStatus(String postId, String status) async {
    await _client.patch('/community/posts/$postId/status', data: {
      'status': status,
    });
  }

  Future<void> recordTYFB(String postId, double value) async {
    await _client.patch('/community/posts/$postId/tyfb', data: {
      'business_value': value,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete('/community/comments/$commentId');
  }
}
