import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';
import 'package:pbn/models/referral.dart';

class ReferralDashboardPage extends StatefulWidget {
  final bool isEmbedded;
  const ReferralDashboardPage({super.key, this.isEmbedded = false});

  @override
  State<ReferralDashboardPage> createState() => _ReferralDashboardPageState();
}

class _ReferralDashboardPageState extends State<ReferralDashboardPage> {
  final _service = ReferralService();
  bool _loading = true;
  List<Referral> _received = [];
  List<Referral> _given = [];

  static const String _invitationText = '''Hi 👋, I'd like to introduce you to Prime Business Network (PBN) — a modern, technology-driven business growth ecosystem that helps entrepreneurs grow through structured, measurable results. It offers industry exclusivity (one member per category) and a digital system to track business opportunities and real business results.

Key Benefits:
• Exclusive industry seat (only one member per category)
• Consistent, high-quality business creation flow
• Digital tracking of business opportunities and ROI
• Increased visibility among trusted professionals
• Access to charter member benefits, events & training

By joining, you become part of a strong ecosystem built on reliable partnerships and accountable business creation, helping your business scale with purpose. Learn more and secure your spot here: https://primebusiness.network/''';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    List<Referral> received = [];
    List<Referral> given = [];

    try {
      received = await _service.getReceivedReferrals();
    } catch (e) {
      debugPrint('Error loading received referrals: $e');
    }

    try {
      given = await _service.getGivenReferrals();
    } catch (e) {
      debugPrint('Error loading given referrals: $e');
    }

    if (mounted) {
      setState(() {
        _received = received;
        _given = given;
        _loading = false;
      });
    }
  }

  // Combined pending: items in either direction that haven't reached a
  // terminal state. Answers "what's live across my entire pipeline".
  int get _pendingCount {
    bool isPending(Referral r) =>
        r.status != 'success' && r.status != 'closed_lost';
    return _received.where(isPending).length + _given.where(isPending).length;
  }

  int get _receivedCount => _received.length;
  int get _sentCount => _given.length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final sections = <Widget>[
      _buildHeroCard(),
      const SizedBox(height: 14),
      _buildStatStrip(),
      const SizedBox(height: 24),
      _sectionHeader('Business Activity'),
      _buildActivityCard(),
      const SizedBox(height: 24),
      _sectionHeader('Grow Your Network'),
      _buildInviteCard(),
      const SizedBox(height: 24),
      _sectionHeader('How It Works'),
      _buildInstructionCard(),
      const SizedBox(height: 24),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1) — copied verbatim from Profile
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
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
          Text(
            title,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO CARD (P-2) — primaryGradient + gold blob + honest ratio
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final total = _receivedCount + _sentCount;
    final ratioPill = _buildRatioPill(total);

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
                  const Icon(TablerIcons.briefcase,
                      color: AppColors.accent, size: 32),
                  const SizedBox(height: 14),
                  const Text(
                    'TOTAL BUSINESS ACTIVITY',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$total',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1.0,
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
                  // TODO: scope to current quarter once backend exposes
                  // createdAt filtering on referrals.
                  Text(
                    'given + received, all time',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (ratioPill == null)
                    _buildNewOpportunityCta()
                  else
                    Row(
                      children: [
                        Flexible(child: ratioPill),
                        const SizedBox(width: 12),
                        _buildNewOpportunityCta(),
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

  /// Honest ratio pill. Returns null when there's no activity yet, so the
  /// hero collapses to just [big "0" → sub-text → gold CTA] on the empty
  /// state (no muted "no activity" pill stacked above an already-present
  /// CTA — that was redundant).
  Widget? _buildRatioPill(int total) {
    if (total == 0) return null;

    final ratio = _sentCount / (_receivedCount == 0 ? 1 : _receivedCount);

    // Drop trailing ".0" on integer ratios so "6:1" reads cleaner than
    // "6.0:1". Non-integer ratios keep one decimal ("1.5:1").
    String stripDotZero(String s) =>
        s.endsWith('.0') ? s.substring(0, s.length - 2) : s;

    String fmt(double r) {
      if (r >= 1.0) {
        return '${stripDotZero(r.toStringAsFixed(1))}:1';
      } else {
        // r < 1.0 → invert as receivedCount / max(sentCount, 1) to avoid
        // 1/0 when the user has only received referrals and given none.
        final inv = _receivedCount / (_sentCount == 0 ? 1 : _sentCount);
        return '1:${stripDotZero(inv.toStringAsFixed(1))}';
      }
    }

    final String label;
    final Color tint;
    if (ratio >= 2.0) {
      label = 'High Giving Ratio · ${fmt(ratio)}';
      tint = AppColors.success;
    } else if (ratio >= 1.0) {
      label = 'Balanced · ${fmt(ratio)}';
      tint = AppColors.accentBlue;
    } else {
      label = 'Receiving More Than Giving · ${fmt(ratio)}';
      tint = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: tint,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOpportunityCta() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReferralPage()),
          ).then((_) => _loadStats());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Icon(TablerIcons.plus, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text(
                'NEW OPPORTUNITY',
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // QUICK STATS STRIP (P-3)
  // ──────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
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
        tile(TablerIcons.inbox, AppColors.success, '$_receivedCount', 'RECEIVED'),
        const SizedBox(width: 8),
        tile(TablerIcons.send, AppColors.accentBlue, '$_sentCount', 'GIVEN'),
        const SizedBox(width: 8),
        tile(TablerIcons.clock, AppColors.warning, '$_pendingCount', 'PENDING'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // ACTIVITY CARD (P-4) — Received + Given rows in one card
  // ──────────────────────────────────────────────────────────
  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _activityRow(
              icon: TablerIcons.inbox,
              iconColor: AppColors.success,
              title: 'Received Opportunities',
              subtitle: 'Track business growth',
              count: _receivedCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyReferralsPage(isReceived: true)),
              ).then((_) => _loadStats()),
            ),
            _hairlineDivider(),
            _activityRow(
              icon: TablerIcons.send,
              iconColor: AppColors.accentBlue,
              title: 'Given Opportunities',
              subtitle: 'Track business growth',
              count: _sentCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyReferralsPage(isReceived: false)),
              ).then((_) => _loadStats()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.18),
                      iconColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(TablerIcons.chevron_right,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hairlineDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.6),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INVITE CARD — retokenized
  // ──────────────────────────────────────────────────────────
  Widget _buildInviteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.accent.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(TablerIcons.user_plus,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'GROW YOUR NETWORK',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Invite Quality Professionals',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Copy our professional template to invite business owners in your network to join PBN.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(
                      const ClipboardData(text: _invitationText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Invitation copied to clipboard!',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(TablerIcons.copy,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'COPY INVITATION TEXT',
                        style: GoogleFonts.dmSans(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // HOW IT WORKS — retokenized
  // ──────────────────────────────────────────────────────────
  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.18),
                      AppColors.accentBlue.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.accentBlue.withValues(alpha: 0.22)),
                ),
                child: const Icon(TablerIcons.info_circle,
                    color: AppColors.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'How it works',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'High business creation flow helps you climb the leaderboard and unlock premium rewards. Always update the ROI once an opportunity is closed successfully.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
