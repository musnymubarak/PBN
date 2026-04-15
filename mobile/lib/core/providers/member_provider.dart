import 'package:flutter/material.dart';
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
      final chapters = await _chapterService.listChapters();
      List<Member> allMembers = [];
      for (var chapter in chapters) {
        final members = await _chapterService.getChapterMembers(chapter.id);
        allMembers.addAll(members);
      }
      
      _members = allMembers;
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
