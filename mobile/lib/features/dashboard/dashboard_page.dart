import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DashboardData? _data;
  PrivilegeCard? _card;
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
        if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load dashboard'; _loading = false; });
    }
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
          const Text('GLOBAL OVERVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(auth.user?.fullName ?? (isProspect ? 'Prospect' : 'Member'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
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
        _buildDrawerMenu(isProspect),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawerMenu(bool isProspect) {
    return PopupMenuButton<String>(
      icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: const Icon(TablerIcons.layout_grid, color: AppColors.primary, size: 20)),
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        if (!isProspect) ...[
          _menuItem('leaderboard', TablerIcons.trophy, 'Leaderboard'),
          _menuItem('rewards', TablerIcons.gift, 'Rewards Catalog'),
          _menuItem('payments', TablerIcons.credit_card, 'Billing'),
          _menuItem('chapters', TablerIcons.building_community, 'Chapters'),
          const PopupMenuDivider(),
        ],
        _menuItem('apply', TablerIcons.file_pencil, 'Application Form'),
        _menuItem('my-applications', TablerIcons.file_search, 'Application Tracker'),
      ],
      onSelected: (route) => Navigator.pushNamed(context, '/$route'),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(value: value, child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: AppColors.primary)), const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ]));
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
          const Text('PERFORMANCE ENGINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          const SizedBox(height: 16),
          const Text('PERFORMANCE OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          Column(children: [
            Row(children: [
              Expanded(child: SizedBox(height: 85, child: StatCard(title: 'Sent', value: '${_data?.referrals.sentTotal ?? 0}', icon: TablerIcons.arrow_up_right, gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 85, child: StatCard(title: 'Ratio', value: '${(_data?.referrals.conversionRate ?? 0).toStringAsFixed(0)}%', icon: TablerIcons.chart_pie, gradient: const [Color(0xFF10B981), Color(0xFF064E3B)]))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SizedBox(height: 85, child: StatCard(title: 'Valuation', value: _formatCurrency(_data?.roi.totalValue ?? 0), icon: TablerIcons.trending_up, gradient: const [Color(0xFFF59E0B), Color(0xFF92400E)]))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 85, child: StatCard(title: 'Incoming', value: '${_data?.referrals.receivedTotal ?? 0}', icon: TablerIcons.arrow_down_left, gradient: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)]))),
            ]),
          ]),
          const SizedBox(height: 32),
          const Text('EXPLORE NETWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            _modernActionTile(TablerIcons.stars, 'Awards', Colors.amber, () => Navigator.pushNamed(context, '/rewards')),
            const SizedBox(width: 16),
            _modernActionTile(TablerIcons.chart_arrows_vertical, 'Global Rank', Colors.blue, () => Navigator.pushNamed(context, '/leaderboard')),
            const SizedBox(width: 16),
            _modernActionTile(TablerIcons.help_circle, 'Support', Colors.pink, () {}),
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
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NETWORK GROWTH', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                const SizedBox(height: 8),
                const Text('Expand your business reach effortlessly.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black87)])),
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
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NEXT ONLINE SESSION', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(event?.title ?? 'Strategic Sync Performance', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
                const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CHAPTER MEETUP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Galle Face In-Person Chapter Meeting', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
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
            ? [ const BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'HOME'), const BottomNavigationBarItem(icon: Icon(TablerIcons.user), label: 'PROFILE') ]
            : [
                const BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'HOME'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.users), label: 'MEMBERS'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.arrows_exchange), label: 'REFERRALS'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.calendar_event), label: 'AGENDA'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.user), label: 'PROFILE'),
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

  Widget _buildEngineStat(String label, String value, IconData icon, Color color, {bool showGlow = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: showGlow ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)] : null,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double v) {
    if (v >= 1000000) return 'LKR ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'LKR ${(v / 1000).toStringAsFixed(0)}K';
    return 'LKR ${v.toStringAsFixed(0)}';
  }
}
