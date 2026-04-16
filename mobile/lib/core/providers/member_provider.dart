import 'package:flutter/material.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/prefs_service.dart';
import 'package:pbn/models/member.dart';

class MemberProvider extends ChangeNotifier {
  final _chapterService = ChapterService();
  
  List<Member> _members = [];
  bool _loading = false;
  String? _error;

  List<Member> get members => _members;
  bool get loading => _loading;
  String? get error => _error;

  MemberProvider() {
    _loadFromCache();
  }

  /// Load from persistent storage on startup
  void _loadFromCache() {
    final cached = PrefsService.getJson('cached_members');
    if (cached != null && cached is List) {
      _members = cached.map((j) => Member.fromJson(j)).toList();
      notifyListeners();
    }
  }

  /// Fetch fresh data from API
  Future<void> fetchMembers({bool background = false}) async {
    if (!background) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // 1. Get user profile to check role
      final user = await AuthService().getProfile();
      
      if (user.role == 'super_admin' || user.role == 'chapter_admin') {
        // Admins can see everyone
        _members = await _chapterService.getAllMembers();
      } else {
        // 2. Regular members: Filter by their chapters
        final myMemberships = await _chapterService.getMyMemberships();
        final myChapterIds = myMemberships
            .map((m) => m.chapter.id)
            .toSet();

        if (myChapterIds.isEmpty) {
          _members = [];
          _error = 'You are not assigned to any chapter yet. Please contact support.';
          notifyListeners();
          return;
        }

        final futures = myChapterIds.map((id) => _chapterService.getChapterMembers(id));
        final nestedResults = await Future.wait(futures);
        
        List<Member> allMembers = [];
        for (var list in nestedResults) {
          allMembers.addAll(list);
        }
        
        final seenIds = <String>{};
        _members = allMembers.where((m) => seenIds.add(m.userId)).toList();
      }
      
      // Save for next app session
      await PrefsService.setJson('cached_members', _members.map((m) => m.toJson()).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _members = [];
    PrefsService.remove('cached_members');
    notifyListeners();
  }
}
