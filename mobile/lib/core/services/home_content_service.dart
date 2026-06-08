import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/prefs_service.dart';
import 'package:pbn/models/home_slide.dart';

/// Fetches the dynamic home carousel and caches it locally so the carousel
/// paints instantly and survives offline launches.
class HomeContentService {
  final _api = ApiClient();
  static const _cacheKey = 'cache_home_slides';

  List<HomeSlide> _parse(dynamic list) {
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => HomeSlide.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Last-fetched slides from local cache (for instant first paint). Returns
  /// an empty list when nothing has been cached yet.
  List<HomeSlide> cachedSlides() => _parse(PrefsService.getJson(_cacheKey));

  /// Fetches slides from the API and refreshes the cache. Falls back to the
  /// cached copy if the network call fails.
  Future<List<HomeSlide>> getHomeSlides() async {
    try {
      final res = await _api.get('/home/slides');
      final data = _api.unwrap(res);
      final list = data is List ? data : <dynamic>[];
      await PrefsService.setJson(_cacheKey, list);
      return _parse(list);
    } catch (_) {
      return cachedSlides();
    }
  }
}
