import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/models/marketplace.dart';

class ListingDetailPage extends StatefulWidget {
  final MarketplaceListing listing;
  const ListingDetailPage({super.key, required this.listing});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final _service = MarketplaceService();
  final _pageCtrl = PageController();
  bool _submittingInterest = false;
  int _activeImage = 0;
  late MarketplaceListing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────────────────
  Future<void> _expressInterest() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id == _listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot express interest in your own listing.')),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _submittingInterest = true);
    try {
      await _service.expressInterest(_listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Interest recorded. The seller has been notified.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to record interest. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingInterest = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    if (_listing.whatsappNumber == null) return;
    HapticFeedback.selectionClick();
    final url =
        'https://wa.me/${_listing.whatsappNumber!.replaceAll('+', '')}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone() async {
    if (_listing.contactPhone == null) return;
    HapticFeedback.selectionClick();
    final url = 'tel:${_listing.contactPhone}';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  Future<void> _launchEmail() async {
    if (_listing.contactEmail == null) return;
    HapticFeedback.selectionClick();
    final url = 'mailto:${_listing.contactEmail}';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    final hasMemberPrice = _listing.memberPrice != null;
    final hasRegular = _listing.regularPrice != null;
    final savings = (hasRegular && hasMemberPrice &&
            _listing.regularPrice! > _listing.memberPrice!)
        ? ((_listing.regularPrice! - _listing.memberPrice!) /
                _listing.regularPrice! *
                100)
            .round()
        : 0;

    final hasContact = _listing.whatsappNumber != null ||
        _listing.contactPhone != null ||
        _listing.contactEmail != null;

    final isOwnListing = Provider.of<AuthProvider>(context, listen: false)
            .user
            ?.id ==
        _listing.sellerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildImageHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleBlock(),
                  const SizedBox(height: 18),
                  _buildPriceCard(
                      currencyFormat, hasMemberPrice, hasRegular, savings),
                  const SizedBox(height: 22),
                  _sectionHeader('Seller'),
                  _buildSellerCard(),
                  const SizedBox(height: 22),
                  _sectionHeader('Description'),
                  _buildDescriptionCard(),
                  if (hasContact) ...[
                    const SizedBox(height: 22),
                    _sectionHeader('Direct Contact'),
                    _buildContactRow(),
                  ],
                  const SizedBox(height: 28),
                  _buildDisclaimerFootnote(),
                  SizedBox(height: isOwnListing ? 40 : 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isOwnListing ? null : _buildBottomCta(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1)
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
  // IMAGE HEADER — gallery with pager dots + navy fade for back button
  // ──────────────────────────────────────────────────────────
  Widget _buildImageHeader() {
    final hasImages = _listing.imageUrls.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(TablerIcons.arrow_left, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImages)
              PageView.builder(
                controller: _pageCtrl,
                itemCount: _listing.imageUrls.length,
                onPageChanged: (i) => setState(() => _activeImage = i),
                itemBuilder: (ctx, i) => Image.network(
                  _listing.imageUrls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _placeholderBg(),
                ),
              )
            else
              _placeholderBg(),
            // Top scrim for back button legibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom scrim
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Featured pill top-right
            if (_listing.isFeatured)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.goldGradient),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: AppColors.goldGlow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(TablerIcons.star_filled,
                          size: 11, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Page indicator dots
            if (hasImages && _listing.imageUrls.length > 1)
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _listing.imageUrls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: i == _activeImage ? 20 : 6,
                      decoration: BoxDecoration(
                        gradient: i == _activeImage
                            ? const LinearGradient(
                                colors: AppColors.goldGradient)
                            : null,
                        color: i == _activeImage
                            ? null
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          TablerIcons.shopping_bag,
          size: 80,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TITLE BLOCK
  // ──────────────────────────────────────────────────────────
  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcon(_listing.category),
                      size: 10, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    _listing.category.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (_listing.industryName != null)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _listing.industryName!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _listing.title,
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.6,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(ListingCategory c) {
    switch (c) {
      case ListingCategory.product:
        return TablerIcons.package;
      case ListingCategory.service:
        return TablerIcons.tool;
      case ListingCategory.consultation:
        return TablerIcons.headset;
    }
  }

  // ──────────────────────────────────────────────────────────
  // PRICE CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildPriceCard(NumberFormat fmt, bool hasMember, bool hasRegular,
      int savings) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REGULAR PRICE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRegular ? fmt.format(_listing.regularPrice) : '—',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                        decoration: hasMember
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(TablerIcons.discount_check_filled,
                            size: 10, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text(
                          'MEMBER PRICE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasMember
                          ? fmt.format(_listing.memberPrice)
                          : 'Contact',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.18),
                    AppColors.success.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.tag,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'EXCLUSIVE MEMBER SAVING · $savings% OFF',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_listing.priceNote != null &&
              _listing.priceNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(TablerIcons.info_circle,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _listing.priceNote!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SELLER CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.goldSoftGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppColors.goldGlow,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.user,
                  color: AppColors.accent, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _listing.sellerName ?? 'Verified Member',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_listing.industryName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _listing.industryName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.18),
                  AppColors.success.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(7),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.32)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(TablerIcons.discount_check,
                    size: 11, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // DESCRIPTION CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Text(
        _listing.description,
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
          height: 1.6,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CONTACT ROW
  // ──────────────────────────────────────────────────────────
  Widget _buildContactRow() {
    final items = <Widget>[];
    if (_listing.whatsappNumber != null) {
      items.add(_contactTile(
        icon: TablerIcons.brand_whatsapp,
        label: 'WhatsApp',
        tint: AppColors.success,
        onTap: _launchWhatsApp,
      ));
    }
    if (_listing.contactPhone != null) {
      items.add(_contactTile(
        icon: TablerIcons.phone,
        label: 'Call',
        tint: AppColors.accentBlue,
        onTap: _launchPhone,
      ));
    }
    if (_listing.contactEmail != null) {
      items.add(_contactTile(
        icon: TablerIcons.mail,
        label: 'Email',
        tint: AppColors.accent,
        onTap: _launchEmail,
      ));
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: items[i]),
        ],
      ],
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.18),
                      tint.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: tint.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: tint,
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
  // DISCLAIMER FOOTNOTE
  // ──────────────────────────────────────────────────────────
  Widget _buildDisclaimerFootnote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'PBN facilitates member connections only. PBN is not a party to, and does not guarantee, any transactions between members.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.textMuted,
          height: 1.55,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BOTTOM CTA — gold "I'M INTERESTED"
  // ──────────────────────────────────────────────────────────
  Widget _buildBottomCta() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 18 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _submittingInterest ? null : _expressInterest,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: _submittingInterest
                    ? LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.5),
                          AppColors.accent.withValues(alpha: 0.35),
                        ],
                      )
                    : const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    _submittingInterest ? null : AppColors.goldGlow,
              ),
              child: Center(
                child: _submittingInterest
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(TablerIcons.send,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "I'M INTERESTED",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
