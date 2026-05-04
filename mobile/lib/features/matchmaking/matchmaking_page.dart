import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/features/matchmaking/ai_matches_view.dart';
import 'package:pbn/features/referrals/referral_dashboard_page.dart';

class MatchmakingDashboardPage extends StatefulWidget {
  const MatchmakingDashboardPage({super.key});

  @override
  State<MatchmakingDashboardPage> createState() => _MatchmakingDashboardPageState();
}

class _MatchmakingDashboardPageState extends State<MatchmakingDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OPPORTUNITIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: 'AI MATCHES', icon: Icon(TablerIcons.sparkles, size: 20)),
            Tab(text: 'REFERRALS', icon: Icon(TablerIcons.arrows_exchange, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AiMatchesView(),
          ReferralDashboardPage(isEmbedded: true),
        ],
      ),
    );
  }
}
