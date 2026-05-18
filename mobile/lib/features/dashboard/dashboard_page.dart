import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:pbn/core/services/event_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/models/dashboard_data.dart';
import 'package:pbn/models/event.dart';

import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/features/members/members_page.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/profile/profile_page.dart';
import 'package:pbn/features/support/support_page.dart';
import 'package:pbn/features/marketplace/marketplace_page.dart';
import 'package:pbn/features/matchmaking/matchmaking_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DashboardData? _data;

  List<dynamic> _leaderboard = [];
  bool _loading = true;
  String? _error;

  // -- Sliding Ads Logic --
  final PageController _adController = PageController();
  int _adIndex = 0;
  Timer? _adTimer;

  NextEvent? _fallbackVirtual;
  NextEvent? _fallbackPhysical;

  // -- ROI chart state --
  String _roiPeriod = '1M';
  List<FlSpot> _roiSeries = [];
  bool _loadingRoi = false;

  final _dashboardService = DashboardService();
  final _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adController.dispose();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted && _adController.hasClients) {
        setState(() {
          _adIndex = (_adIndex + 1) % 3; // Cycle between 3 ads
          _adController.animateToPage(
            _adIndex,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutQuart,
          );
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        _dashboardService.getDashboard(),
        auth.refreshProfile(),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as DashboardData;
          _loading = false;
        });
        _loadLeaderboard();
        _loadEventFallbacks();
        _loadRoi(_roiPeriod);
        if (mounted) {
          final notifProvider = context.read<NotificationProvider>();
          notifProvider.startListening();
          notifProvider.fetchUnreadCount();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final auth = context.read<AuthProvider>();
      final entries = await _dashboardService.getLeaderboard(
        chapterId: auth.user?.chapterId,
        period: 'this_month',
      );
      if (mounted) {
        setState(() {
          _leaderboard = entries.take(3).toList();
        });
      }
    } catch (_) {}
  }

  String _periodApiKey(String label) {
    switch (label) {
      case '1M':
        return 'last_1_month';
      case '3M':
        return 'last_3_months';
      case '1Y':
        return 'last_12_months';
      default:
        return 'last_1_month';
    }
  }

  Future<void> _loadRoi(String label) async {
    if (!mounted) return;
    setState(() {
      _roiPeriod = label;
      _loadingRoi = true;
    });
    try {
      final raw = await _dashboardService.getRoi(period: _periodApiKey(label));
      final values = <double>[];
      for (final item in raw) {
        double? v;
        if (item is num) {
          v = item.toDouble();
        } else if (item is Map) {
          final cand = item['value'] ??
              item['amount'] ??
              item['total'] ??
              item['roi'] ??
              item['roi_value'] ??
              item['value_generated'];
          if (cand is num) v = cand.toDouble();
        }
        if (v != null) values.add(v);
      }
      final spots = <FlSpot>[
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ];
      if (mounted) {
        setState(() {
          _roiSeries = spots;
          _loadingRoi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _roiSeries = [];
          _loadingRoi = false;
        });
      }
    }
  }

  Future<void> _loadEventFallbacks() async {
    final needsVirtual = _data?.events.nextVirtual == null;
    final needsPhysical = _data?.events.nextPhysical == null;
    if (!needsVirtual && !needsPhysical) return;

    try {
      final auth = context.read<AuthProvider>();
      final events = await _eventService.listEvents(chapterId: auth.user?.chapterId);
      final now = DateTime.now();

      Event? soonest(bool Function(Event) match) {
        final upcoming = events.where((e) {
          if (!match(e)) return false;
          try {
            return DateTime.parse(e.startAt).toLocal().isAfter(now);
          } catch (_) {
            return false;
          }
        }).toList()
          ..sort((a, b) {
            try {
              return DateTime.parse(a.startAt)
                  .compareTo(DateTime.parse(b.startAt));
            } catch (_) {
              return 0;
            }
          });
        return upcoming.isEmpty ? null : upcoming.first;
      }

      bool isVirtual(Event e) {
        final t = e.eventType.toLowerCase();
        return t == 'virtual' ||
            t == 'online' ||
            t == 'zoom' ||
            (e.meetingLink != null && e.meetingLink!.isNotEmpty);
      }

      bool isPhysical(Event e) {
        final t = e.eventType.toLowerCase();
        return t == 'physical' ||
            t == 'in_person' ||
            t == 'inperson' ||
            t == 'offline' ||
            (e.location != null && e.location!.isNotEmpty && !isVirtual(e));
      }

      NextEvent toNext(Event e) => NextEvent(
            id: e.id,
            title: e.title,
            startAt: e.startAt,
            location: e.location,
            meetingLink: e.meetingLink,
            imageUrl: e.imageUrl,
          );

      Event? v = needsVirtual ? soonest(isVirtual) : null;
      Event? p = needsPhysical ? soonest(isPhysical) : null;

      if (mounted) {
        setState(() {
          if (v != null) _fallbackVirtual = toNext(v);
          if (p != null) _fallbackPhysical = toNext(p);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isProspect = auth.user?.role.toUpperCase() == 'PROSPECT';

    final pages = isProspect
        ? [_buildProspectDashboard(), const ProfilePage()]
        : [
            _buildDashboardBody(),
            const MembersPage(),
            const MarketplacePage(),
            const MatchmakingDashboardPage(),
            const ProfilePage(),
          ];

    if (_currentIndex >= pages.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          IndexedStack(index: _currentIndex, children: pages),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isProspect),
    );
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _tierColor(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return const Color(0xFF8B5CF6);
      case 'gold':
        return AppColors.accent;
      case 'silver':
        return const Color(0xFF94A3B8);
      default:
        return AppColors.accentBlue;
    }
  }

  Widget _buildSliverAppBar(bool isProspect) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final firstName = user?.fullName.split(' ').first ?? 'Member';
    final level = user?.verificationLevel ?? 'none';
    final hasTier = level.toLowerCase() != 'none';
    final tierColor = _tierColor(level);

    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // Gold-ringed avatar
          GestureDetector(
            onTap: () => setState(() => _currentIndex = isProspect ? 1 : 4),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: AppColors.goldSoftGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CachedAvatar(
                imageUrl: user?.profilePhoto,
                initials: user?.initials ?? '?',
                size: 36,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeGreeting(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (hasTier)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              tierColor.withValues(alpha: 0.18),
                              tierColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: tierColor.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TablerIcons.discount_check_filled,
                                size: 9, color: tierColor),
                            const SizedBox(width: 2),
                            Text(
                              level.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: tierColor,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: const [PbnAppBarActions()],
    );
  }

  Widget _sectionHeader({required String title, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
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
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.4,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildDashboardBody() {
    if (_error != null) return _buildErrorState();

    final sections = <Widget>[
      AspectRatio(
        aspectRatio: 1.586,
        child: PageView(
          controller: _adController,
          onPageChanged: (i) => setState(() => _adIndex = i),
          children: [
            _buildAdPromoPanel(),
            _buildEventZoomPanel(),
            _buildPhysicalMeetingPanel(),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _buildAdIndicator(),
      const SizedBox(height: 18),
      _buildSmartActionCard(),
      const SizedBox(height: 14),
      _buildClubsQuickLink(),
      const SizedBox(height: 28),
      _sectionHeader(title: 'Your Performance'),
      _buildRoiHeroCard(),
      const SizedBox(height: 12),
      SizedBox(
        height: 168,
        child: Builder(builder: (ctx) {
          final sentTotal = _data?.referrals.sentTotal ?? 0;
          final sentMonth = _data?.referrals.sentThisMonth ?? 0;
          final receivedTotal = _data?.referrals.receivedTotal ?? 0;
          final receivedMonth = _data?.referrals.receivedThisMonth ?? 0;
          final rate = (_data?.referrals.conversionRate ?? 0).toDouble();

          double safeRatio(int part, int total) =>
              total > 0 ? (part / total).clamp(0.0, 1.0) : 0.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatTile(
                  title: 'Business Sent',
                  value: '$sentTotal',
                  icon: TablerIcons.arrow_up_right,
                  accentColor: const Color(0xFF3B82F6),
                  deltaCount: sentMonth,
                  progress: safeRatio(sentMonth, sentTotal),
                  progressCaption: sentTotal > 0
                      ? '$sentMonth of $sentTotal this month'
                      : 'No referrals yet',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  title: 'Ratio',
                  value: '${rate.toStringAsFixed(0)}%',
                  icon: TablerIcons.chart_pie,
                  accentColor: const Color(0xFF10B981),
                  deltaLabel: rate >= 50 ? 'Healthy' : 'Active',
                  isPositive: rate >= 50,
                  progress: (rate / 100).clamp(0.0, 1.0),
                  progressCaption: rate >= 75
                      ? 'Excellent conversion'
                      : rate >= 50
                          ? 'Above average'
                          : 'Room to grow',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  title: 'Incoming',
                  value: '$receivedTotal',
                  icon: TablerIcons.arrow_down_left,
                  accentColor: const Color(0xFF8B5CF6),
                  deltaCount: receivedMonth,
                  progress: safeRatio(receivedMonth, receivedTotal),
                  progressCaption: receivedTotal > 0
                      ? '$receivedMonth of $receivedTotal this month'
                      : 'No leads yet',
                ),
              ),
            ],
          );
        }),
      ),
      const SizedBox(height: 14),
      _buildActivityPulse(),
      const SizedBox(height: 28),
      _buildLeaderboardPreview(),
      const SizedBox(height: 24),
      _buildDailyInsight(),
      const SizedBox(height: 28),
      _sectionHeader(title: 'Explore Network'),
      Row(
        children: [
          _modernActionTile(
            TablerIcons.stars,
            'Rewards',
            AppColors.accent,
            () => Navigator.pushNamed(context, '/rewards'),
            badge: 'NEW',
          ),
          const SizedBox(width: 14),
          _modernActionTile(
            TablerIcons.building_community,
            'Chapters',
            const Color(0xFF3B82F6),
            () => Navigator.pushNamed(context, '/chapters'),
          ),
          const SizedBox(width: 14),
          _modernActionTile(
            TablerIcons.help_circle,
            'Support',
            const Color(0xFFE11D74),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportPage()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
    ];

    return sk.Skeletonizer(
      enabled: _loading,
      enableSwitchAnimation: true,
      effect: sk.ShimmerEffect(
        baseColor: AppColors.surfaceAlt,
        highlightColor: Colors.white.withValues(alpha: 0.9),
        duration: const Duration(milliseconds: 1400),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(false),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList.list(
                children: List.generate(sections.length, (i) {
                  // Cascade only above-the-fold items; cap delay so bottom
                  // sections don't wait for the whole list to finish.
                  final delayMs = (i * 35).clamp(0, 280);
                  return sections[i]
                      .animate(delay: delayMs.ms)
                      .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.10, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_adIndex + 1}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(3, (i) {
                final active = _adIndex == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 4),
                  width: active ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(colors: AppColors.goldGradient)
                        : null,
                    color: active ? null : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                '3',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({IconData icon, String title, String subtitle, VoidCallback onTap}) _smartAction() {
    final pending = _data?.referrals.pendingFollowup ?? 0;
    final sentThisMonth = _data?.referrals.sentThisMonth ?? 0;
    final virtual = _data?.events.nextVirtual ?? _fallbackVirtual;
    final physical = _data?.events.nextPhysical ?? _fallbackPhysical;

    NextEvent? soonest;
    int soonestDays = 999;
    for (final e in [virtual, physical]) {
      if (e == null) continue;
      try {
        final dt = DateTime.parse(e.startAt).toLocal();
        final diff = dt.difference(DateTime.now()).inDays;
        if (diff >= 0 && diff <= 7 && diff < soonestDays) {
          soonest = e;
          soonestDays = diff;
        }
      } catch (_) {}
    }

    if (pending > 0) {
      return (
        icon: TablerIcons.checklist,
        title: 'Follow up on $pending ${pending == 1 ? "referral" : "referrals"}',
        subtitle: 'Your network is waiting for your update',
        onTap: () => Navigator.pushNamed(context, '/my-referrals'),
      );
    }
    if (soonest != null) {
      final whenText = soonestDays == 0
          ? 'today'
          : soonestDays == 1
              ? 'tomorrow'
              : 'in $soonestDays days';
      return (
        icon: TablerIcons.calendar_star,
        title: 'Next event $whenText',
        subtitle: soonest.title,
        onTap: () => Navigator.pushNamed(context, '/events'),
      );
    }
    if (sentThisMonth == 0) {
      return (
        icon: TablerIcons.send,
        title: 'Send your first referral this month',
        subtitle: 'Givers gain — every introduction counts',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateReferralPage()),
        ),
      );
    }
    return (
      icon: TablerIcons.compass,
      title: 'Discover new connections',
      subtitle: 'Explore chapters across the network',
      onTap: () => Navigator.pushNamed(context, '/chapters'),
    );
  }

  Widget _buildSmartActionCard() {
    final action = _smartAction();
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AppColors.goldGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NEXT FOR YOU',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent.withValues(alpha: 0.9),
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          action.subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      TablerIcons.arrow_up_right,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityPulse() {
    final conv = (_data?.referrals.conversionRate ?? 0).toStringAsFixed(0);
    final pending = _data?.referrals.pendingFollowup ?? 0;
    final avg = _data?.roi.avgDealValue ?? 0;

    Widget chip(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: color, size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(TablerIcons.flame, const Color(0xFFEF4444), '$conv%', 'CONVERSION'),
        const SizedBox(width: 8),
        chip(TablerIcons.clipboard_list, AppColors.warning, '$pending', 'PENDING'),
        const SizedBox(width: 8),
        chip(TablerIcons.diamond, AppColors.accentBlue, _formatCurrency(avg), 'AVG DEAL'),
      ],
    );
  }

  Widget _buildDailyInsight() {
    const insights = [
      ('Members who follow up within 24 hours close 3× more deals.', 'Engagement Velocity'),
      ('Your network\'s strength is measured by who you can call at 2am.', 'Network Depth'),
      ('Givers gain. Members who send 5+ referrals receive 4× more in return.', 'Reciprocity Loop'),
      ('Quality over quantity — 10 trusted connections outperform 100 acquaintances.', 'Network Quality'),
      ('The best opportunity often arrives wrapped in a casual conversation.', 'Serendipity'),
      ('Specificity in asks attracts 2× more responses than vague requests.', 'Sharp Asks'),
      ('Top performers spend 15 minutes daily nurturing 3 relationships.', 'Daily Discipline'),
    ];
    final idx = DateTime.now().day % insights.length;
    final quote = insights[idx];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF7), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.sparkles, size: 12, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'DAILY INSIGHT · ${quote.$2.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  quote.$1,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPromoPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: _smartImage(
                'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=600',
                const [AppColors.primary, Color(0xFF1E293B)],
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Floating accent orb
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NETWORK GROWTH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Expand your business reach effortlessly.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateReferralPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text(
                      'SUBMIT OPPORTUNITY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventZoomPanel() {
    final event = _data?.events.nextVirtual ?? _fallbackVirtual;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (event != null) ...[
              Positioned.fill(
                child: _smartImage(
                  event.imageUrl != null
                      ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${event.imageUrl}'
                      : 'https://images.unsplash.com/photo-1588196749597-9ff075ee6b5b?auto=format&fit=crop&q=80&w=600',
                  const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'NEXT ONLINE SESSION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(TablerIcons.calendar_event, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(event.startAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _launchMeeting(event.meetingLink),
                      icon: const Icon(TablerIcons.video, size: 16),
                      label: const Text(
                        'JOIN ZOOM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              _buildEmptyAdState(
                title: 'No upcoming sessions',
                subtitle: 'Explore events to stay connected',
                buttonText: 'BROWSE EVENTS',
                onPressed: () => Navigator.pushNamed(context, '/events'),
                color: const Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }

  void _launchMeeting(String? link) async {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link not available')));
      return;
    }
    final url = Uri.parse(link);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open meeting link')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid meeting link')));
    }
  }

  Widget _buildEmptyAdState({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Abstract patterns
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(TablerIcons.calendar_star, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TablerIcons.calendar_event, size: 40, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Colors.white, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalMeetingPanel() {
    final event = _data?.events.nextPhysical ?? _fallbackPhysical;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (event != null) ...[
              Positioned.fill(
                child: _smartImage(
                  event.imageUrl != null
                      ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${event.imageUrl}'
                      : 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=600',
                  const [AppColors.primary, Color(0xFFEA580C)],
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'CHAPTER MEETUP',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(TablerIcons.calendar_event, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(event.startAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _launchMaps(event.location),
                      icon: const Icon(TablerIcons.map_pin, size: 16),
                      label: const Text(
                        'VIEW LOCATION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              _buildEmptyAdState(
                title: 'No upcoming meetups',
                subtitle: 'Discover opportunities nearby',
                buttonText: 'SEE ALL CHAPTERS',
                onPressed: () => Navigator.pushNamed(context, '/chapters'),
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _launchMaps(String? location) async {
    if (location == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available')));
      return;
    }
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error opening maps')));
    }
  }

  Widget _smartImage(String url, List<Color> fallbackColors) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: fallbackColors),
              ),
            ),
      errorBuilder: (context, error, stack) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fallbackColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.1,
            child: Icon(TablerIcons.photo, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Date TBD';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('EEEE | hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.alert_triangle, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 48),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProspectDashboard() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(true),
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverList.list(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(TablerIcons.building_community, size: 48, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Verification Pending',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Your application is being reviewed. Verified members unlock access to leads, events, and rewards.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(TablerIcons.progress_check, color: AppColors.success),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Applied', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('We have received your application', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage())),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 56)),
                child: const Text('CONTACT SUPPORT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isProspect) {
    final navItems = isProspect
        ? [
            _NavItem(TablerIcons.smart_home, 'Home', 0),
            _NavItem(TablerIcons.user_circle, 'Me', 1),
          ]
        : [
            _NavItem(TablerIcons.smart_home, 'Home', 0),
            _NavItem(TablerIcons.users, 'Members', 1),
            _NavItem(TablerIcons.shopping_cart, 'Market', 2),
            _NavItem(TablerIcons.briefcase, 'Matches', 3),
            _NavItem(TablerIcons.user_circle, 'Me', 4),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBase.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: navItems.map((item) {
              bool isActive = _currentIndex == item.index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = item.index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.18),
                                  AppColors.accent.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isActive ? AppColors.accent : AppColors.textMuted,
                            size: isActive ? 23 : 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                              color: isActive ? AppColors.accent : AppColors.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: isActive ? 18 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.goldGradient,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _modernActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.06),
          highlightColor: color.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.surfaceGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
              boxShadow: AppColors.shadowMd,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.18),
                            color.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.22),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.5),
                            color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.goldGradient,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double v) {
    if (v >= 1000000000) {
      return 'LKR ${NumberFormat("#,##0.0").format(v / 1000000000)}B';
    }
    if (v >= 1000000) {
      return 'LKR ${NumberFormat("#,##0.0").format(v / 1000000)}M';
    }
    return 'LKR ${NumberFormat("#,##0").format(v)}';
  }

  Widget _buildLeaderboardPreview() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Top Performers',
          trailing: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/leaderboard');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 2),
                Icon(TablerIcons.chevron_right,
                    size: 14, color: AppColors.accent),
              ],
            ),
          ),
        ),
        _buildAnimatedPodiumCard(),
      ],
    );
  }

  Widget _buildAnimatedPodiumCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/leaderboard');
        },
        splashColor: AppColors.accent.withValues(alpha: 0.06),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 18),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFDF7), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Layer 1: ambient gold radial halo at top
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 260,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.22),
                          AppColors.accent.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                )
                    .animate(
                        onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 1800.ms, curve: Curves.easeInOut)
                    .then()
                    .fadeOut(duration: 1800.ms, curve: Curves.easeInOut),
              ),

              // ── Layer 2: decorative sparkles
              _sparkle(top: 14, left: 28, size: 8, delay: 0),
              _sparkle(top: 30, right: 36, size: 6, delay: 400),
              _sparkle(top: 70, left: 14, size: 5, delay: 800),
              _sparkle(top: 8, right: 80, size: 10, delay: 1200),
              _sparkle(top: 56, right: 18, size: 7, delay: 1600),

              // ── Layer 3: the podium
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_leaderboard.length >= 2)
                        _buildMiniPodium(
                            _leaderboard[1], 2, AppColors.textMuted)
                      else
                        const SizedBox(width: 80),
                      if (_leaderboard.isNotEmpty)
                        _buildMiniPodium(
                            _leaderboard[0], 1, AppColors.accent)
                      else
                        const SizedBox(width: 80),
                      if (_leaderboard.length >= 3)
                        _buildMiniPodium(
                            _leaderboard[2], 3, AppColors.warning)
                      else
                        const SizedBox(width: 80),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Bottom CTA pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                      children: const [
                        Icon(TablerIcons.trophy,
                            size: 12, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text(
                          'VIEW FULL RANKINGS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(TablerIcons.chevron_right,
                            size: 12, color: AppColors.accent),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                          delay: 600.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic)
                      .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // SPARKLE — small decorative dot with looping pulse
  // ────────────────────────────────────────────────────────────
  Widget _sparkle({
    double? top,
    double? left,
    double? right,
    required double size,
    required int delay,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.55),
              AppColors.accent.withValues(alpha: 0.0),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(
              delay: delay.ms,
              duration: 1200.ms,
              curve: Curves.easeInOut)
          .scaleXY(
              begin: 0.6,
              end: 1.2,
              duration: 1200.ms,
              curve: Curves.easeInOut),
    );
  }

  // ────────────────────────────────────────────────────────────
  // MINI PODIUM — single podium tile with animations
  // ────────────────────────────────────────────────────────────
  Widget _buildMiniPodium(dynamic res, int rank, Color color) {
    final name = (res['full_name'] ?? 'Member').toString().split(' ').first;
    final count = res['sent_count'] ?? 0;
    final double size = rank == 1 ? 78 : 56;
    final String? profilePhoto = res['profile_photo'];

    String initials = '?';
    if (res['full_name'] != null) {
      final parts = res['full_name']
          .toString()
          .trim()
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        initials = parts[0][0].toUpperCase();
      } else if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      }
    }

    // Entrance stagger: rank 2 first (left), then rank 1 (center, slight delay),
    // then rank 3 (right). The center is the "drumroll" payoff.
    final entranceDelay =
        rank == 2 ? 0 : (rank == 1 ? 180 : 360);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating crown for rank 1 only
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Icon(TablerIcons.crown,
                color: AppColors.accent, size: 26),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -3,
                end: 3,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),

        // Avatar with halo
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Pulsing halo (rank 1 only — the spotlight)
            if (rank == 1)
              Container(
                width: size + 28,
                height: size + 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.28),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                      begin: 0.85,
                      end: 1.10,
                      duration: 1600.ms,
                      curve: Curves.easeInOut),
            // Outer gold ring (rank 1 uses full goldGradient)
            Container(
              padding: EdgeInsets.all(rank == 1 ? 3 : 2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: rank == 1
                    ? const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [color, color.withValues(alpha: 0.65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: rank == 1 ? 22 : 14,
                    spreadRadius: rank == 1 ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CachedAvatar(
                imageUrl: profilePhoto,
                initials: initials,
                size: size,
                backgroundColor: Colors.white,
                textColor: color,
                fontSize: rank == 1 ? 26 : 20,
              ),
            ),
            // Rank badge
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.32),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: rank == 1 ? 14 : 13,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: rank == 1
                ? const LinearGradient(colors: AppColors.goldGradient)
                : LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.20),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: rank == 1
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
            border: rank == 1
                ? null
                : Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TablerIcons.send,
                size: 10,
                color: rank == 1 ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text(
                '$count SENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: rank == 1 ? Colors.white : color,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
                delay: (entranceDelay + 280).ms,
                duration: 320.ms,
                curve: Curves.easeOutCubic)
            .scaleXY(
                begin: 0.7,
                end: 1,
                delay: (entranceDelay + 280).ms,
                duration: 320.ms,
                curve: Curves.easeOutCubic),
      ],
    );

    return body
        .animate()
        .fadeIn(
            delay: entranceDelay.ms,
            duration: 380.ms,
            curve: Curves.easeOutCubic)
        .slideY(
            begin: 0.25,
            end: 0,
            delay: entranceDelay.ms,
            duration: 380.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildClubsQuickLink() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/clubs'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBase.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left gold accent bar
              Positioned(
                left: 0,
                top: 22,
                bottom: 22,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        TablerIcons.layers_linked,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Horizontal Clubs',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Connect by industry across chapters',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        TablerIcons.chevron_right,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    int? deltaCount,
    String? deltaLabel,
    bool isPositive = true,
    double progress = 0,
    String? progressCaption,
  }) {
    final hasDelta = deltaCount != null || deltaLabel != null;
    final deltaText = deltaCount != null
        ? (deltaCount > 0 ? '+$deltaCount' : '$deltaCount')
        : (deltaLabel ?? '');
    final deltaPositive = deltaCount != null ? deltaCount >= 0 : isPositive;
    final deltaColor = deltaPositive ? AppColors.success : AppColors.error;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const Spacer(),
              if (hasDelta)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaPositive
                            ? TablerIcons.trending_up
                            : TablerIcons.trending_down,
                        size: 9,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        deltaText,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: deltaColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.6,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Real progress bar + caption (this month vs total / threshold)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 4,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
          ),
          if (progressCaption != null) ...[
            const SizedBox(height: 5),
            Text(
              progressCaption,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoiHeroCard() {
    final totalValue = _data?.roi.totalValue ?? 0;
    final thisMonthValue = _data?.roi.thisMonthValue ?? 0;
    final deltaPct = totalValue > 0
        ? ((thisMonthValue / totalValue) * 100).clamp(0, 999).toDouble()
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF0A0C1B).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Real ROI sparkline (fl_chart LineChart) — fed by _roiSeries
            Positioned(
              bottom: 18,
              right: 18,
              child: SizedBox(
                width: 140,
                height: 60,
                child: _buildRoiSparkline(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.goldGradient,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          TablerIcons.trending_up,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'TOTAL ROI GENERATED',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      // Period segment
                      _buildPeriodSegment(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: totalValue),
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(v),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.2,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              TablerIcons.calendar_month,
                              color: AppColors.accent,
                              size: 13,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _formatCurrency(thisMonthValue),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'this month',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (deltaPct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                TablerIcons.trending_up,
                                color: AppColors.success,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${deltaPct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildPeriodSegment() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['1M', '3M', '1Y'].map((label) {
          final active = label == _roiPeriod;
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: _loadingRoi || active ? null : () => _loadRoi(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: AppColors.goldGradient)
                      : null,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoiSparkline() {
    if (_loadingRoi) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.accent.withValues(alpha: 0.7)),
          ),
        ),
      );
    }
    if (_roiSeries.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );
    }
    // Compute min/max for auto-fit
    double minY = _roiSeries.first.y;
    double maxY = _roiSeries.first.y;
    for (final s in _roiSeries) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    if ((maxY - minY).abs() < 0.0001) {
      maxY = minY + 1; // avoid flat line edge case
    }
    final padding = (maxY - minY) * 0.12;
    minY -= padding;
    maxY += padding;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.32,
            color: AppColors.accent,
            barWidth: 2,
            isStrokeCapRound: true,
            spots: _roiSeries,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.accent,
                strokeWidth: 4,
                strokeColor: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.42),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  _NavItem(this.icon, this.label, this.index);
}

