import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/reward_service.dart';
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
      final results =
          await Future.wait([_service.getMyCard(), _service.listPartners()]);
      _card = results[0] as PrivilegeCard?;
      _partners = results[1] as List<Partner>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleRedeem(Offer offer, String partnerName) async {
    if (offer.isRedeemedByMe) return;

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

    // If the offer was redeemed, refresh the data
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Rewards',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_card != null) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFF0A2540),
                          Color(0xFF1E3A8A)
                        ]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MY PRIVILEGE CARD',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(_card!.tier.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_card!.cardNumber,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Text('${_card!.points} Points',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text('Partner Offers',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (_partners.isEmpty)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No partner offers available',
                                style: TextStyle(
                                    color: Colors.grey.shade500)))),
                  ..._partners.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8)
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color:
                                        AppColors.accent.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: const Icon(
                                    TablerIcons.building_store,
                                    color: AppColors.accent),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    if (p.description != null)
                                      Text(p.description!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.grey.shade500),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ]),
                            if (p.offers.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...p.offers.map((o) => _buildOfferRow(o, p.name)),
                            ],
                          ],
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildOfferRow(Offer o, String partnerName) {
    final isRedeemed = o.isRedeemedByMe;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Opacity(
        opacity: isRedeemed ? 0.5 : 1.0,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: isRedeemed
                            ? TextDecoration.lineThrough
                            : null,
                      )),
                  if (o.discountPercent > 0)
                    Text(
                      '${o.discountPercent.toStringAsFixed(0)}% off',
                      style: TextStyle(
                          fontSize: 12,
                          color: isRedeemed
                              ? Colors.grey.shade500
                              : Colors.green.shade600,
                          fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 32,
              child: isRedeemed
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Redeemed',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _handleRedeem(o, partnerName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Redeem'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
