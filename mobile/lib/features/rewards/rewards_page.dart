import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/models/reward.dart';
import 'package:pbn/core/widgets/privilege_card_widget.dart';

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
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_service.getMyCard(), _service.listPartners()]);
      _card = results[0] as PrivilegeCard?;
      _partners = results[1] as List<Partner>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _redeem(Offer offer) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Redeem Offer', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('Redeem "${offer.title}" for ${offer.discountPercent}% off?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Redeem')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await _service.redeemOffer(offer.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer redeemed!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to redeem'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rewards', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(onRefresh: _loadData, child: ListView(padding: const EdgeInsets.all(16), children: [
              if (_card != null) ...[
                PrivilegeCardWidget(card: _card!),
                const SizedBox(height: 32),
              ],
              const Text('Partner Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (_partners.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No partner offers available', style: TextStyle(color: Colors.grey.shade500)))),
              ..._partners.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(TablerIcons.building_store, color: AppColors.accent)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (p.description != null) Text(p.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                  if (p.offers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...p.offers.map((o) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${o.discountPercent}% off', style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w700)),
                        ])),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _redeem(o),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            child: const Text('Redeem'),
                          ),
                        ),
                      ]),
                    )),
                  ],
                ]),
              )),
            ])),
    );
  }
}
