import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
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
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 60,
            floating: true,
            snap: true,
            title: const Text(
              'Opportunities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
            actions: const [PbnAppBarActions()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(73),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.text,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: AppColors.accent, width: 3),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        insets: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(WidgetState.pressed)) {
                            return AppColors.accent.withValues(alpha: 0.06);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return AppColors.accent.withValues(alpha: 0.04);
                          }
                          return null;
                        },
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(TablerIcons.sparkles, size: 18),
                          text: 'AI MATCHES',
                          iconMargin: EdgeInsets.only(bottom: 4),
                        ),
                        Tab(
                          icon: Icon(TablerIcons.arrows_exchange, size: 18),
                          text: 'REFERRALS',
                          iconMargin: EdgeInsets.only(bottom: 4),
                        ),
                      ],
                    ),
                    Container(height: 1, color: AppColors.borderLight),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            AiMatchesView(),
            ReferralDashboardPage(),
          ],
        ),
      ),
    );
  }
}
