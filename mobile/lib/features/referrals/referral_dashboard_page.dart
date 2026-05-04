import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class ReferralDashboardPage extends StatefulWidget {
  final bool isEmbedded;
  const ReferralDashboardPage({super.key, this.isEmbedded = false});

  @override
  State<ReferralDashboardPage> createState() => _ReferralDashboardPageState();
}

class _ReferralDashboardPageState extends State<ReferralDashboardPage> {
  final _service = ReferralService();
  bool _loading = true;
  int _receivedCount = 0;
  int _sentCount = 0;

  static const String _invitationText = '''Hi 👋, I’d like to introduce you to Prime Business Network (PBN) — a modern, technology-driven business growth ecosystem that helps entrepreneurs grow through structured, measurable results. It offers industry exclusivity (one member per category) and a digital system to track business opportunities and real business results.

Key Benefits:
• Exclusive industry seat (only one member per category)
• Consistent, high-quality business creation flow
• Digital tracking of business opportunities and ROI
• Increased visibility among trusted professionals
• Access to charter member benefits, events & training

By joining, you become part of a strong ecosystem built on reliable partnerships and accountable business creation, helping your business scale with purpose. Learn more and secure your spot here: https://primebusiness.network/''';

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
      debugPrint('Error loading received referrals: $e');
    }

    try {
      final sent = await _service.getGivenReferrals();
      sCount = sent.length;
    } catch (e) {
      debugPrint('Error loading sent referrals: $e');
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
    final totalReferrals = _receivedCount + _sentCount;

    Widget body = _loading
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
                      const Text('Total Business Opportunities',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Text('$totalReferrals',
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
                      label: 'New Opportunity',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReferralPage())).then((_) => _loadStats()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('BUSINESS ACTIVITY',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),

                // -- PERFORMANCE ROWS --
                _buildTrackerCard(
                  title: 'Received Opportunities',
                  count: _receivedCount,
                  icon: TablerIcons.arrow_down_left,
                  color: const Color(0xFF15803D),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: true))).then((_) => _loadStats()),
                ),
                const SizedBox(height: 12),
                _buildTrackerCard(
                  title: 'Given Opportunities',
                  count: _sentCount,
                  icon: TablerIcons.arrow_up_right,
                  color: const Color(0xFF0369A1),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: false))).then((_) => _loadStats()),
                ),

                const SizedBox(height: 32),
                _buildInviteCard(),
                const SizedBox(height: 20),
                _buildInstructionCard(),
              ],
            ),
          );

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          'Business Creation', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)
        ),
        actions: const [
          PbnAppBarActions(),
        ],
      ),
      body: body,
    );
  }

  Widget _buildInviteCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(TablerIcons.user_plus, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('GROW YOUR NETWORK', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Invite Quality Professionals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            'Copy our professional template to invite business owners in your network to join PBN.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _invitationText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invitation copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              },
              icon: const Icon(TablerIcons.copy, size: 18),
              label: const Text('COPY INVITATION TEXT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
              ),
            ),
          ),
        ],
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
                  Text('Track business growth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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
            'High business creation flow helps you climb the leaderboard and unlock premium rewards. Always update the ROI once an opportunity is closed successfully.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
