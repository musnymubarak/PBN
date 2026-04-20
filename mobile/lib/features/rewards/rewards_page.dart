import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/features/rewards/qr_redeem_screen.dart';
import 'package:pbn/models/reward.dart';
import 'package:pbn/core/widgets/privilege_card_widget.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      final results =
          await Future.wait([_service.getMyCard(), _service.listPartners()]);
      _card = results[0] as PrivilegeCard?;
      _partners = results[1] as List<Partner>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleRedeem(Offer offer, String partnerName) async {
    if (offer.isRedeemedByMe) return;

    if (offer.redemptionMethod == 'coupon') {
      await _showCouponRedeemDialog(offer, partnerName);
      return;
    }

    // Default to QR
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
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const Icon(TablerIcons.ticket, color: AppColors.primary, size: 48),
                    const SizedBox(height: 16),
                    Text(offer.title, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.text)),
                    Text(partnerName, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('YOUR COUPON CODE', 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: Text(coupon.code, 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 4, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 24),
                    Text(offer.description ?? 'Use this code at checkout to claim your reward.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Copy to clipboard logic could be added here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard!'))
                          );
                        },
                        icon: const Icon(TablerIcons.copy),
                        label: const Text('COPY & CLOSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      _loadData();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate coupon: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REWARDS CATALOG',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text('Exclusive Offers',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_card != null) ...[
                    const Text('YOUR ACTIVE PASS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    PrivilegeCardWidget(card: _card!),
                    const SizedBox(height: 32),
                  ],
                  
                  const Text('PARTNER OFFERS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  
                  if (_partners.isEmpty)
                    _buildEmptyState()
                  else
                    ..._partners.map((p) => _buildPartnerCard(p)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(TablerIcons.gift_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No active offers available',
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Partner p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: p.logoUrl != null && p.logoUrl!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            final imageUrl = p.logoUrl!.startsWith('http')
                                ? p.logoUrl!
                                : '${ApiConfig.staticUrl}${p.logoUrl}';
                            
                            if (imageUrl.toLowerCase().endsWith('.svg')) {
                              return SvgPicture.network(
                                imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                                placeholderBuilder: (context) => const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              );
                            }
                            
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              errorWidget: (context, url, error) => const Icon(TablerIcons.building_store, color: AppColors.primary, size: 32),
                            );
                          },
                        )
                      : const Icon(TablerIcons.building_store, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
                      if (p.description != null)
                        Text(p.description!, 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Offers List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: p.offers.map((o) => _buildOfferItem(o, p.name)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferItem(Offer o, String partnerName) {
    final isRedeemed = o.isRedeemedByMe;
    final color = isRedeemed ? Colors.grey : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRedeemed ? Colors.grey.shade50.withOpacity(0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isRedeemed ? Colors.grey : AppColors.text,
                        decoration: isRedeemed ? TextDecoration.lineThrough : null)),
                Row(
                  children: [
                    if (o.discountPercent > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: isRedeemed ? Colors.grey.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('${o.discountPercent.toStringAsFixed(0)}% OFF',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isRedeemed ? Colors.grey : Colors.green)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Icon(
                            o.redemptionMethod == 'qr' ? TablerIcons.qrcode : TablerIcons.ticket,
                            size: 10,
                            color: isRedeemed ? Colors.grey : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(o.redemptionMethod.toUpperCase(),
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isRedeemed ? Colors.grey : Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isRedeemed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(TablerIcons.circle_check, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('USED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 0.5)),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _handleRedeem(o, partnerName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('REDEEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
        ],
      ),
    );
  }
}
