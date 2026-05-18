import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/features/marketplace/create_listing_page.dart';
import 'package:pbn/features/marketplace/listing_detail_page.dart';
import 'package:pbn/features/marketplace/my_marketplace_page.dart';
import 'package:pbn/models/marketplace.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _service = MarketplaceService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<MarketplaceListing> _listings = [];
  List<MarketplaceListing> _featuredListings = [];
  List<MarketplaceListing> _myListings = [];
  bool _loading = true;
  String? _error;
  ListingCategory? _activeCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // DATA
  // ──────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        _service.getListings(
            search: _searchQuery, category: _activeCategory),
        _service.getListings(featuredOnly: true, limit: 5),
        _service.getMyListings().catchError((_) => <MarketplaceListing>[]),
      ]);
      if (mounted) {
        setState(() {
          _listings = futures[0];
          _featuredListings = futures[1];
          _myListings = futures[2];
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Marketplace Load Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = 'Failed to load marketplace';
          _loading = false;
        });
      }
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _activeCategory = null;
    });
    _loadData();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _activeCategory != null;

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    final showFeatured = _featuredListings.isNotEmpty &&
        _searchQuery.isEmpty &&
        _activeCategory == null;

    final sections = <Widget>[
      _buildHero(),
      const SizedBox(height: 14),
      _buildStatStrip(),
      const SizedBox(height: 22),
      _buildSearchBar(),
      const SizedBox(height: 10),
      _buildCategoryChips(),
      const SizedBox(height: 20),
      if (showFeatured) ...[
        _sectionHeader('Featured',
            trailing: '${_featuredListings.length}'),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _featuredListings.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _FeaturedCard(
              listing: _featuredListings[i],
              currencyFormat: currencyFormat,
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
      _sectionHeader(
        _searchQuery.isNotEmpty
            ? 'Search Results'
            : _activeCategory != null
                ? '${_categoryLabel(_activeCategory!)} Listings'
                : 'All Listings',
        trailing: '${_listings.length}',
      ),
      if (_error != null && _listings.isEmpty)
        _buildErrorState()
      else if (_listings.isEmpty && !_loading)
        _buildEmptyState()
      else
        ..._listings.map((l) => _ListingRow(
              listing: l,
              currencyFormat: currencyFormat,
            )),
      const SizedBox(height: 24),
      _buildDisclaimerFootnote(),
      const SizedBox(height: 100),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Marketplace',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Members-only deals from verified sellers',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
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
                  letterSpacing: 0.6,
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
                      AppColors.accent.withValues(alpha: 0.22),
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
                      AppColors.accentBlue.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
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
                        child: const Icon(TablerIcons.shopping_cart,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'THE MEMBER MARKETPLACE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exclusive deals\nfrom verified members.',
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
                    'Members-only pricing. Direct contact. PBN connects, you transact.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateListingPage()),
                          ).then((v) {
                            if (v == true) _loadData();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.goldGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.goldGlow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(TablerIcons.plus,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'POST A LISTING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
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
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STAT STRIP (P-3)
  // ──────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    Widget chip({
      required IconData icon,
      required Color tint,
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
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
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7)),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tint.withValues(alpha: 0.18),
                          tint.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: tint.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, color: tint, size: 13),
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
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          icon: TablerIcons.shopping_bag,
          tint: AppColors.accentBlue,
          value: '${_listings.length}',
          label: 'Listed',
        ),
        const SizedBox(width: 8),
        chip(
          icon: TablerIcons.star_filled,
          tint: AppColors.accent,
          value: '${_featuredListings.length}',
          label: 'Featured',
        ),
        const SizedBox(width: 8),
        chip(
          icon: TablerIcons.user_check,
          tint: AppColors.success,
          value: '${_myListings.length}',
          label: 'Yours',
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyMarketplacePage()),
            ).then((_) => _loadData());
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR (P-6)
  // ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search marketplace…',
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(TablerIcons.search,
              color: AppColors.textMuted, size: 18),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(TablerIcons.x,
                      color: AppColors.textMuted, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadData();
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CATEGORY CHIPS (P-7)
  // ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _categoryChip('All', null, TablerIcons.apps),
          const SizedBox(width: 8),
          _categoryChip(
              'Products', ListingCategory.product, TablerIcons.package),
          const SizedBox(width: 8),
          _categoryChip(
              'Services', ListingCategory.service, TablerIcons.tool),
          const SizedBox(width: 8),
          _categoryChip('Consultation', ListingCategory.consultation,
              TablerIcons.headset),
        ],
      ),
    );
  }

  Widget _categoryChip(
      String label, ListingCategory? category, IconData icon) {
    final isSelected = _activeCategory == category;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeCategory = category);
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.goldGradient)
                : const LinearGradient(
                    colors: AppColors.surfaceGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.55)
                  : AppColors.border.withValues(alpha: 0.7),
              width: isSelected ? 1.2 : 1,
            ),
            boxShadow:
                isSelected ? AppColors.goldGlow : AppColors.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.text,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(ListingCategory c) {
    switch (c) {
      case ListingCategory.product:
        return 'Product';
      case ListingCategory.service:
        return 'Service';
      case ListingCategory.consultation:
        return 'Consultation';
    }
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
            child: const Icon(TablerIcons.shopping_bag,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            _hasActiveFilters
                ? 'No matches found'
                : 'No listings yet',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasActiveFilters
                ? 'Try a different search or clear the filters.'
                : 'Be the first to post in this category.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _hasActiveFilters
                  ? _clearFilters
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateListingPage()),
                      ).then((v) {
                        if (v == true) _loadData();
                      });
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.goldGlow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasActiveFilters
                          ? TablerIcons.refresh
                          : TablerIcons.plus,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasActiveFilters
                          ? 'CLEAR FILTERS'
                          : 'POST A LISTING',
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ERROR STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                size: 28, color: AppColors.error),
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load marketplace",
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.goldGlow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.refresh,
                        color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'TRY AGAIN',
                      style: TextStyle(
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // DISCLAIMER FOOTNOTE (demoted from amber banner)
  // ──────────────────────────────────────────────────────────
  Widget _buildDisclaimerFootnote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        'PBN facilitates connections only. We are not a party to transactions.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.textMuted,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LISTING ROW (P-5 list-item card)
// ─────────────────────────────────────────────────────────────
class _ListingRow extends StatelessWidget {
  final MarketplaceListing listing;
  final NumberFormat currencyFormat;

  const _ListingRow({required this.listing, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final hasMemberPrice = listing.memberPrice != null;
    final hasRegular = listing.regularPrice != null;
    final showStrike = hasMemberPrice &&
        hasRegular &&
        listing.regularPrice! > listing.memberPrice!;

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
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ListingDetailPage(listing: listing)),
            );
          },
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (gold-soft-ring frame)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: listing.imageUrls.isNotEmpty
                          ? Image.network(
                              listing.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) =>
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                                letterSpacing: -0.2,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (listing.isFeatured)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: AppColors.goldGradient),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(TablerIcons.user_circle,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              listing.sellerName ?? 'Member',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasMemberPrice)
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              currencyFormat.format(listing.memberPrice),
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (showStrike)
                              Text(
                                currencyFormat.format(listing.regularPrice),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        )
                      else
                        Text(
                          'Contact for price',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(TablerIcons.chevron_right,
                      color: AppColors.textMuted, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(TablerIcons.shopping_bag,
            color: AppColors.textMuted, size: 26),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FEATURED CARD (P-11)
// ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final MarketplaceListing listing;
  final NumberFormat currencyFormat;

  const _FeaturedCard(
      {required this.listing, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ListingDetailPage(listing: listing)),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (listing.imageUrls.isNotEmpty)
                  Image.network(
                    listing.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => _placeholderBg(),
                  )
                else
                  _placeholderBg(),
                // Bottom navy fade for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.85),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gold FEATURED pill (P-8)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: AppColors.goldGlow,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TablerIcons.star_filled,
                                size: 10, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (listing.memberPrice != null)
                            Text(
                              currencyFormat.format(listing.memberPrice),
                              style: GoogleFonts.dmSans(
                                color: AppColors.accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            )
                          else
                            const Text(
                              'Contact for Price',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(TablerIcons.chevron_right,
                                color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          size: 56,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
