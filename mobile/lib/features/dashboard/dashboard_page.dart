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

  final _dashboardService = DashboardService();
  final _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _loadData();
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
          const Text('OVERVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(auth.user?.fullName ?? (isProspect ? 'Prospect' : 'Member'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
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
          _buildPrivilegeCard(),
          const SizedBox(height: 32),
          const Text('PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: StatCard(title: 'Sent', value: '${_data?.referrals.sentTotal ?? 0}', icon: TablerIcons.arrow_up_right, color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: StatCard(title: 'Ratio', value: '${(_data?.referrals.conversionRate ?? 0).toStringAsFixed(0)}%', icon: TablerIcons.chart_pie, color: const Color(0xFF10B981))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: StatCard(title: 'Valuation', value: _formatCurrency(_data?.roi.totalValue ?? 0), icon: TablerIcons.trending_up, color: Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: StatCard(title: 'Incoming', value: '${_data?.referrals.receivedTotal ?? 0}', icon: TablerIcons.arrow_down_left, color: Colors.purple)),
          ]),
          const SizedBox(height: 32),
          const Text('UPCOMING PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (_data?.events.nextEvent != null) _buildNextEvent(),
          const SizedBox(height: 32),
          _buildQuickActionsTiles(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPrivilegeCard() {
    if (_card == null) return const SizedBox();
    return PrivilegeCardWidget(card: _card!);
  }

  Widget _buildNextEvent() {
    final event = _data!.events.nextEvent!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(TablerIcons.calendar_event, color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(event.startAt.split('T').first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ])),
        const Icon(TablerIcons.chevron_right, color: AppColors.textSecondary, size: 20),
      ]),
    );
  }

  Widget _buildQuickActionsTiles() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('EXPLORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
      const SizedBox(height: 20),
      Row(children: [
        _modernActionTile(TablerIcons.stars, 'Awards', Colors.amber, () => Navigator.pushNamed(context, '/rewards')),
        const SizedBox(width: 16),
        _modernActionTile(TablerIcons.chart_arrows_vertical, 'Rank', Colors.blue, () => Navigator.pushNamed(context, '/leaderboard')),
        const SizedBox(width: 16),
        _modernActionTile(TablerIcons.help_circle, 'Help', Colors.pink, () {}),
      ]),
    ]);
  }

  Widget _modernActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))]),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text)),
          ]),
        ),
      ),
    );
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
          Text('Apply to unlock the full potential of PBN. Verified members get access to exclusive leads, events, and rewards.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          CustomButton(text: 'SUBMIT APPLICATION', onPressed: () => Navigator.pushNamed(context, '/apply'), backgroundColor: AppColors.primary),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/my-applications'), child: const Text('Track Application Status', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13))),
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
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: isProspect
            ? [ const BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'HOME'), const BottomNavigationBarItem(icon: Icon(TablerIcons.user), label: 'PROFILE') ]
            : [
                const BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'HOME'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.users), label: 'NETWORK'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.arrows_exchange), label: 'REFERRALS'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.calendar_event), label: 'AGENDA'),
                const BottomNavigationBarItem(icon: Icon(TablerIcons.user), label: 'ME'),
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
