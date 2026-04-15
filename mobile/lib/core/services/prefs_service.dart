import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for persistent storage of simple key-value pairs and JSON data.
class PrefsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Onboarding ──────────────────────────────────────────
  static const _keyFirstRun = 'is_first_run';
  static bool isFirstRun() => _prefs?.getBool(_keyFirstRun) ?? true;
  static Future<void> markFirstRunDone() => _prefs?.setBool(_keyFirstRun, false) ?? Future.value();

  // ── Data Caching (General) ────────────────────────────────
  static Future<void> setJson(String key, dynamic val) async {
    await _prefs?.setString(key, jsonEncode(val));
  }

  static dynamic getJson(String key) {
    final str = _prefs?.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) => _prefs?.remove(key) ?? Future.value();
  static Future<void> clear() => _prefs?.clear() ?? Future.value();
}
