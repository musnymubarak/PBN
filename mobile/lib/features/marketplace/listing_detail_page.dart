import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/models/marketplace.dart';
import 'package:pbn/core/services/marketplace_service.dart';

class ListingDetailPage extends StatefulWidget {
  final MarketplaceListing listing;

  const ListingDetailPage({super.key, required this.listing});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final _service = MarketplaceService();
  bool _submittingInterest = false;
  late MarketplaceListing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  Future<void> _expressInterest() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id == _listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot express interest in your own listing.')),
      );
      return;
    }

    setState(() => _submittingInterest = true);
    try {
      await _service.expressInterest(_listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest recorded! Seller has been notified. 🚀')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record interest. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingInterest = false);
    }
  }

  void _launchWhatsApp() async {
    if (_listing.whatsappNumber == null) return;
    final url = 'https://wa.me/${_listing.whatsappNumber!.replaceAll('+', '')}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchPhone() async {
    if (_listing.contactPhone == null) return;
    final url = 'tel:${_listing.contactPhone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchEmail() async {
    if (_listing.contactEmail == null) return;
    final url = 'mailto:${_listing.contactEmail}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
    final hasMemberPrice = _listing.memberPrice != null;
    final savings = (_listing.regularPrice != null && _listing.memberPrice != null)
        ? ((_listing.regularPrice! - _listing.memberPrice!) / _listing.regularPrice! * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Gallery
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _listing.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: _listing.imageUrls.length,
                      itemBuilder: (context, index) => Image.network(
                        _listing.imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary.withOpacity(0.05), AppColors.primary.withOpacity(0.2)],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(TablerIcons.shopping_bag, size: 80, color: AppColors.primary.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text('Exclusive Member Deal', style: TextStyle(color: AppColors.primary.withOpacity(0.3), fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _listing.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _listing.category.name.toUpperCase(),
                                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_listing.isFeatured)
                        const Icon(TablerIcons.star_filled, color: Colors.amber, size: 24),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pricing Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Regular Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _listing.regularPrice != null ? currencyFormat.format(_listing.regularPrice) : 'N/A',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                      decoration: hasMemberPrice ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PBN Member Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _listing.memberPrice != null ? currencyFormat.format(_listing.memberPrice) : 'Contact Us',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (savings > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '🎉 Exclusive Member Saving: $savings% OFF',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Seller Info
                  const Text('Seller Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(TablerIcons.user, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_listing.sellerName ?? 'Verified Member', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(_listing.industryName ?? 'Network Business', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Description
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                    _listing.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 40),

                  // Contact Options
                  const Text('Direct Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_listing.whatsappNumber != null)
                        _buildContactButton(TablerIcons.brand_whatsapp, 'WhatsApp', Colors.green, _launchWhatsApp),
                      if (_listing.contactPhone != null)
                        _buildContactButton(TablerIcons.phone, 'Call', Colors.blue, _launchPhone),
                      if (_listing.contactEmail != null)
                        _buildContactButton(TablerIcons.mail, 'Email', Colors.redAccent, _launchEmail),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                    child: const Text(
                      'PBN facilitating member connections only. PBN is not a party to, and does not guarantee, any transactions between members.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (Provider.of<AuthProvider>(context, listen: false).user?.id == _listing.sellerId)
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submittingInterest ? null : _expressInterest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submittingInterest
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('I\'m Interested', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
