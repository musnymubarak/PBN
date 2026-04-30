import 'package:flutter/material.dart';
import 'package:pbn/core/services/club_service.dart';
import 'package:pbn/core/services/prefs_service.dart';
import 'package:pbn/models/horizontal_club.dart';

class ClubProvider extends ChangeNotifier {
  final _clubService = ClubService();
  
  List<HorizontalClub> _clubs = [];
  bool _loading = false;
  String? _error;

  List<HorizontalClub> get clubs => _clubs;
  bool get loading => _loading;
  String? get error => _error;

  ClubProvider() {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = PrefsService.getJson('cached_clubs');
    if (cached != null && cached is List) {
      _clubs = cached.map((j) => HorizontalClub.fromJson(j)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchClubs({bool background = false}) async {
    if (!background) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _clubs = await _clubService.listClubs();
      await PrefsService.setJson('cached_clubs', _clubs.map((c) => c.toJson()).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleMembership(HorizontalClub club) async {
    try {
      if (club.isMember) {
        await _clubService.leaveClub(club.id);
      } else {
        await _clubService.joinClub(club.id);
      }
      await fetchClubs(background: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearCache() {
    _clubs = [];
    PrefsService.remove('cached_clubs');
    notifyListeners();
  }
}
