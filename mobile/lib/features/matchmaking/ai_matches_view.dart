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
import 'package:pbn/features/matchmaking/business_matching_profile_page.dart';
import 'package:pbn/models/matchmaking.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMatches();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _handleConnect(MatchSuggestion match) {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final member = memberProvider.members
        .where((m) => m.userId == match.matchedUserId)
        .firstOrNull;

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member details not found in directory.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(
              30, 30, 30, 30 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedAvatar(
                  imageUrl: member.profilePhoto,
                  initials: member.initials,
                  size: 80),
              const SizedBox(height: 16),
              Text(member.fullName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              Text(member.company,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 30),
              Row(
                children: [
                  _contactCircle(TablerIcons.phone, 'Call', Colors.blue, () {
                    if (member.phoneNumber != null) {
                      launchUrl(Uri.parse('tel:${member.phoneNumber}'));
                    }
                  }),
                  _contactCircle(
                      TablerIcons.brand_whatsapp, 'WhatsApp', Colors.green, () {
                    if (member.phoneNumber != null) {
                      final phone =
                          member.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                      launchUrl(Uri.parse('https://wa.me/$phone'),
                          mode: LaunchMode.externalApplication);
                    }
                  }),
                  _contactCircle(TablerIcons.mail, 'Email', Colors.red, () {
                    if (member.email != null) {
                      launchUrl(Uri.parse('mailto:${member.email}'));
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCircle(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ],
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
  String? _strategy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _strategy = widget.match.partnershipStrategy;
    if (_strategy == null) _loadStrategy();
  }

  Future<void> _loadStrategy() async {
    setState(() {
      _loading = true;
    });
    try {
      final strategy = await widget.service.getAiStrategy(widget.match.id);
      if (mounted) {
        setState(() {
          _strategy = strategy;
          _loading = false;
        });
      }
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(children: [
            Icon(TablerIcons.sparkles, color: AppColors.accent, size: 24),
            SizedBox(width: 12),
            Text('Partnership Strategy',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ]),
          const SizedBox(height: 24),
          Text('HOW TO CREATE BUSINESS TOGETHER:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    child: Text(
                      _strategy ?? 'No strategy generated yet.',
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          // Bottom button row: Close (text) + Connect (gold)
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
                        gradient:
                            const LinearGradient(colors: AppColors.goldGradient),
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
