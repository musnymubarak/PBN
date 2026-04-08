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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Referrals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: Colors.black,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // -- MAIN METRIC --
                    const Text('Total Network Deals', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('$totalDeals', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -2)),
                    const SizedBox(height: 32),

                    // -- QUICK ACTIONS (CIRCLES) --
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickAction(context, 'New Deal', TablerIcons.plus, Colors.black, Colors.white, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReferralPage())).then((_) => _loadStats());
                        }),
                        _buildQuickAction(context, 'Received', TablerIcons.arrow_down_left, const Color(0xFFF3F4F6), Colors.black, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: true))).then((_) => _loadStats());
                        }, badgeCount: _receivedCount),
                        _buildQuickAction(context, 'Sent', TablerIcons.arrow_up_right, const Color(0xFFF3F4F6), Colors.black, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: false))).then((_) => _loadStats());
                        }, badgeCount: _sentCount),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // -- BOTTOM CARD --
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(TablerIcons.chart_bar, size: 20, color: Colors.black),
                              ),
                              const SizedBox(width: 16),
                              const Text('My Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildStatRow('Deals Received', '$_receivedCount', Colors.green),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),
                          _buildStatRow('Deals Sent', '$_sentCount', Colors.blue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}
