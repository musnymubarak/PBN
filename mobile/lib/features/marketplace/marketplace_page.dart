import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/models/marketplace.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:intl/intl.dart';
import 'package:pbn/features/marketplace/listing_detail_page.dart';
import 'package:pbn/features/marketplace/create_listing_page.dart';
import 'package:pbn/features/marketplace/my_marketplace_page.dart';

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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
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
          search: _searchQuery,
          category: _activeCategory,
        ),
        _service.getListings(featuredOnly: true, limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _listings = futures[0];
          _featuredListings = futures[1];
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marketplace',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5)),
            Text('Exclusive Member Deals',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.layout_dashboard, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyMarketplacePage()),
            ).then((_) => _loadData()),
            tooltip: 'My Management',
          ),
          const PbnAppBarActions(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Search and Filters
            SliverToBoxAdapter(
              child: _buildSearchAndFilter(),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _buildErrorState(),
              )
            else ...[
              // Featured Section
              if (_featuredListings.isNotEmpty && _searchQuery.isEmpty && _activeCategory == null)
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(currencyFormat),
                ),

              // Disclaimer
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(TablerIcons.info_circle, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'PBN facilitates connections only. We are not a party to transactions.',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Listings Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _searchQuery.isNotEmpty ? 'Search Results' : 'All Listings',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              // Grid of Listings
              if (_listings.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ListingCard(
                        listing: _listings[index],
                        currencyFormat: currencyFormat,
                      ),
                      childCount: _listings.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingPage()),
          ).then((value) {
            if (value == true) _loadData();
          });
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(TablerIcons.plus, color: Colors.white),
        label: const Text('Post Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search marketplace...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600),
                prefixIcon: const Icon(TablerIcons.search, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null, TablerIcons.apps),
                const SizedBox(width: 8),
                _buildCategoryChip('Products', ListingCategory.product, TablerIcons.package),
                const SizedBox(width: 8),
                _buildCategoryChip('Services', ListingCategory.service, TablerIcons.tool),
                const SizedBox(width: 8),
                _buildCategoryChip('Consult', ListingCategory.consultation, TablerIcons.headset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, ListingCategory? category, IconData icon) {
    final isSelected = _activeCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeCategory = category;
        });
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w700, 
                color: isSelected ? Colors.white : Colors.grey.shade600
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Icon(TablerIcons.star_filled, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text('Featured Deals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _featuredListings.length,
            itemBuilder: (context, index) => _FeaturedCard(
              listing: _featuredListings[index],
              format: format,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.shopping_cart_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matches found' : 'Nothing here yet',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(TablerIcons.alert_triangle, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          TextButton(onPressed: _loadData, child: const Text('RETRY')),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final NumberFormat currencyFormat;

  const _ListingCard({required this.listing, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailPage(listing: listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: listing.imageUrls.isNotEmpty
                    ? Image.network(listing.imageUrls[0], fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary.withOpacity(0.05), AppColors.primary.withOpacity(0.1)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(TablerIcons.shopping_bag, color: AppColors.primary.withOpacity(0.2), size: 48),
                              const SizedBox(height: 8),
                              Text('PBN Marketplace', style: TextStyle(color: AppColors.primary.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.sellerName ?? 'Member',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (listing.memberPrice != null) ...[
                    Text(
                      currencyFormat.format(listing.memberPrice),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14),
                    ),
                    if (listing.regularPrice != null)
                      Text(
                        currencyFormat.format(listing.regularPrice),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ] else
                    const Text('Contact for Price',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final MarketplaceListing listing;
  final NumberFormat format;

  const _FeaturedCard({required this.listing, required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (listing.imageUrls.isNotEmpty)
              Image.network(listing.imageUrls[0], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.3)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.shopping_bag, size: 64, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('PBN Featured', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(TablerIcons.star_filled, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (listing.memberPrice != null)
                        Text(
                          format.format(listing.memberPrice),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        )
                      else
                        const Text('Contact for Price', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      const Icon(TablerIcons.chevron_right, color: Colors.white, size: 16),
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
}
