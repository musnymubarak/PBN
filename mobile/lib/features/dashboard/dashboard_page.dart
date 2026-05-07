import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
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
                    AppColors.accentBlue.withOpacity(0.08),
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
                    AppColors.accent.withOpacity(0.05),
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

  Widget _buildSliverAppBar(bool isProspect) {
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.fullName.split(' ').first ?? 'Member';
    
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      floating: true,
      snap: true,
      titleSpacing: 20,
      title: Text(
        'Welcome, $firstName',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
      actions: const [PbnAppBarActions()],
    );
  }

  Widget _buildDashboardBody() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _shimmerRect(height: 200, radius: 24),
            const SizedBox(height: 16),
            _shimmerRect(height: 84, radius: 20),
            const SizedBox(height: 26),
            _shimmerRect(height: 24, width: 150, radius: 4),
            const SizedBox(height: 14),
            _shimmerRect(height: 180, radius: 28),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _shimmerRect(height: 120, radius: 20)),
                const SizedBox(width: 10),
                Expanded(child: _shimmerRect(height: 120, radius: 20)),
                const SizedBox(width: 10),
                Expanded(child: _shimmerRect(height: 120, radius: 20)),
              ],
            ),
          ],
        ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Overview',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
          Text(
            'Explore Network',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.3,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.border,
        borderRadius: BorderRadius.circular(10),
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
            color: AppColors.primary.withOpacity(0.12),
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
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.1),
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
                      AppColors.accent.withOpacity(0.2),
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
    final event = _data?.events.nextVirtual;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.12),
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
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.12),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open meeting link')));
      }
    } catch (_) {
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
          colors: [color, color.withOpacity(0.8)],
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
            child: Icon(TablerIcons.calendar_star, size: 120, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TablerIcons.calendar_event, size: 40, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
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
    final event = _data?.events.nextPhysical;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
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
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.12),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    } catch (_) {
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
          border: Border.all(color: AppColors.error.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.alert_triangle, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
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

  Widget _shimmerRect({required double height, double? width, double radius = 0}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
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
                      color: AppColors.accent.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
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
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBase.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: navItems.map((item) {
            bool isActive = _currentIndex == item.index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = item.index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? AppColors.accent : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? AppColors.accent : AppColors.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBase.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom accent bar
              Positioned(
                bottom: -20,
                child: Container(
                  width: 32,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      letterSpacing: 0.2,
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
            Text(
              'Top Performers',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              child: Row(
                children: [
                  const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(TablerIcons.chevron_right, size: 14, color: AppColors.accent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/leaderboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFDF7), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
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
                      width: 220,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.15),
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
    final double size = rank == 1 ? 80 : 58;
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
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(TablerIcons.crown, color: AppColors.accent, size: 26),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (rank == 1)
              Container(
                width: size + 20,
                height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
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
                  colors: [color, color.withOpacity(0.6)],
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
                fontSize: rank == 1 ? 26 : 20,
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
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
        const SizedBox(height: 16),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Sent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBase.withOpacity(0.04),
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
                        color: AppColors.accent.withOpacity(0.1),
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
                            style: GoogleFonts.outfit(
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBase.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 15),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(TablerIcons.trending_up, color: AppColors.success.withOpacity(0.5), size: 12),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            height: 3.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.7), accentColor.withOpacity(0.1)],
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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B0F1F), Color(0xFF162033)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.20),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF0A0C1B).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Ambient gold glows
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Mini bar visualizer
            Positioned(
              bottom: 24,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _heroBar(14, 0.15),
                  _heroBar(24, 0.25),
                  _heroBar(18, 0.2),
                  _heroBar(34, 0.4),
                  _heroBar(28, 0.3),
                  _heroBar(44, 0.6),
                  _heroBar(38, 0.45),
                  _heroBar(52, 0.8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          TablerIcons.trending_up,
                          color: AppColors.accent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'TOTAL ROI GENERATED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(totalValue),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.30),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TablerIcons.calendar_month,
                          color: AppColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This month',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatCurrency(thisMonthValue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  _NavItem(this.icon, this.label, this.index);
}
