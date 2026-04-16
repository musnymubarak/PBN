import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/core/widgets/stat_card.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/models/dashboard_data.dart';
import 'package:pbn/models/reward.dart';
import 'package:pbn/core/widgets/privilege_card_widget.dart';
import 'package:pbn/features/members/members_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/referral_dashboard_page.dart';
import 'package:pbn/features/events/events_page.dart';
import 'package:pbn/features/profile/profile_page.dart';
import 'package:pbn/features/support/support_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DashboardData? _data;
  PrivilegeCard? _card;
  List<dynamic> _leaderboard = [];
  bool _loading = true;
  String? _error;

  // -- Sliding Ads Logic --
  final PageController _adController = PageController();
  int _adIndex = 0;
  Timer? _adTimer;

  final _dashboardService = DashboardService();
  final _rewardService = RewardService();

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
          _adController.animateToPage(_adIndex, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutQuart);
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _dashboardService.getDashboard(),
        _rewardService.getMyCard(),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as DashboardData;
          _card = results[1] as PrivilegeCard?;
          _loading = false;
        });
        _loadLeaderboard();
        if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load dashboard'; _loading = false; });
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final entries = await _dashboardService.getLeaderboard(period: 'all_time');
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
        ? [ _buildProspectDashboard(), const ProfilePage() ]
        : [ _buildDashboardBody(), const MembersPage(), const ReferralDashboardPage(), const EventsPage(), const ProfilePage() ];

    if (_currentIndex >= pages.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0 ? _buildAppBar(isProspect) : null,
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(isProspect),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isProspect) {
    final auth = context.watch<AuthProvider>();
    final notifs = context.watch<NotificationProvider>();
    return AppBar(
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INSIGHTS HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('Welcome, ${auth.user?.fullName.split(' ').first ?? 'Member'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(icon: const Icon(TablerIcons.bell, color: AppColors.text, size: 24), onPressed: () => Navigator.pushNamed(context, '/notifications')),
            if (notifs.unreadCount > 0)
              Positioned(right: 8, top: 10, child: Container(
                padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('${notifs.unreadCount}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w900)),
              )),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }



  Widget _buildDashboardBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          PrivilegeCardWidget(card: _card!),
          const SizedBox(height: 16),
          
          // -- TRANSITIONING AD PANEL (SLIDER) --
          SizedBox(
            height: 170,
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
          
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _adDot(0), const SizedBox(width: 8), _adDot(1), const SizedBox(width: 8), _adDot(2),
          ]),
          
          const SizedBox(height: 16),
          const Text('PERFORMANCE OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          Column(children: [
            Row(children: [
              Expanded(child: SizedBox(height: 95, child: StatCard(title: 'Sent', value: '${_data?.referrals.sentTotal ?? 0}', icon: TablerIcons.arrow_up_right, gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 95, child: StatCard(title: 'Ratio', value: '${(_data?.referrals.conversionRate ?? 0).toStringAsFixed(0)}%', icon: TablerIcons.chart_pie, gradient: const [Color(0xFF10B981), Color(0xFF064E3B)]))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SizedBox(height: 95, child: StatCard(title: 'ROI', value: _formatCurrency(_data?.roi.totalValue ?? 0), icon: TablerIcons.trending_up, gradient: const [Color(0xFFF59E0B), Color(0xFF92400E)]))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 95, child: StatCard(title: 'Incoming', value: '${_data?.referrals.receivedTotal ?? 0}', icon: TablerIcons.arrow_down_left, gradient: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)]))),
            ]),
          ]),
          const SizedBox(height: 32),
          _buildLeaderboardPreview(),
          
          const SizedBox(height: 32),
          const Text('EXPLORE NETWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            _modernActionTile(TablerIcons.stars, 'Rewards', Colors.amber, () => Navigator.pushNamed(context, '/rewards')),
            const SizedBox(width: 16),
            _modernActionTile(TablerIcons.building_community, 'Chapters', Colors.blue, () => Navigator.pushNamed(context, '/chapters')),
            const SizedBox(width: 16),
            _modernActionTile(TablerIcons.help_circle, 'Support', Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()))),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _adDot(int index) {
    bool active = _adIndex == index;
    return Container(width: active ? 22 : 8, height: 8, decoration: BoxDecoration(color: active ? AppColors.primary : Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)));
  }

  Widget _buildAdPromoPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          Positioned.fill(child: _smartImage('https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=600', const [Color(0xFF0F172A), Color(0xFF1E293B)])),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('NETWORK GROWTH', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                const SizedBox(height: 6),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Expand your business reach effortlessly.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black87)])),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReferralPage())),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  child: const Text('SUBMIT REFERRAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildEventZoomPanel() {
    final event = _data?.events.nextEvent;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          Positioned.fill(child: _smartImage('https://images.unsplash.com/photo-1588196749597-9ff075ee6b5b?auto=format&fit=crop&q=80&w=600', const [Color(0xFF6366F1), Color(0xFF4F46E5)])),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.95), const Color(0xFF6366F1).withOpacity(0.4)], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('NEXT ONLINE SESSION', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(event?.title ?? 'Strategic Sync Performance', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(TablerIcons.calendar_event, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(_formatDateTime(event?.startAt), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(TablerIcons.video, size: 14),
                  label: const Text('JOIN ZOOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPhysicalMeetingPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF97316),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFFF97316).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          Positioned.fill(child: _smartImage('https://picsum.photos/id/445/600/300', const [Color(0xFFF97316), Color(0xFFEA580C)])),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFF97316).withOpacity(0.95), const Color(0xFFF97316).withOpacity(0.4)], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('CHAPTER MEETUP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Galle Face In-Person Chapter Meeting', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(TablerIcons.map_pin, size: 14),
                  label: const Text('VIEW LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFF97316), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _smartImage(String url, List<Color> fallbackColors) {
    return Image.network(
      url, 
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null ? child : Container(decoration: BoxDecoration(gradient: LinearGradient(colors: fallbackColors))),
      errorBuilder: (context, error, stack) => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: fallbackColors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(child: Opacity(opacity: 0.1, child: Icon(TablerIcons.photo, size: 80, color: Colors.white))),
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return 'Wednesday | 10:00 AM';
    final parts = iso.split('T');
    if (parts.length < 2) return iso;
    return '${parts[0]}  |  ${parts[1].substring(0, 5)}';
  }

  Widget _buildErrorState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(TablerIcons.alert_triangle, size: 48, color: Colors.amber.shade300),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 24),
      SizedBox(width: 120, child: CustomButton(text: 'RETRY', onPressed: _loadData, backgroundColor: AppColors.primary)),
    ]));
  }

  Widget _buildProspectDashboard() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle), child: const Icon(TablerIcons.building_community, size: 64, color: AppColors.primary)),
          const SizedBox(height: 32),
          const Text('Verification Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 16),
          Text('Your application is being reviewed. Verified members unlock access to leads, events, and rewards.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          CustomButton(text: 'CONTACT SUPPORT', onPressed: () {}, backgroundColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isProspect) {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.4),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: isProspect
            ? [ const BottomNavigationBarItem(icon: Icon(TablerIcons.smart_home), label: 'Home'), const BottomNavigationBarItem(icon: Icon(TablerIcons.user_circle), label: 'Me') ]
            : [
                const BottomNavigationBarItem(icon: Icon(TablerIcons.smart_home), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.users), label: 'Members'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.briefcase), label: 'Deals'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.calendar_event), label: 'Schedule'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.user_circle), label: 'Me'),
              ],
      ),
    );
  }

  Widget _modernActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))]),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.text)),
          ]),
        ),
      ),
    );
  }


  String _formatCurrency(double v) {
    if (v >= 1000000) return 'LKR ${(v / 1000000).toStringAsFixed(1)}M';
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
                const Icon(TablerIcons.trophy, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 8),
                const Text('TOP CONNECTORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5)),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              child: const Text('VIEW ALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/leaderboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_leaderboard.length >= 2) _buildMiniPodium(_leaderboard[1], 2, const Color(0xFF94A3B8)), // Silver
                if (_leaderboard.length >= 1) _buildMiniPodium(_leaderboard[0], 1, const Color(0xFFF59E0B)), // Gold
                if (_leaderboard.length >= 3) _buildMiniPodium(_leaderboard[2], 3, const Color(0xFFB45309)), // Bronze
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
    final initials = (res['full_name'] ?? '?').toString().substring(0, 1).toUpperCase();
    
    final double size = rank == 1 ? 74 : 54;
    
    String? profilePhoto = res['profile_photo'];
    String imageUrl = profilePhoto != null && profilePhoto.isNotEmpty
        ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$profilePhoto'
        : 'https://picsum.photos/seed/${Uri.encodeComponent(name)}/150/150';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1) 
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Icon(TablerIcons.crown, color: Color(0xFFF59E0B), size: 24),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // GLOE EFFECT FOR RANK 1
            if (rank == 1)
              Container(
                width: size + 16, height: size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
              ),
            Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.8), width: rank == 1 ? 3 : 2),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: const Color(0xFF1E293B), width: 2)
                ),
                child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count Sent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }
}
