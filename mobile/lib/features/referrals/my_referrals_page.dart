import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/models/referral.dart';

class MyReferralsPage extends StatefulWidget {
  const MyReferralsPage({super.key});

  @override
  State<MyReferralsPage> createState() => _MyReferralsPageState();
}

class _MyReferralsPageState extends State<MyReferralsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ReferralService();
  List<Referral> _given = [];
  List<Referral> _received = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_service.getGivenReferrals(), _service.getReceivedReferrals()]);
      _given = results[0]; _received = results[1];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Referrals', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800), indicatorColor: AppColors.accent, indicatorWeight: 3,
          tabs: [Tab(text: 'Sent (${_given.length})'), Tab(text: 'Received (${_received.length})')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(controller: _tabController, children: [
              _buildList(_given, 'No referrals sent yet'),
              _buildList(_received, 'No referrals received yet'),
            ]),
    );
  }

  Widget _buildList(List<Referral> referrals, String emptyMsg) {
    if (referrals.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(TablerIcons.arrows_exchange, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: referrals.length,
        itemBuilder: (context, i) => _buildCard(referrals[i]),
      ),
    );
  }

  Widget _buildCard(Referral ref) {
    final color = _statusColor(ref.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(ref.leadName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(ref.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(TablerIcons.user, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text('To: ${ref.targetUser.fullName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const Spacer(),
          Text(ref.createdAt.split('T').first, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
        if (ref.notes != null && ref.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(ref.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted': return Colors.blue;
      case 'contacted': return Colors.orange;
      case 'in_progress': return AppColors.accent;
      case 'closed_won': return Colors.green;
      case 'closed_lost': return Colors.red;
      default: return Colors.grey;
    }
  }
}
