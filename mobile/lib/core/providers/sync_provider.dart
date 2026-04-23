import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';

/// Centralized background sync manager.
/// 
/// Polls all critical data sources on a fixed interval so that
/// admin-side changes (role updates, member additions/removals,
/// profile edits, etc.) are reflected in the app with near-zero delay.
class SyncProvider extends ChangeNotifier {
  AuthProvider? _authProvider;
  MemberProvider? _memberProvider;
  NotificationProvider? _notificationProvider;

  Timer? _syncTimer;
  DateTime? _lastSync;
  bool _syncing = false;

  /// How often we poll the backend (in seconds).
  /// 30s gives near-real-time feel without hammering the server.
  static const int _syncIntervalSeconds = 30;

  DateTime? get lastSync => _lastSync;
  bool get syncing => _syncing;

  /// Attach the providers that this sync manager coordinates.
  /// Call once from the top-level widget after providers are available.
  void attach({
    required AuthProvider auth,
    required MemberProvider members,
    required NotificationProvider notifications,
  }) {
    _authProvider = auth;
    _memberProvider = members;
    _notificationProvider = notifications;
  }

  /// Start the periodic background sync loop.
  void startSync() {
    // Cancel any existing timer to avoid duplicates
    _syncTimer?.cancel();

    // Run an immediate sync on start
    _runSync();

    // Then schedule periodic syncs
    _syncTimer = Timer.periodic(
      const Duration(seconds: _syncIntervalSeconds),
      (_) => _runSync(),
    );

    debugPrint('[SyncProvider] Background sync started (${_syncIntervalSeconds}s interval)');
  }

  /// Stop the background sync (e.g. on logout).
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('[SyncProvider] Background sync stopped');
  }

  /// Force an immediate sync (e.g. after a mutation).
  Future<void> forceSync() async {
    await _runSync();
  }

  /// Internal: execute all sync tasks in parallel.
  Future<void> _runSync() async {
    if (_syncing) return; // Prevent overlapping syncs
    if (_authProvider == null || _authProvider!.status != AuthStatus.authenticated) return;

    _syncing = true;

    try {
      await Future.wait([
        // 1. Refresh user profile (catches role changes, deactivation, etc.)
        _authProvider!.refreshProfile(),

        // 2. Refresh member directory in the background
        _memberProvider!.fetchMembers(background: true),

        // 3. Refresh notification badge count
        _notificationProvider!.fetchUnreadCount(),
      ]);

      _lastSync = DateTime.now();
    } catch (e) {
      debugPrint('[SyncProvider] Sync error: $e');
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}
