import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/core/widgets/stat_card.dart';
import 'package:pbn/models/dashboard_data.dart';
import 'package:pbn/models/reward.dart';
import 'package:pbn/features/members/members_page.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
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
        // Update notification badge
        if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load dashboard'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardBody(),
      const MembersPage(),
      const CreateReferralPage(),
      const EventsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final auth = context.watch<AuthProvider>();
    final notifs = context.watch<NotificationProvider>();
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back,', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          Text(auth.user?.fullName ?? 'Member', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(icon: const Icon(TablerIcons.bell, color: AppColors.text), onPressed: () => Navigator.pushNamed(context, '/notifications')),
            if (notifs.unreadCount > 0)
              Positioned(right: 8, top: 8, child: Container(
                padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('${notifs.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
              )),
          ],
        ),
        _buildDrawerMenu(),
      ],
    );
  }

  Widget _buildDrawerMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(TablerIcons.menu_2, color: AppColors.text),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        _menuItem('my-referrals', TablerIcons.arrows_exchange, 'My Referrals'),
        _menuItem('leaderboard', TablerIcons.trophy, 'Leaderboard'),
        _menuItem('rewards', TablerIcons.gift, 'Rewards'),
        _menuItem('payments', TablerIcons.credit_card, 'Payments'),
        _menuItem('chapters', TablerIcons.building, 'Chapters'),
        const PopupMenuDivider(),
        _menuItem('apply', TablerIcons.file_plus, 'Apply Now'),
        _menuItem('my-applications', TablerIcons.file_check, 'My Applications'),
      ],
      onSelected: (route) => Navigator.pushNamed(context, '/$route'),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(value: value, child: Row(children: [
      Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _buildDashboardBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(TablerIcons.wifi_off, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Stats Grid ──────────────────────────
          Row(children: [
            Expanded(child: StatCard(title: 'Referrals Sent', value: '${_data?.referrals.sentTotal ?? 0}', icon: TablerIcons.send, gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)])),
            const SizedBox(width: 14),
            Expanded(child: StatCard(title: 'Conversion', value: '${(_data?.referrals.conversionRate ?? 0).toStringAsFixed(0)}%', icon: TablerIcons.chart_bar, gradient: const [Color(0xFF10B981), Color(0xFF059669)])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: StatCard(title: 'Total ROI', value: _formatCurrency(_data?.roi.totalValue ?? 0), icon: TablerIcons.trending_up, gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)])),
            const SizedBox(width: 14),
            Expanded(child: StatCard(title: 'Received', value: '${_data?.referrals.receivedTotal ?? 0}', icon: TablerIcons.inbox, gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)])),
          ]),
          const SizedBox(height: 28),

          // ── Privilege Card ────────────────────────
          if (_card != null) ...[
            _buildPrivilegeCard(),
            const SizedBox(height: 28),
          ],

          // ── Next Event ────────────────────────────
          if (_data?.events.nextEvent != null) ...[
            _buildNextEvent(),
            const SizedBox(height: 28),
          ],

          // ── Quick Actions ─────────────────────────
          _buildQuickActions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPrivilegeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('PRIVILEGE CARD', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
            child: Text(_card!.tier.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 20),
        Text(_card!.cardNumber, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_card!.points} Points', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const Text('PRIME BUSINESS NETWORK', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
      ]),
    );
  }

  Widget _buildNextEvent() {
    final event = _data!.events.nextEvent!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(TablerIcons.calendar_event, color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NEXT EVENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
        ])),
        const Icon(TablerIcons.chevron_right, color: AppColors.textSecondary),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 14),
      Row(children: [
        _actionTile(TablerIcons.send, 'New Referral', () => setState(() => _currentIndex = 2)),
        const SizedBox(width: 12),
        _actionTile(TablerIcons.trophy, 'Leaderboard', () => Navigator.pushNamed(context, '/leaderboard')),
        const SizedBox(width: 12),
        _actionTile(TablerIcons.gift, 'Rewards', () => Navigator.pushNamed(context, '/rewards')),
      ]),
    ]);
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
          child: Column(children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        items: const [
          BottomNavigationBarItem(icon: Icon(TablerIcons.layout_dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.users), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.send), label: 'Referral'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.calendar_event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(TablerIcons.user), label: 'Profile'),
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
