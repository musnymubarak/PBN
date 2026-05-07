import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/models/dashboard_data.dart';

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

  final _dashboardService = DashboardService();

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
      backgroundColor: const Color(0xFFF7F8FA),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(isProspect),
    );
  }

  Widget _buildSliverAppBar(bool isProspect) {
    final auth = context.watch<AuthProvider>();
    context.watch<NotificationProvider>();
    final firstName = auth.user?.fullName.split(' ').first ?? 'Member';
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      floating: true,
      snap: true,
      title: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Welcome, ',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: -0.3,
              ),
            ),
            TextSpan(
              text: firstName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      actions: const [PbnAppBarActions()],
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFEEF1F5), width: 1),
      ),
    );
  }

  Widget _buildDashboardBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(false), // Pass isProspect if needed, or handle inside
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList.list(
              children: [
          // -- TRANSITIONING AD PANEL (SLIDER) --
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

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _adDot(0),
              const SizedBox(width: 8),
              _adDot(1),
              const SizedBox(width: 8),
              _adDot(2),
            ],
          ),

          const SizedBox(height: 18),
          _buildClubsQuickLink(),
          const SizedBox(height: 26),
          const Text(
            'PERFORMANCE OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          _buildRoiHeroCard(),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatTile(
                    title: 'Business Sent',
                    value: '${_data?.referrals.sentTotal ?? 0}',
                    icon: TablerIcons.arrow_up_right,
                    accentColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    title: 'Ratio',
                    value:
                        '${(_data?.referrals.conversionRate ?? 0).toStringAsFixed(0)}%',
                    icon: TablerIcons.chart_pie,
                    accentColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    title: 'Incoming',
                    value: '${_data?.referrals.receivedTotal ?? 0}',
                    icon: TablerIcons.arrow_down_left,
                    accentColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildLeaderboardPreview(),

          const SizedBox(height: 30),
          const Text(
            'EXPLORE NETWORK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _modernActionTile(
                TablerIcons.stars,
                'Rewards',
                AppColors.accent,
                () => Navigator.pushNamed(context, '/rewards'),
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
              ],
            ),
          ),
        ],
      ),
    );
}

  Widget _adDot(int index) {
    bool active = _adIndex == index;
    return Container(
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildAdPromoPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: _smartImage(
                'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=600',
                const [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NETWORK GROWTH',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Expand your business reach effortlessly.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black87),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateReferralPage(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'SUBMIT OPPORTUNITY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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
    final event = _data?.events.nextVirtual;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: _smartImage(
                event?.imageUrl != null
                    ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${event!.imageUrl}'
                    : 'https://images.unsplash.com/photo-1588196749597-9ff075ee6b5b?auto=format&fit=crop&q=80&w=600',
                const [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NEXT ONLINE SESSION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            event?.title ?? 'Stay tuned for further updates',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black45),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (event != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  TablerIcons.calendar_event,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(event.startAt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (event != null) const Spacer(),
                        if (event != null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (event.meetingLink != null &&
                                  event.meetingLink!.isNotEmpty) {
                                final url = Uri.parse(event.meetingLink!);
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open meeting link',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid meeting link'),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Meeting link not available',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(TablerIcons.video, size: 14),
                            label: const Text(
                              'JOIN ZOOM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildPhysicalMeetingPanel() {
    final event = _data?.events.nextPhysical;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: _smartImage(
                event?.imageUrl != null
                    ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${event!.imageUrl}'
                    : 'https://picsum.photos/id/445/600/300',
                const [AppColors.secondary, Color(0xFFEA580C)],
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'CHAPTER MEETUP',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            event?.title ?? 'Stay tuned for further updates',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black45),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (event != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  TablerIcons.calendar_event,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(event.startAt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (event != null) const Spacer(),
                        if (event != null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (event.location != null &&
                                  event.location!.isNotEmpty) {
                                final encodedLocation = Uri.encodeComponent(
                                  event.location!,
                                );
                                final url = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$encodedLocation',
                                );
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open maps'),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error opening maps'),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Location not available'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(TablerIcons.map_pin, size: 14),
                            label: const Text(
                              'VIEW LOCATION',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.alert_triangle,
            size: 48,
            color: Colors.amber.shade300,
          ),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          SizedBox(
            width: 120,
            child: CustomButton(
              text: 'RETRY',
              onPressed: _loadData,
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProspectDashboard() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.building_community,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Verification Pending',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your application is being reviewed. Verified members unlock access to leads, events, and rewards.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'CONTACT SUPPORT',
            onPressed: () {},
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isProspect) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF1F5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A0C1B).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 9,
          unselectedFontSize: 9,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: isProspect
              ? [
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.smart_home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.user_circle),
                    label: 'Me',
                  ),
                ]
              : [
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.smart_home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.users),
                    label: 'Members',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.shopping_cart),
                    label: 'Market',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.briefcase),
                    label: 'Matches',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(TablerIcons.user_circle),
                    label: 'Me',
                  ),
                ],
        ),
      ),
    );
  }

  Widget _modernActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEF1F5), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A0C1B).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.20),
                      color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  TablerIcons.trophy,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'TOP OPPORTUNITY GENERATORS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/leaderboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 26),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBF1), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_leaderboard.length >= 2)
                      _buildMiniPodium(
                        _leaderboard[1],
                        2,
                        const Color(0xFF94A3B8),
                      ),
                    if (_leaderboard.isNotEmpty)
                      _buildMiniPodium(_leaderboard[0], 1, AppColors.accent),
                    if (_leaderboard.length >= 3)
                      _buildMiniPodium(
                        _leaderboard[2],
                        3,
                        const Color(0xFFB45309),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPodium(dynamic res, int rank, Color color) {
    final name = (res['full_name'] ?? 'Member').toString().split(' ').first;
    final count = res['sent_count'] ?? 0;
    final double size = rank == 1 ? 74 : 54;
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Icon(TablerIcons.crown, color: AppColors.accent, size: 22),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (rank == 1)
              Container(
                width: size + 18,
                height: size + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.40),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CachedAvatar(
                imageUrl: profilePhoto,
                initials: initials,
                size: size,
                backgroundColor: Colors.white,
                textColor: color,
                fontSize: rank == 1 ? 24 : 18,
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Sent',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubsQuickLink() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/clubs'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A0C1B).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.22),
                    AppColors.accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                TablerIcons.layers_linked,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horizontal Clubs',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Connect by industry across chapters',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TablerIcons.chevron_right,
                color: AppColors.accent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A0C1B).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.20),
                  accentColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accentColor, size: 13),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.6,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.7),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoiHeroCard() {
    final totalValue = _data?.roi.totalValue ?? 0;
    final thisMonthValue = _data?.roi.thisMonthValue ?? 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0C1B), Color(0xFF1A1F3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF0A0C1B).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.32),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.14),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              right: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _heroBar(12, 0.18),
                  _heroBar(20, 0.28),
                  _heroBar(16, 0.22),
                  _heroBar(30, 0.45),
                  _heroBar(24, 0.36),
                  _heroBar(38, 0.62),
                  _heroBar(32, 0.50),
                  _heroBar(46, 0.85),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.32),
                              AppColors.accent.withValues(alpha: 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.40),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          TablerIcons.trending_up,
                          color: AppColors.accent,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'TOTAL ROI GENERATED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(totalValue),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.4,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TablerIcons.calendar_month,
                          color: AppColors.accent,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'This month',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.70),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(thisMonthValue),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
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

  Widget _heroBar(double height, double opacity) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Container(
        width: 4,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
