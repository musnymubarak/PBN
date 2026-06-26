import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/notification_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  final _scrollController = ScrollController();

  List<NotificationItem> _notifications = [];
  bool _loading = true;
  bool _loadError = false;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      _notifications = await _service.listNotifications();
    } catch (_) {
      _loadError = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  // ──────────────────────────────────────────────────────────
  // ACTIONS — preserve immutable update pattern from the original
  // since NotificationItem has no copyWith.
  // ──────────────────────────────────────────────────────────
  Future<void> _markRead(String id) async {
    try {
      await _service.markRead(id);
      setState(() {
        _notifications = _notifications
            .map((n) => n.id == id ? _withRead(n, true) : n)
            .toList();
      });
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    HapticFeedback.selectionClick();
    try {
      await _service.markAllRead();
      setState(() {
        _notifications =
            _notifications.map((n) => _withRead(n, true)).toList();
      });
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      setState(() => _notifications.removeWhere((n) => n.id == id));
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (_) {}
  }

  NotificationItem _withRead(NotificationItem n, bool read) {
    return NotificationItem(
      id: n.id,
      title: n.title,
      body: n.body,
      notificationType: n.notificationType,
      isRead: read,
      sentAt: n.sentAt,
      data: n.data,
    );
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;
    final visible = _applyFilter(_notifications);
    final hasError =
        _loadError && _notifications.isEmpty && !_loading;
    final showSkeleton = _loading && _notifications.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: showSkeleton,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          color: AppColors.accent,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(unread),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList.list(
                  children: _buildAnimatedBody(
                    showSkeleton: showSkeleton,
                    hasError: hasError,
                    visible: visible,
                    unread: unread,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP BAR (P-13)
  // ──────────────────────────────────────────────────────────
  Widget _buildAppBar(int unread) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      floating: true,
      snap: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unread == 0
                ? 'All caught up'
                : '$unread unread • Pull to refresh',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
      actions: [
        const PbnAppBarActions(),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // BODY ASSEMBLY
  // ──────────────────────────────────────────────────────────
  List<Widget> _buildAnimatedBody({
    required bool showSkeleton,
    required bool hasError,
    required List<NotificationItem> visible,
    required int unread,
  }) {
    final blocks = <Widget>[];

    blocks.add(_buildFilterRow(unread));
    blocks.add(const SizedBox(height: 16));

    if (showSkeleton) {
      // Render shimmer placeholders that match the loaded layout.
      for (var i = 0; i < 4; i++) {
        blocks.add(_buildNotificationCard(_skeletonItem(i)));
        blocks.add(const SizedBox(height: 10));
      }
    } else if (hasError) {
      blocks.add(_buildErrorState());
    } else if (visible.isEmpty) {
      blocks.add(_buildEmptyState());
    } else {
      _addGroupedNotifications(blocks, visible);
    }

    blocks.add(const SizedBox(height: 24));

    return List.generate(blocks.length, (i) {
      final delayMs = (i * 25).clamp(0, 200);
      return blocks[i]
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
          .slideY(
              begin: 0.08,
              end: 0,
              duration: 280.ms,
              curve: Curves.easeOutCubic);
    });
  }

  void _addGroupedNotifications(
      List<Widget> sink, List<NotificationItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final todayList = <NotificationItem>[];
    final yesterdayList = <NotificationItem>[];
    final weekList = <NotificationItem>[];
    final olderList = <NotificationItem>[];

    for (final n in items) {
      final dt = _parseDate(n.sentAt);
      if (dt == null) {
        olderList.add(n);
        continue;
      }
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) {
        todayList.add(n);
      } else if (day == yesterday) {
        yesterdayList.add(n);
      } else if (day.isAfter(thisWeek)) {
        weekList.add(n);
      } else {
        olderList.add(n);
      }
    }

    void appendGroup(String title, List<NotificationItem> list) {
      if (list.isEmpty) return;
      sink.add(_sectionHeader(title, trailing: '${list.length}'));
      sink.add(const SizedBox(height: 10));
      for (final n in list) {
        sink.add(_buildNotificationCard(n));
        sink.add(const SizedBox(height: 10));
      }
      sink.add(const SizedBox(height: 14));
    }

    appendGroup('Today', todayList);
    appendGroup('Yesterday', yesterdayList);
    appendGroup('This Week', weekList);
    appendGroup('Earlier', olderList);
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1) + count
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                trailing,
                style: GoogleFonts.dmSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FILTER ROW — All / Unread
  // ──────────────────────────────────────────────────────────
  Widget _buildFilterRow(int unread) {
    return Row(
      children: [
        _filterChip(_Filter.all, 'All', _notifications.length),
        const SizedBox(width: 8),
        _filterChip(_Filter.unread, 'Unread', unread),
        if (unread > 0) ...[
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.accent.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.32)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.checks,
                        size: 13, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      'MARK ALL',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filterChip(_Filter value, String label, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: AppColors.goldGradient)
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border.withValues(alpha: 0.7),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    if (_filter == _Filter.unread) {
      return items.where((n) => !n.isRead).toList();
    }
    return items;
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final filtered = _filter == _Filter.unread;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(
              filtered ? TablerIcons.mail_check : TablerIcons.bell_off,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered ? "You're all caught up" : 'No notifications yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? "Every notification has been read. We'll let you know "
                    'when something new arrives.'
                : 'Activity from your chapter, referrals, marketplace, '
                    'and events will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.18),
                  AppColors.warning.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.30)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                size: 36, color: AppColors.warning),
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load notifications",
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _loadNotifications,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.refresh,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'RETRY',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // NOTIFICATION CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildNotificationCard(NotificationItem notif) {
    final meta = _typeMeta(notif.notificationType);
    final isRead = notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.18),
              AppColors.error.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.trash,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'DELETE',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.error,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteNotification(notif.id),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: meta.tint.withValues(alpha: 0.06),
          highlightColor: meta.tint.withValues(alpha: 0.04),
          onTap: () {
            if (!isRead) _markRead(notif.id);
            final route = notif.data?['route'];
            if (route is String && route.isNotEmpty) {
              Navigator.pushNamed(context, route);
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              // Unread tint uses the brand accent, not the off-palette
              // pale blue from the original.
              gradient: isRead
                  ? const LinearGradient(
                      colors: AppColors.surfaceGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.06),
                        AppColors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? AppColors.border.withValues(alpha: 0.6)
                    : AppColors.accent.withValues(alpha: 0.28),
                width: isRead ? 1 : 1.2,
              ),
              boxShadow: isRead
                  ? AppColors.shadowSm
                  : [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tinted icon container.
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        meta.tint.withValues(alpha: 0.18),
                        meta.tint.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: meta.tint.withValues(alpha: 0.22)),
                  ),
                  child: Icon(meta.icon, size: 18, color: meta.tint),
                ),
                const SizedBox(width: 12),
                // Content.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: GoogleFonts.dmSans(
                                fontWeight: isRead
                                    ? FontWeight.w700
                                    : FontWeight.w900,
                                fontSize: 13.5,
                                color: AppColors.text,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.goldGradient,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notif.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _categoryPill(meta),
                          const SizedBox(width: 8),
                          Icon(TablerIcons.clock,
                              size: 11,
                              color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _relativeTime(notif.sentAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryPill(_TypeMeta meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: meta.tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: meta.tint.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Text(
        meta.category,
        style: GoogleFonts.dmSans(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: meta.tint,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TYPE → icon + tint + category label
  // Built from the backend's notification_type strings (mixed case
  // because some types are uppercase like NEW_REFERRAL and some are
  // lowercase like community_post — we compare case-insensitively).
  // ──────────────────────────────────────────────────────────
  _TypeMeta _typeMeta(String rawType) {
    final t = rawType.toUpperCase();
    switch (t) {
      // Money / business closed
      case 'TYFB_RECEIVED':
      case 'PAYMENT_SUCCESS':
      case 'PAYMENT_RECORDED':
      case 'DEAL_ALERT':
        return _TypeMeta(
            icon: TablerIcons.trophy,
            tint: AppColors.accent,
            category: 'BUSINESS');
      // Referrals / leads
      case 'NEW_REFERRAL':
      case 'REFERRAL_UPDATE':
      case 'LEAD_STATUS_UPDATE':
        return _TypeMeta(
            icon: TablerIcons.route,
            tint: AppColors.accent,
            category: 'REFERRAL');
      // Members / applications / verification
      case 'NEW_APPLICATION':
        return _TypeMeta(
            icon: TablerIcons.user_plus,
            tint: AppColors.accentBlue,
            category: 'APPLICATION');
      case 'APPLICATION_APPROVED':
      case 'VERIFICATION_UPGRADE':
        return _TypeMeta(
            icon: TablerIcons.discount_check,
            tint: AppColors.success,
            category: 'VERIFIED');
      // Match suggestion
      case 'NOTICE_MATCH':
        return _TypeMeta(
            icon: TablerIcons.sparkles,
            tint: AppColors.accent,
            category: 'MATCH');
      // Marketplace
      case 'MARKETPLACE_INTEREST':
        return _TypeMeta(
            icon: TablerIcons.building_store,
            tint: AppColors.accentBlue,
            category: 'MARKETPLACE');
      // Community
      case 'COMMUNITY_POST':
        return _TypeMeta(
            icon: TablerIcons.message_2,
            tint: AppColors.accentBlue,
            category: 'COMMUNITY');
      case 'COMMUNITY_LIKE':
        return _TypeMeta(
            icon: TablerIcons.heart_filled,
            tint: AppColors.accentBlue,
            category: 'COMMUNITY');
      case 'COMMUNITY_COMMENT':
        return _TypeMeta(
            icon: TablerIcons.message_circle,
            tint: AppColors.accentBlue,
            category: 'COMMUNITY');
      // Events
      case 'RSVP_UPDATE':
        return _TypeMeta(
            icon: TablerIcons.calendar_event,
            tint: AppColors.accentBlue,
            category: 'EVENTS');
      // Rewards
      case 'NEW_REWARD':
        return _TypeMeta(
            icon: TablerIcons.gift,
            tint: AppColors.accent,
            category: 'REWARDS');
      // Default fallback
      default:
        return _TypeMeta(
            icon: TablerIcons.bell,
            tint: AppColors.textSecondary,
            category: 'UPDATE');
    }
  }

  // ──────────────────────────────────────────────────────────
  // Time helpers
  // ──────────────────────────────────────────────────────────
  DateTime? _parseDate(String iso) {
    if (iso.isEmpty) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _relativeTime(String iso) {
    final dt = _parseDate(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // ──────────────────────────────────────────────────────────
  // SKELETON SAMPLE
  // ──────────────────────────────────────────────────────────
  NotificationItem _skeletonItem(int i) {
    final types = [
      'NEW_REFERRAL',
      'COMMUNITY_POST',
      'TYFB_RECEIVED',
      'RSVP_UPDATE'
    ];
    return NotificationItem(
      id: 'sk-$i',
      title: 'Your chapter has a new opportunity to review',
      body: 'A member shared a high-priority lead in your industry.',
      notificationType: types[i % types.length],
      isRead: i.isOdd,
      sentAt: DateTime.now()
          .subtract(Duration(hours: i * 3))
          .toIso8601String(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────
class _TypeMeta {
  final IconData icon;
  final Color tint;
  final String category;
  const _TypeMeta({
    required this.icon,
    required this.tint,
    required this.category,
  });
}

enum _Filter { all, unread }
