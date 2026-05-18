import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/widgets/pbn_bottom_sheet.dart';
import 'package:pbn/features/marketplace/create_listing_page.dart';
import 'package:pbn/models/marketplace.dart';
import 'package:pbn/models/member.dart';

class MyMarketplacePage extends StatefulWidget {
  const MyMarketplacePage({super.key});

  @override
  State<MyMarketplacePage> createState() => _MyMarketplacePageState();
}

class _MyMarketplacePageState extends State<MyMarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = MarketplaceService();
  bool _loading = true;
  List<MarketplaceListing> _myListings = [];
  List<MarketplaceInterest> _receivedInterests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final listings = await _service.getMyListings();
      final List<MarketplaceInterest> allInterests = [];
      for (final l in listings) {
        final interests = await _service.getInterests(l.id);
        allInterests.addAll(interests);
      }
      if (mounted) {
        setState(() {
          _myListings = listings;
          _receivedInterests = allInterests
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pendingCount = _receivedInterests
        .where((i) => i.status == InterestStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(
          'My Marketplace',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.text,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('LISTINGS'),
                      const SizedBox(width: 6),
                      _tabCountPill('${_myListings.length}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('INTERESTS'),
                      const SizedBox(width: 6),
                      _tabCountPill(
                        '${_receivedInterests.length}',
                        highlight: pendingCount > 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyListingsTab(),
              _buildInterestsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabCountPill(String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(colors: AppColors.goldGradient)
            : null,
        color: highlight ? null : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: highlight ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // MY LISTINGS TAB
  // ──────────────────────────────────────────────────────────
  Widget _buildMyListingsTab() {
    if (_myListings.isEmpty && !_loading) {
      return _buildEmptyState(
        icon: TablerIcons.shopping_bag,
        title: 'No listings yet',
        subtitle: 'Post your first deal to reach the PBN network.',
        ctaLabel: 'POST A LISTING',
        ctaIcon: TablerIcons.plus,
        onCta: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingPage()),
          );
          if (ok == true) _loadData();
        },
      );
    }

    final fmt = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _myListings.length,
      itemBuilder: (context, i) {
        final l = _myListings[i];
        return _MyListingCard(
          listing: l,
          currencyFormat: fmt,
          onEdit: () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateListingPage(listing: l)),
            );
            if (ok == true) _loadData();
          },
          onDelete: () => _confirmDelete(l),
        )
            .animate(delay: (i * 35).clamp(0, 280).ms)
            .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
            .slideY(
                begin: 0.10,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOutCubic);
      },
    );
  }

  Future<void> _confirmDelete(MarketplaceListing l) async {
    HapticFeedback.selectionClick();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(TablerIcons.trash,
                        color: AppColors.error, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete listing?',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'This will permanently remove the deal from the marketplace. This cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'CANCEL',
                      onTap: () => Navigator.pop(ctx, false),
                      tint: AppColors.textSecondary,
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogButton(
                      label: 'DELETE',
                      onTap: () => Navigator.pop(ctx, true),
                      tint: AppColors.error,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _service.deleteListing(l.id);
      _loadData();
    }
  }

  Widget _dialogButton({
    required String label,
    required VoidCallback onTap,
    required Color tint,
    required bool filled,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? tint : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(
                    color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: filled ? Colors.white : tint,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INTERESTS TAB
  // ──────────────────────────────────────────────────────────
  Widget _buildInterestsTab() {
    if (_receivedInterests.isEmpty && !_loading) {
      return _buildEmptyState(
        icon: TablerIcons.message_heart,
        title: 'No interests yet',
        subtitle:
            'When members express interest in your listings, they\'ll show up here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _receivedInterests.length,
      itemBuilder: (context, i) {
        final interest = _receivedInterests[i];
        final listing = _myListings.firstWhere(
          (l) => l.id == interest.listingId,
          orElse: () => _myListings.isEmpty ? _placeholderListing() : _myListings.first,
        );
        return _InterestCard(
          interest: interest,
          listing: listing,
          onTap: () => _showInterestSheet(interest, listing),
          onConfirm: () => _confirmDeal(interest),
          onCancel: () async {
            HapticFeedback.selectionClick();
            await _service.updateInterestStatus(interest.id,
                status: 'cancelled');
            _loadData();
          },
        )
            .animate(delay: (i * 35).clamp(0, 280).ms)
            .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
            .slideY(
                begin: 0.10,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOutCubic);
      },
    );
  }

  MarketplaceListing _placeholderListing() {
    return MarketplaceListing(
      id: '',
      sellerId: '',
      title: 'Listing',
      description: '',
      category: ListingCategory.product,
      industryCategoryId: '',
      currency: 'LKR',
      imageUrls: const [],
      isFeatured: false,
      status: ListingStatus.active,
      viewCount: 0,
      interestCount: 0,
      isApproved: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INTEREST DETAIL SHEET
  // ──────────────────────────────────────────────────────────
  void _showInterestSheet(
      MarketplaceInterest interest, MarketplaceListing listing) {
    final memberProvider = context.read<MemberProvider>();
    Member? member;
    for (final m in memberProvider.members) {
      if (m.userId == interest.interestedUserId) {
        member = m;
        break;
      }
    }

    showPbnBottomSheet(
      context,
      builder: (ctx) {
        return PbnBottomSheet(
          child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _interestHeroCard(interest, member),
                      const SizedBox(height: 18),
                      _detailSubHeader('Interested In'),
                      const SizedBox(height: 8),
                      _listingMiniCard(listing),
                      if (interest.message != null &&
                          interest.message!.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _detailSubHeader('Their Message'),
                        const SizedBox(height: 8),
                        _messageBubble(interest.message!),
                      ],
                      if (member != null) ...[
                        const SizedBox(height: 18),
                        _detailSubHeader('Member Details'),
                        const SizedBox(height: 8),
                        _memberInfoCard(member),
                        if (member.isSameChapter) ...[
                          const SizedBox(height: 14),
                          _contactRow(member),
                        ] else ...[
                          const SizedBox(height: 14),
                          _privacyNote(),
                        ],
                      ] else ...[
                        const SizedBox(height: 18),
                        _privacyNote(
                          message:
                              'Full profile details aren\'t in your visible network yet. Confirm the deal to record the connection.',
                        ),
                      ],
                      const SizedBox(height: 22),
                      _interestActionBar(interest),
                    ],
          ),
        );
      },
    );
  }

  Widget _detailSubHeader(String text) {
    return Row(
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
    );
  }

  Widget _interestHeroCard(MarketplaceInterest interest, Member? member) {
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
                      imageUrl: member?.profilePhoto,
                      initials: _initials(interest.interestedUserName),
                      size: 68,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          interest.interestedUserName,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 18,
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
                        if (member?.industry != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            member!.industry,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _glassPill(
                              icon: _interestStatusIcon(interest.status),
                              label: _interestStatusLabel(interest.status),
                              color: _interestStatusColor(interest.status),
                            ),
                            _glassPill(
                              icon: TablerIcons.clock,
                              label: _formatRelative(interest.createdAt),
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
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

  Widget _listingMiniCard(MarketplaceListing l) {
    final fmt = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: l.imageUrls.isNotEmpty
                  ? Image.network(
                      l.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _miniPlaceholder(),
                    )
                  : _miniPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
                if (l.memberPrice != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    fmt.format(l.memberPrice),
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(TablerIcons.shopping_bag,
            size: 20, color: AppColors.textMuted),
      ),
    );
  }

  Widget _messageBubble(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        message,
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
          height: 1.55,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _memberInfoCard(Member member) {
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
      child: Column(
        children: [
          _infoRow(
            icon: TablerIcons.briefcase,
            iconColor: AppColors.accentBlue,
            label: 'INDUSTRY',
            value: member.industry,
          ),
          _hairline(),
          _infoRow(
            icon: TablerIcons.building_community,
            iconColor: AppColors.accent,
            label: 'CHAPTER',
            value: member.chapterName ?? 'Unknown',
          ),
          _hairline(),
          _infoRow(
            icon: TablerIcons.building_store,
            iconColor: AppColors.accent,
            label: 'COMPANY',
            value: member.company,
          ),
        ],
      ),
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
    required Color iconColor,
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
                  iconColor.withValues(alpha: 0.18),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 15, color: iconColor),
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

  Widget _contactRow(Member member) {
    final items = <Widget>[];
    if (member.phoneNumber != null) {
      items.add(_contactTile(
        icon: TablerIcons.phone,
        label: 'CALL',
        tint: AppColors.accentBlue,
        onTap: () => launchUrl(Uri.parse('tel:${member.phoneNumber}')),
      ));
      items.add(_contactTile(
        icon: TablerIcons.brand_whatsapp,
        label: 'WHATSAPP',
        tint: AppColors.success,
        onTap: () {
          final phone =
              member.phoneNumber!.replaceAll(RegExp(r'\D'), '');
          launchUrl(
            Uri.parse('https://wa.me/$phone'),
            mode: LaunchMode.externalApplication,
          );
        },
      ));
    }
    if (member.email != null) {
      items.add(_contactTile(
        icon: TablerIcons.mail,
        label: 'EMAIL',
        tint: AppColors.accent,
        onTap: () => launchUrl(Uri.parse('mailto:${member.email}')),
      ));
    }
    if (items.isEmpty) return _privacyNote();

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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tint.withValues(alpha: 0.28)),
          ),
          child: Column(
            children: [
              Icon(icon, color: tint, size: 18),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: tint,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyNote({String? message}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(TablerIcons.lock,
                color: AppColors.textMuted, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ??
                  'Contact details are only visible to members of the same chapter.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interestActionBar(MarketplaceInterest interest) {
    if (interest.status == InterestStatus.dealConfirmed) {
      final fmt = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.16),
              AppColors.success.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(TablerIcons.circle_check_filled,
                  color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DEAL CONFIRMED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fmt.format(interest.businessValue ?? 0),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (interest.status == InterestStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.circle_x,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            const Text(
              'CANCELLED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.pop(context);
                _confirmDeal(interest);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.goldGlow,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TablerIcons.check, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'CONFIRM DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              Navigator.pop(context);
              HapticFeedback.selectionClick();
              await _service.updateInterestStatus(interest.id,
                  status: 'cancelled');
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.28)),
              ),
              child: const Icon(TablerIcons.x,
                  color: AppColors.error, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // CONFIRM DEAL DIALOG
  // ──────────────────────────────────────────────────────────
  Future<void> _confirmDeal(MarketplaceInterest interest) async {
    HapticFeedback.selectionClick();
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.goldGradient),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppColors.goldGlow,
                    ),
                    child: const Icon(TablerIcons.cash,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Record Business Value',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the final transaction value. This updates your Member ROI.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Value (LKR)',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(TablerIcons.currency_dollar,
                        color: AppColors.accent, size: 16),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'CANCEL',
                      onTap: () => Navigator.pop(ctx),
                      tint: AppColors.textSecondary,
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(
                            ctx, double.tryParse(controller.text)),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.goldGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.goldGlow,
                          ),
                          child: const Text(
                            'CONFIRM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
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
      ),
    );

    if (value != null) {
      setState(() => _loading = true);
      try {
        await _service.updateInterestStatus(
          interest.id,
          status: 'deal_confirmed',
          businessValue: value,
        );
        _loadData();
      } catch (e) {
        setState(() => _loading = false);
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE (P-10)
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? ctaLabel,
    IconData? ctaIcon,
    VoidCallback? onCta,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
                child:
                    Icon(icon, size: 32, color: AppColors.accent),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: 18),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onCta,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.goldGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.goldGlow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ctaIcon != null) ...[
                            Icon(ctaIcon, color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            ctaLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────
  Widget _glassPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  IconData _interestStatusIcon(InterestStatus s) {
    switch (s) {
      case InterestStatus.dealConfirmed:
        return TablerIcons.circle_check_filled;
      case InterestStatus.cancelled:
        return TablerIcons.circle_x;
      case InterestStatus.pending:
        return TablerIcons.clock_hour_4;
    }
  }

  String _interestStatusLabel(InterestStatus s) {
    switch (s) {
      case InterestStatus.dealConfirmed:
        return 'CONFIRMED';
      case InterestStatus.cancelled:
        return 'CANCELLED';
      case InterestStatus.pending:
        return 'PENDING';
    }
  }

  Color _interestStatusColor(InterestStatus s) {
    switch (s) {
      case InterestStatus.dealConfirmed:
        return AppColors.success;
      case InterestStatus.cancelled:
        return AppColors.textMuted;
      case InterestStatus.pending:
        return AppColors.accent;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) {
      return DateFormat('MMM d').format(dt);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}

// ─────────────────────────────────────────────────────────────
// MY LISTING CARD
// ─────────────────────────────────────────────────────────────
class _MyListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.listing,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = listing.isApproved;
    final isRejected = !isApproved && listing.rejectionReason != null;
    final isPending = !isApproved && listing.rejectionReason == null;

    final approvalColor = isApproved
        ? AppColors.success
        : (isRejected ? AppColors.error : AppColors.warning);
    final approvalLabel = isApproved
        ? 'APPROVED'
        : (isRejected ? 'REJECTED' : 'PENDING REVIEW');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: listing.imageUrls.isNotEmpty
                          ? Image.network(
                              listing.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _statusPill(approvalLabel, approvalColor,
                              filled: isPending),
                          if (isApproved)
                            _statusPill(listing.status.name.toUpperCase(),
                                listing.status == ListingStatus.active
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                filled: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isRejected) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(TablerIcons.alert_circle,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${listing.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _metric(TablerIcons.eye, '${listing.viewCount}', 'views'),
                const SizedBox(width: 14),
                _metric(TablerIcons.heart_filled,
                    '${listing.interestCount}', 'interests'),
                const Spacer(),
                _iconButton(
                  icon: TablerIcons.edit,
                  tint: AppColors.accentBlue,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _iconButton(
                  icon: TablerIcons.trash,
                  tint: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(TablerIcons.photo,
            color: AppColors.textMuted, size: 22),
      ),
    );
  }

  Widget _statusPill(String label, Color color, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: filled ? null : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$value ',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: tint.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: tint, size: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INTEREST CARD
// ─────────────────────────────────────────────────────────────
class _InterestCard extends StatelessWidget {
  final MarketplaceInterest interest;
  final MarketplaceListing listing;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _InterestCard({
    required this.interest,
    required this.listing,
    required this.onTap,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = interest.status == InterestStatus.pending;
    final isConfirmed = interest.status == InterestStatus.dealConfirmed;
    final isCancelled = interest.status == InterestStatus.cancelled;

    final statusColor = isConfirmed
        ? AppColors.success
        : isCancelled
            ? AppColors.textMuted
            : AppColors.accent;
    final statusLabel = isConfirmed
        ? 'CONFIRMED'
        : isCancelled
            ? 'CANCELLED'
            : 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials(interest.interestedUserName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  interest.interestedUserName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              _statusPill(statusLabel, statusColor),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Interested in: ${listing.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (interest.message != null &&
                    interest.message!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      interest.message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(TablerIcons.clock,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _formatRelative(interest.createdAt),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (isPending) ...[
                      _smallAction(
                        icon: TablerIcons.x,
                        tint: AppColors.error,
                        onTap: onCancel,
                      ),
                      const SizedBox(width: 8),
                      _smallAction(
                        icon: TablerIcons.check,
                        tint: AppColors.success,
                        onTap: onConfirm,
                        filled: true,
                      ),
                    ] else
                      _viewProfileButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _smallAction({
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: filled ? tint : tint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: tint.withValues(alpha: filled ? 0 : 0.32)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon,
              size: 14, color: filled ? Colors.white : tint),
        ),
      ),
    );
  }

  Widget _viewProfileButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'VIEW',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(width: 4),
          Icon(TablerIcons.chevron_right,
              size: 12, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) {
      return DateFormat('MMM d').format(dt);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}
