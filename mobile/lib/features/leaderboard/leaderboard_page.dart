import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const _periods = <_Period>[
    _Period('Month', 'this_month'),
    _Period('Quarter', 'this_quarter'),
    _Period('Year', 'this_year'),
    _Period('All Time', 'all_time'),
  ];

  final _service = DashboardService();
  List<dynamic> _entries = [];
  bool _loading = true;
  String _period = 'this_month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_entries.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final auth = context.read<AuthProvider>();
      final newEntries = await _service.getLeaderboard(
        chapterId: auth.user?.chapterId,
        period: _period,
      );
      if (mounted) {
        setState(() {
          _entries = newEntries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUserId = auth.user?.id;

    final top1 = _entries.isNotEmpty ? _entries[0] : null;
    final top2 = _entries.length >= 2 ? _entries[1] : null;
    final top3 = _entries.length >= 3 ? _entries[2] : null;
    final rest = _entries.length > 3 ? _entries.sublist(3) : <dynamic>[];

    final myRank = myUserId == null
        ? null
        : _entries.indexWhere((e) => e['user_id'] == myUserId);
    final myEntry = (myRank != null && myRank >= 0) ? _entries[myRank] : null;

    final sections = <Widget>[
      _buildHero(),
      const SizedBox(height: 18),
      _buildPeriodSelector(),
      const SizedBox(height: 20),
      if (_entries.isEmpty)
        _buildEmptyState()
      else ...[
        _sectionHeader('Top 3', trailing: 'PODIUM'),
        _buildPodium(top1: top1, top2: top2, top3: top3, myUserId: myUserId),
        const SizedBox(height: 22),
        if (myEntry != null && myRank! >= 3) ...[
          _sectionHeader('Your Position'),
          _buildEntryCard(myRank + 1, myEntry, isYou: true),
          const SizedBox(height: 22),
        ],
        if (rest.isNotEmpty) ...[
          _sectionHeader('Full Rankings', trailing: '${rest.length}'),
          for (int i = 0; i < rest.length; i++)
            _buildEntryCard(
              i + 4,
              rest[i],
              isYou: rest[i]['user_id'] != null &&
                  rest[i]['user_id'] == myUserId,
            ),
        ],
      ],
      const SizedBox(height: 100),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: _loading && _entries.isEmpty,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: List.generate(sections.length, (i) {
                    final delayMs = (i * 35).clamp(0, 280);
                    return sections[i]
                        .animate(delay: delayMs.ms)
                        .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                        .slideY(
                            begin: 0.10,
                            end: 0,
                            duration: 320.ms,
                            curve: Curves.easeOutCubic);
                  }),
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
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      floating: true,
      snap: true,
      title: Text(
        'Leaderboard',
        style: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
          letterSpacing: -0.5,
        ),
      ),
      actions: const [PbnAppBarActions()],
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.accent.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.28)),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO (P-2)
  // ──────────────────────────────────────────────────────────
  Widget _buildHero() {
    final totalReferrals = _entries.fold<int>(
        0, (sum, e) => sum + ((e['sent_count'] as int?) ?? 0));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
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
                      AppColors.accent.withValues(alpha: 0.24),
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
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppColors.goldGlow,
                        ),
                        child: const Icon(TablerIcons.trophy,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TOP REFERRERS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _heroHeadline(),
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Celebrating members who connect the network.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _heroChip(
                        icon: TablerIcons.users_group,
                        label: '${_entries.length} MEMBERS',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _heroChip(
                        icon: TablerIcons.send,
                        label: '$totalReferrals REFERRALS',
                        color: AppColors.accent,
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

  String _heroHeadline() {
    switch (_period) {
      case 'this_month':
        return "This Month's Champions";
      case 'this_quarter':
        return "This Quarter's Leaders";
      case 'this_year':
        return "This Year's Top Performers";
      case 'all_time':
        return 'All-Time Legends';
      default:
        return 'Top Referrers';
    }
  }

  Widget _heroChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // PERIOD SELECTOR (gold underline)
  // ──────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: _periods.map((p) {
          final isSelected = _period == p.value;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _period = p.value);
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    children: [
                      Text(
                        p.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isSelected
                              ? AppColors.text
                              : AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 2,
                        width: isSelected ? 32 : 0,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(1),
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // PODIUM
  // ──────────────────────────────────────────────────────────
  Widget _buildPodium({
    dynamic top1,
    dynamic top2,
    dynamic top3,
    String? myUserId,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 26, 12, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top2 != null)
            Expanded(
              child: _podiumAvatar(
                user: top2,
                rank: 2,
                color: AppColors.textMuted,
                isYou: top2['user_id'] == myUserId,
              ),
            )
          else
            const Expanded(child: SizedBox()),
          if (top1 != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: _podiumAvatar(
                  user: top1,
                  rank: 1,
                  color: AppColors.accent,
                  isYou: top1['user_id'] == myUserId,
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          if (top3 != null)
            Expanded(
              child: _podiumAvatar(
                user: top3,
                rank: 3,
                color: AppColors.warning,
                isYou: top3['user_id'] == myUserId,
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _podiumAvatar({
    required dynamic user,
    required int rank,
    required Color color,
    required bool isYou,
  }) {
    final fullName = (user['full_name'] ?? 'Unknown').toString();
    final firstName = fullName.split(' ').first;
    final count = user['sent_count'] ?? 0;
    final initials = _getInitials(fullName);
    final photo = user['profile_photo'] as String?;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final imageUrl = hasPhoto
        ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$photo'
        : '';

    final avatarSize = rank == 1 ? 80.0 : 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (rank == 1)
          Column(
            children: [
              const Icon(TablerIcons.crown,
                  color: AppColors.accent, size: 28),
              const SizedBox(height: 6),
            ],
          ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
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
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: color,
                                fontSize: rank == 1 ? 26 : 19,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: color,
                              fontSize: rank == 1 ? 26 : 19,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: rank == 1 ? 14 : 13,
            color: AppColors.text,
            letterSpacing: -0.2,
          ),
        ),
        if (isYou) ...[
          const SizedBox(height: 4),
          _youPill(small: true),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(TablerIcons.send, size: 10, color: color),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // ENTRY CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildEntryCard(int rank, dynamic entry, {bool isYou = false}) {
    final name = (entry['full_name'] ?? 'Unknown').toString();
    final count = entry['sent_count'] ?? 0;
    final initials = _getInitials(name);
    final photo = entry['profile_photo'] as String?;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final imageUrl = hasPhoto
        ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$photo'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isYou
              ? AppColors.accent.withValues(alpha: 0.55)
              : AppColors.border.withValues(alpha: 0.7),
          width: isYou ? 1.4 : 1,
        ),
        boxShadow: isYou ? AppColors.goldGlow : AppColors.shadowSm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isYou ? AppColors.accent : AppColors.textMuted,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isYou
                  ? const LinearGradient(
                      colors: AppColors.goldGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: 6),
                  _youPill(),
                ],
              ],
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(TablerIcons.send, color: AppColors.textMuted, size: 13),
        ],
      ),
    );
  }

  Widget _youPill({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 7, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(5),
        boxShadow: AppColors.goldGlow,
      ),
      child: Text(
        'YOU',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE (P-10)
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
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
            child: const Icon(TablerIcons.trophy,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            'No referrals yet',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send your first referral to start climbing the leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _Period {
  final String label;
  final String value;
  const _Period(this.label, this.value);
}
