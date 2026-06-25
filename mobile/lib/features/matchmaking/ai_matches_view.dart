import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/services/matchmaking_service.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/widgets/pbn_bottom_sheet.dart';
import 'package:pbn/features/matchmaking/business_matching_profile_page.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/models/matchmaking.dart';
import 'package:pbn/models/member.dart';

class AiMatchesView extends StatefulWidget {
  const AiMatchesView({super.key});

  @override
  State<AiMatchesView> createState() => _AiMatchesViewState();
}

class _AiMatchesViewState extends State<AiMatchesView> {
  final _service = MatchmakingService();
  List<MatchSuggestion> _matches = [];
  bool _loading = true;
  String? _error;

  // Own ScrollController — see referral_dashboard_page for the rationale.
  // Each tab in MatchmakingDashboardPage's TabBarView owns its own
  // scroll position so the desktop Scrollbar never sees two positions
  // bound to the same PrimaryScrollController during a tab swap.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() { _loading = true; _error = null; });
    try {
      final matches = await _service.getSuggestions();
      if (mounted) setState(() { _matches = matches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load matches'; _loading = false; });
    }
  }

  Future<void> _computeMatches() async {
    setState(() { _loading = true; });
    try {
      await _service.computeMatches();
      await _loadMatches();
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to recompute matches'; _loading = false; });
    }
  }

  // ──────────────────────────────────────────────────────────
  // STATUS HELPERS — viewed bookkeeping + optimistic dismiss
  // ──────────────────────────────────────────────────────────

  Future<void> _markViewed(String matchId) async {
    try {
      await _service.updateMatchStatus(matchId, 'viewed');
    } catch (_) {
      // Best-effort; silent failure.
    }
  }

  void _handleViewPartnership(MatchSuggestion match) {
    if (match.status.toLowerCase() == 'pending') {
      _markViewed(match.id);
    }
    _showMatchDetails(match);
  }

  Future<void> _handleDismiss(MatchSuggestion match) async {
    final removedIndex = _matches.indexOf(match);
    if (removedIndex == -1) return;
    setState(() => _matches.removeAt(removedIndex));

    try {
      await _service.updateMatchStatus(match.id, 'dismissed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dismissed.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _matches.insert(removedIndex, match));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't dismiss. Try again.")),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showSkeleton = _loading && _matches.isEmpty;
    final showError = !showSkeleton && _error != null && _matches.isEmpty;
    final showEmpty = !_loading && !showError && _matches.isEmpty;

    final sections = <Widget>[
      _buildHeroCard(),
      const SizedBox(height: 14),
      _buildStatStrip(),
      const SizedBox(height: 24),
      _buildSectionHeader(),
      const SizedBox(height: 12),
      _buildMatchesBody(
        showSkeleton: showSkeleton,
        showError: showError,
        showEmpty: showEmpty,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppColors.primary,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(sections.length, (i) {
          final delayMs = (i * 35).clamp(0, 280);
          return sections[i]
              .animate(delay: delayMs.ms)
              .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.10, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
        }),
      ),
    );
  }

  Widget _buildMatchesBody({
    required bool showSkeleton,
    required bool showError,
    required bool showEmpty,
  }) {
    if (showSkeleton) {
      return Column(
        children: List.generate(3, (_) => _buildSkeletonMatchCard()),
      );
    }
    if (showError) return _buildErrorState();
    if (showEmpty) return _buildEmptyState();
    return Column(
      children: _matches.map(_buildMatchCard).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO CARD (P-2) — navy gradient + gold ambient glow
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final isLoading = _loading && _matches.isEmpty;
    final isEmpty = !isLoading && _matches.isEmpty;

    final String headline;
    if (isLoading) {
      headline = 'Finding matches…';
    } else if (isEmpty) {
      headline = 'Set up your match profile';
    } else {
      final n = _matches.length;
      headline = n == 1
          ? '1 high-confidence match for you'
          : '$n high-confidence matches for you';
    }

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
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
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
                      AppColors.accentBlue.withValues(alpha: 0.10),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(TablerIcons.sparkles, color: AppColors.accent, size: 32),
                  const SizedBox(height: 14),
                  const Text(
                    'AI BUSINESS MATCHMAKING',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Based on industry, network gap, verification, and your stated needs.',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessMatchingProfilePage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(TablerIcons.user_cog, color: Colors.white, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'EDIT MATCH PROFILE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // ──────────────────────────────────────────────────────────
  // QUICK STATS STRIP (P-3)
  // ──────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    final newCount = _matches.where((m) => m.status.toLowerCase() == 'pending').length;
    final pursuedCount = _matches.where((m) => m.status.toLowerCase() == 'accepted').length;
    // createdAt not on MatchSuggestion — hardcoded em-dash until backend exposes it.
    const monthLabel = '—';

    Widget tile(IconData icon, Color color, String value, String label) {
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
                  border: Border.all(color: color.withValues(alpha: 0.22)),
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
                      style: const TextStyle(
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
        tile(TablerIcons.sparkles, AppColors.accent, '$newCount', 'NEW'),
        const SizedBox(width: 8),
        tile(TablerIcons.user_check, AppColors.success, '$pursuedCount', 'PURSUED'),
        const SizedBox(width: 8),
        tile(TablerIcons.calendar_month, AppColors.accentBlue, monthLabel, 'THIS MONTH'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1) + discreet refresh affordance
  // ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
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
        Text(
          'Top Recommendations',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _loading
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    _computeMatches();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TablerIcons.refresh,
                    size: 14,
                    color: _loading ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Refresh',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _loading ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // MATCH CARD (P-12)
  // ──────────────────────────────────────────────────────────
  Widget _buildMatchCard(MatchSuggestion match) {
    final percentage = (match.score * 100).round();
    final hasExplanation =
        match.explanation != null && match.explanation!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CachedAvatar(
                    imageUrl: match.matchedUserPhoto,
                    initials: (match.matchedUserName ?? '?')[0].toUpperCase(),
                    size: 50,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        match.matchedUserName ?? 'Unknown Member',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.matchedUserIndustry ?? 'Member',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Score badge — 56×56 navy circle, 2px gold ring
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$percentage%',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // TODO(matches/phase-2): four-dimensional score breakdown chips
            // (Industry / Chapter / Verification / Needs) go here. The model
            // exposes `match.scoreBreakdown` (Map<String,double>) but the chip
            // ordering, label canon, and threshold styling aren't yet specced.
            // Render four P-7 micro-chips when the design contract is finalized.

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.4),
              ),
            ),

            // Mini section header: ▌ Why this match
            Row(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.goldGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Why this match',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasExplanation
                  ? match.explanation!.trim()
                  : 'Strong fit across industry, chapter, and your stated needs.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Action row: View Partnership (gold) + Dismiss (text-only navy)
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _handleViewPartnership(match);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(TablerIcons.sparkles, color: Colors.white, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'VIEW PARTNERSHIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _handleDismiss(match);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Text(
                        'DISMISS',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SKELETON CARD (loading state)
  // ──────────────────────────────────────────────────────────
  Widget _buildSkeletonMatchCard() {
    return sk.Skeletonizer(
      enabled: true,
      effect: sk.ShimmerEffect(
        baseColor: AppColors.surfaceAlt,
        highlightColor: Colors.white.withValues(alpha: 0.9),
        duration: const Duration(milliseconds: 1400),
      ),
      child: _buildMatchCard(MatchSuggestion(
        id: 'skeleton',
        matchedUserId: 'placeholder',
        score: 0.85,
        scoreBreakdown: const {},
        explanation:
            'Lorem ipsum dolor sit amet consectetur adipisicing elit, sed do eiusmod tempor incididunt.',
        status: 'pending',
        matchedUserName: 'Placeholder Name',
        matchedUserIndustry: 'Tech & Software',
      )),
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE (P-10)
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            TablerIcons.brain,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 24),
          Text(
            'No matches yet',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap below and our AI will scan the network for members aligned with your business goals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                _computeMatches();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(TablerIcons.sparkles, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text(
                      'GENERATE MATCHES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ERROR STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            TablerIcons.alert_triangle,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 24),
          Text(
            "Couldn't load matches",
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Pull down to retry, or tap below to recompute.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                _loadMatches();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(TablerIcons.refresh, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text(
                      'RETRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // MATCH DETAIL SHEET launcher + preserved CONNECT flow
  // ──────────────────────────────────────────────────────────
  void _showMatchDetails(MatchSuggestion match) {
    showPbnBottomSheet(
      context,
      builder: (sheetCtx) => _MatchDetailSheet(
        match: match,
        service: _service,
        onConnect: () {
          Navigator.pop(sheetCtx);
          _handleConnect(match);
        },
      ),
    );
  }

  Future<void> _handleConnect(MatchSuggestion match) async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    
    if (memberProvider.members.isEmpty) {
      await memberProvider.fetchMembers();
    }
    
    final member = memberProvider.members
        .where((m) => m.userId == match.matchedUserId)
        .firstOrNull;

    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member details not found in directory.')),
        );
      }
      return;
    }
    if (!mounted) return;

    showPbnBottomSheet(
      context,
      builder: (_) => _ConnectContactSheet(member: member),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CONNECT CONTACT SHEET
// Same shape as members_page._showMemberDetailBottomSheet: navy hero
// with the matched member's identity, gold-bar section header,
// contact info card, then the three tinted action buttons (Call /
// WhatsApp / Email). Replaces the prior bespoke layout that used raw
// Colors.blue / .green / .red — off-palette and inconsistent with
// every other sheet in the app.
// ──────────────────────────────────────────────────────────────
class _ConnectContactSheet extends StatelessWidget {
  final Member member;
  const _ConnectContactSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    final hasPhone =
        member.phoneNumber != null && member.phoneNumber!.isNotEmpty;
    final hasEmail = member.email != null && member.email!.isNotEmpty;

    return PbnBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(member),
          const SizedBox(height: 18),
          _sectionLabel('Contact'),
          const SizedBox(height: 8),
          _infoCard([
            _infoRow(
              icon: TablerIcons.phone,
              tint: AppColors.accentBlue,
              label: 'PHONE',
              value: hasPhone ? member.phoneNumber! : 'Not shared',
            ),
            _hairline(),
            _infoRow(
              icon: TablerIcons.mail,
              tint: const Color(0xFF8B5CF6),
              label: 'EMAIL',
              value: hasEmail ? member.email! : 'Not shared',
            ),
          ]),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _action(
                  icon: TablerIcons.phone,
                  label: 'CALL',
                  tint: AppColors.accentBlue,
                  onTap: !hasPhone
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          launchUrl(
                              Uri.parse('tel:${member.phoneNumber}'));
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _action(
                  icon: TablerIcons.brand_whatsapp,
                  label: 'WHATSAPP',
                  tint: AppColors.success,
                  onTap: !hasPhone
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          final phone = member.phoneNumber!
                              .replaceAll(RegExp(r'\D'), '');
                          launchUrl(
                            Uri.parse('https://wa.me/$phone'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _action(
                  icon: TablerIcons.mail,
                  label: 'EMAIL',
                  tint: AppColors.accent,
                  onTap: !hasEmail
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          launchUrl(Uri.parse('mailto:${member.email}'));
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context); // Close sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReferralPage(initialMember: member),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.goldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.goldGlow,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.send, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SEND OPPORTUNITY',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(Member member) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 170,
                height: 170,
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppColors.goldGlow,
                    ),
                    child: CachedAvatar(
                      imageUrl: member.profilePhoto,
                      initials: member.initials,
                      size: 72,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.primary,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.fullName,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.company,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(children: children),
    );
  }

  Widget _hairline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.18),
                  tint.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tint.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.22),
                      tint.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppColors.textMuted.withValues(alpha: 0.10),
                      AppColors.textMuted.withValues(alpha: 0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? tint.withValues(alpha: 0.32)
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: enabled ? tint : AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? tint : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// MATCH DETAIL SHEET — strategy + Close / Connect bottom row
// ──────────────────────────────────────────────────────────
class _MatchDetailSheet extends StatefulWidget {
  final MatchSuggestion match;
  final MatchmakingService service;
  final VoidCallback onConnect;
  const _MatchDetailSheet({
    required this.match,
    required this.service,
    required this.onConnect,
  });

  @override
  State<_MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<_MatchDetailSheet> {
  // The backend returns these sentinels for failure cases (see
  // `get_partnership_strategy` in backend/.../matchmaking/service.py).
  // We must NOT cache them on the in-memory match — otherwise reopens would
  // surface the stale error forever instead of giving Gemini another chance.
  static const _errorSentinels = <String>[
    'The AI is busy right now',
    'Failed to generate AI strategy',
    'AI strategy generation is currently disabled',
    'No strategy could be generated',
    // Legacy sentinel kept for backwards compat with rows generated before
    // the message was reworded.
    'AI quota temporarily exceeded',
  ];

  String? _strategy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _strategy = widget.match.partnershipStrategy;
    // Only fetch if we don't already have a real strategy. If a prior tap
    // cached one on the in-memory match, this skips the round-trip entirely.
    if (_strategy == null) _loadStrategy();
  }

  bool _isErrorPayload(String s) {
    for (final prefix in _errorSentinels) {
      if (s.startsWith(prefix)) return true;
    }
    return false;
  }

  Future<void> _loadStrategy() async {
    setState(() {
      _loading = true;
    });
    try {
      final strategy = await widget.service.getAiStrategy(widget.match.id);
      if (!mounted) return;

      // Cache on the parent match object so a later reopen reuses it instead
      // of round-tripping to the backend. Skip caching for error payloads so
      // the user can retry.
      if (!_isErrorPayload(strategy)) {
        widget.match.partnershipStrategy = strategy;
      }

      setState(() {
        _strategy = strategy;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading AI strategy: $e');
      if (mounted) {
        setState(() {
          _strategy = 'Error loading strategy: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbnBottomSheet(
      maxHeightFraction: 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold-bar section header replaces the prior "Partnership
          // Strategy" + "HOW TO CREATE BUSINESS TOGETHER" double-title.
          // One header per section, palette-aligned.
          Row(
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
              Text(
                'Partnership Strategy',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            _StrategyMarkdown(
              text: _strategy ?? 'No strategy generated yet.',
            ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onConnect();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.goldGradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(TablerIcons.phone,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'CONNECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STRATEGY MARKDOWN
// Renders Gemini's partnership-strategy output: handles **bold** inline
// spans and numbered list items ("1. ", "2. "…) as styled rows with a
// gold-gradient number badge. Plain paragraphs render as flowing text.
// ──────────────────────────────────────────────────────────────
class _StrategyMarkdown extends StatelessWidget {
  final String text;
  const _StrategyMarkdown({required this.text});

  static final _listItemRegex = RegExp(r'^\s*(\d+)\.\s+(.*)$');
  static final _boldRegex = RegExp(r'\*\*(.+?)\*\*');

  List<TextSpan> _parseInline(String input, {required TextStyle base}) {
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final m in _boldRegex.allMatches(input)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, m.start), style: base));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.dmSans(
      fontSize: 14.5,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: -0.1,
    );

    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 8));
        }
        continue;
      }

      final m = _listItemRegex.firstMatch(trimmed);
      if (m != null) {
        final number = m.group(1)!;
        final body = m.group(2)!;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  number,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: RichText(
                    text: TextSpan(
                      children: _parseInline(body, base: baseStyle),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(
            text: TextSpan(
              children: _parseInline(trimmed, base: baseStyle),
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
