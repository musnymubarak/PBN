import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/models/marketplace.dart';

class MyMarketplacePage extends StatefulWidget {
  const MyMarketplacePage({super.key});

  @override
  State<MyMarketplacePage> createState() => _MyMarketplacePageState();
}

class _MyMarketplacePageState extends State<MyMarketplacePage> with SingleTickerProviderStateMixin {
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

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final listings = await _service.getMyListings();
      
      // Fetch interests for all my listings
      final List<MarketplaceInterest> allInterests = [];
      for (var l in listings) {
        final interests = await _service.getInterests(l.id);
        allInterests.addAll(interests);
      }

      if (mounted) {
        setState(() {
          _myListings = listings;
          _receivedInterests = allInterests;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Marketplace', style: TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'MY LISTINGS'),
            Tab(text: 'INTERESTS'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyListingsList(),
                _buildInterestsList(),
              ],
            ),
    );
  }

  Widget _buildMyListingsList() {
    if (_myListings.isEmpty) return _buildEmptyState('You haven\'t posted any deals yet.');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myListings.length,
      itemBuilder: (context, index) {
        final l = _myListings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: l.imageUrls.isNotEmpty 
                ? Image.network(l.imageUrls[0], width: 50, height: 50, fit: BoxFit.cover)
                : Container(width: 50, height: 50, color: Colors.grey.shade100, child: const Icon(TablerIcons.photo)),
            ),
            title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: l.status == ListingStatus.active ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(l.status.name.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: l.status == ListingStatus.active ? Colors.green.shade700 : Colors.orange.shade700)),
                ),
                const SizedBox(width: 8),
                Text('${l.interestCount} interests', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Listing?'),
                    content: const Text('This will permanently remove this deal from the marketplace.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _service.deleteListing(l.id);
                  _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterestsList() {
    if (_receivedInterests.isEmpty) return _buildEmptyState('No interests recorded yet.');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedInterests.length,
      itemBuilder: (context, index) {
        final i = _receivedInterests[index];
        final listing = _myListings.firstWhere((l) => l.id == i.listingId, orElse: () => _myListings[0]); // fallback
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(i.interestedUserName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.interestedUserName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('Interested in: ${listing.title}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (i.status == InterestStatus.deal_confirmed)
                      const Icon(TablerIcons.circle_check_filled, color: Colors.green)
                  ],
                ),
                if (i.message != null && i.message!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text(i.message!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ),
                ],
                const SizedBox(height: 16),
                if (i.status == InterestStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmDeal(i),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CONFIRM DEAL', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(TablerIcons.x, color: Colors.red),
                        onPressed: () async {
                          await _service.updateInterestStatus(i.id, status: 'cancelled');
                          _loadData();
                        },
                      ),
                    ],
                  )
                else if (i.status == InterestStatus.deal_confirmed)
                  Text(
                    'Value: ${NumberFormat.currency(symbol: 'LKR ').format(i.businessValue ?? 0)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14),
                  )
                else
                  const Text('Cancelled', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeal(MarketplaceInterest interest) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Business Value'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the final transaction value to update your Member ROI.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Value (LKR)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('CONFIRM'),
          ),
        ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.package, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
