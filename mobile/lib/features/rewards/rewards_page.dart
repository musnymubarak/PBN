import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/core/widgets/privilege_card_widget.dart';
import 'package:pbn/features/rewards/qr_redeem_screen.dart';
import 'package:pbn/models/reward.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final _service = RewardService();
  PrivilegeCard? _card;
  List<Partner> _partners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait(
          [_service.getMyCard(), _service.listPartners()]);
      _card = results[0] as PrivilegeCard?;
      _partners = results[1] as List<Partner>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ──────────────────────────────────────────────────────────
  // REDEMPTION FLOWS
  // ──────────────────────────────────────────────────────────
  Future<void> _handleRedeem(Offer offer, String partnerName) async {
    if (offer.isRedeemedByMe) return;
    HapticFeedback.selectionClick();

    if (offer.redemptionMethod == 'coupon') {
      await _showCouponRedeemDialog(offer, partnerName);
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrRedeemScreen(
          offerId: offer.id,
          offerTitle: offer.title,
          partnerName: partnerName,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showCouponRedeemDialog(Offer offer, String partnerName) async {
    setState(() => _loading = true);
    try {
      final coupon = await _service.generateCoupon(offer.id);
      if (!mounted) return;
      setState(() => _loading = false);

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              boxShadow: AppColors.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navy hero with gold accent
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 140,
                          height: 140,
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
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.goldGradient),
                              shape: BoxShape.circle,
                              boxShadow: AppColors.goldGlow,
                            ),
                            child: const Icon(TablerIcons.ticket,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            offer.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partnerName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: AppColors.accent,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR COUPON CODE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFDF7), Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: AppColors.shadowSm,
                        ),
                        child: Text(
                          coupon.code,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        offer.description ??
                            'Use this code at checkout to claim your reward.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _GoldCtaButton(
                        icon: TablerIcons.copy,
                        label: 'COPY & CLOSE',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: coupon.code));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate coupon: ${e.toString()}')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final totalPartners = _partners.length;
    final totalOffers =
        _partners.fold<int>(0, (sum, p) => sum + p.offers.length);
    final totalRedeemed = _partners.fold<int>(
      0,
      (sum, p) => sum + p.offers.where((o) => o.isRedeemedByMe).length,
    );

    final sections = <Widget>[
      if (_card != null) ...[
        _sectionHeader('Your Privilege Card'),
        PrivilegeCardWidget(card: _card!),
        const SizedBox(height: 18),
      ],
      _buildStatsStrip(totalPartners, totalOffers, totalRedeemed),
      const SizedBox(height: 22),
      _sectionHeader('Exclusive Partner Offers',
          trailing: totalOffers > 0 ? '$totalOffers AVAILABLE' : null),
      if (_partners.isEmpty)
        _buildEmptyState()
      else
        ..._partners.map(_buildPartnerCard),
      const SizedBox(height: 32),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: _loading,
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
              SliverAppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 60,
                floating: true,
                snap: true,
                title: Text(
                  'Privilege Rewards',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                actions: const [PbnAppBarActions()],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: List.generate(sections.length, (i) {
                    final delayMs = (i * 35).clamp(0, 280);
                    return sections[i]
                        .animate(delay: delayMs.ms)
                        .fadeIn(
                            duration: 320.ms, curve: Curves.easeOutCubic)
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
  // SECTION HEADER (gold bar + bold title — matches profile page)
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
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STATS STRIP
  // ──────────────────────────────────────────────────────────
  Widget _buildStatsStrip(int partners, int offers, int redeemed) {
    Widget chip(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                  border:
                      Border.all(color: color.withValues(alpha: 0.22)),
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
                      label.toUpperCase(),
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
        chip(TablerIcons.building_store, AppColors.accentBlue,
            '$partners', 'Partners'),
        const SizedBox(width: 8),
        chip(TablerIcons.gift, AppColors.accent, '$offers', 'Offers'),
        const SizedBox(width: 8),
        chip(TablerIcons.discount_check, AppColors.success,
            '$redeemed', 'Claimed'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(TablerIcons.gift_off,
                size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            'No Active Offers Yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Partner offers will appear here as soon as they go live. Check back soon.',
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
  // PARTNER CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildPartnerCard(Partner p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Partner header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                // Gold-ringed logo
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPartnerLogo(p),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.description != null &&
                          p.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          p.description!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${p.offers.length} OFFER${p.offers.length == 1 ? '' : 'S'}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Hairline divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          // ── Offers list
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                for (int i = 0; i < p.offers.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _buildOfferItem(p.offers[i], p.name),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerLogo(Partner p) {
    final hasLogo = p.logoUrl != null && p.logoUrl!.isNotEmpty;
    if (!hasLogo) {
      return const Icon(TablerIcons.building_store,
          color: AppColors.accent, size: 26);
    }
    final imageUrl = p.logoUrl!.startsWith('http')
        ? p.logoUrl!
        : '${ApiConfig.staticUrl}${p.logoUrl}';

    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: SvgPicture.network(
          imageUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (ctx, url) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
      ),
      errorWidget: (ctx, url, err) => const Icon(TablerIcons.building_store,
          color: AppColors.accent, size: 26),
    );
  }

  // ──────────────────────────────────────────────────────────
  // OFFER ITEM
  // ──────────────────────────────────────────────────────────
  Widget _buildOfferItem(Offer o, String partnerName) {
    final isRedeemed = o.isRedeemedByMe;
    final isQr = o.redemptionMethod == 'qr';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isRedeemed ? null : () => _handleRedeem(o, partnerName),
        splashColor: AppColors.accent.withValues(alpha: 0.06),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: isRedeemed
                ? AppColors.surfaceAlt.withValues(alpha: 0.5)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRedeemed
                  ? AppColors.border.withValues(alpha: 0.4)
                  : AppColors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              // Method icon (gold accent when active)
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRedeemed
                        ? [
                            AppColors.textMuted.withValues(alpha: 0.14),
                            AppColors.textMuted.withValues(alpha: 0.05),
                          ]
                        : [
                            AppColors.accent.withValues(alpha: 0.18),
                            AppColors.accent.withValues(alpha: 0.06),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isRedeemed
                        ? AppColors.textMuted.withValues(alpha: 0.18)
                        : AppColors.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  isQr ? TablerIcons.qrcode : TablerIcons.ticket,
                  size: 16,
                  color: isRedeemed
                      ? AppColors.textMuted
                      : AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              // Title + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      o.title,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isRedeemed
                            ? AppColors.textMuted
                            : AppColors.text,
                        letterSpacing: -0.2,
                        height: 1.2,
                        decoration: isRedeemed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (o.discountPercent > 0)
                          _miniChip(
                            label:
                                '${o.discountPercent.toStringAsFixed(0)}% OFF',
                            color: isRedeemed
                                ? AppColors.textMuted
                                : AppColors.accent,
                            filled: true,
                          ),
                        _miniChip(
                          label: isQr ? 'IN-STORE QR' : 'COUPON CODE',
                          color: isRedeemed
                              ? AppColors.textMuted
                              : AppColors.accentBlue,
                          filled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isRedeemed)
                _usedBadge()
              else
                _RedeemButton(
                  onTap: () => _handleRedeem(o, partnerName),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip({
    required String label,
    required Color color,
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: filled ? null : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _usedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.circle_check,
              size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            'USED',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// PREMIUM GOLD REDEEM BUTTON
// ──────────────────────────────────────────────────────────────
class _RedeemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RedeemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.goldGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
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
              Icon(TablerIcons.bolt, color: Colors.white, size: 12),
              SizedBox(width: 5),
              Text(
                'REDEEM',
                style: TextStyle(
                  color: Colors.white,
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

// ──────────────────────────────────────────────────────────────
// PREMIUM GOLD CTA (used in coupon dialog)
// ──────────────────────────────────────────────────────────────
class _GoldCtaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GoldCtaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.goldGlow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
