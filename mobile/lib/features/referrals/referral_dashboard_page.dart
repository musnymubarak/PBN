import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';

class ReferralDashboardPage extends StatefulWidget {
  const ReferralDashboardPage({super.key});

  @override
  State<ReferralDashboardPage> createState() => _ReferralDashboardPageState();
}

class _ReferralDashboardPageState extends State<ReferralDashboardPage> {
  final _service = ReferralService();
  bool _loading = true;
  int _receivedCount = 0;
  int _sentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    int rCount = 0;
    int sCount = 0;

    try {
      final received = await _service.getReceivedReferrals();
      rCount = received.length;
    } catch (e) {
      debugPrint('Error loading received deals: $e');
    }

    try {
      final sent = await _service.getGivenReferrals();
      sCount = sent.length;
    } catch (e) {
      debugPrint('Error loading sent deals: $e');
    }

    if (mounted) {
      setState(() {
        _receivedCount = rCount;
        _sentCount = sCount;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDeals = _receivedCount + _sentCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DEAL FLOW',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            const Text('Referrals Center',
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
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // -- MAIN OVERVIEW CARD --
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Total Network Deals',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Text('$totalDeals',
                            style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -2)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_sentCount >= _receivedCount ? 'High Giving Ratio' : 'Potential Growth Needed', 
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- ACTION TILES --
                  Row(
                    children: [
                      _buildActionTile(
                        icon: TablerIcons.plus,
                        label: 'New Deal',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReferralPage())).then((_) => _loadStats()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('DEAL ACTIVITY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  // -- PERFORMANCE ROWS --
                  _buildTrackerCard(
                    title: 'Received Deals',
                    count: _receivedCount,
                    icon: TablerIcons.arrow_down_left,
                    color: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: true))).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 12),
                  _buildTrackerCard(
                    title: 'Sent Deals',
                    count: _sentCount,
                    icon: TablerIcons.arrow_up_right,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: false))).then((_) => _loadStats()),
                  ),

                  const SizedBox(height: 32),
                  _buildInstructionCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerCard({required String title, required int count, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('Track status and updates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1)),
            const SizedBox(width: 12),
            Icon(TablerIcons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(TablerIcons.info_circle, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('How it works', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'High deal flow helps you climb the leaderboard and unlock premium rewards. Always update the ROI once a deal is closed successfully.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
