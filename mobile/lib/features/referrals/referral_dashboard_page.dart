import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';

class ReferralDashboardPage extends StatelessWidget {
  const ReferralDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Referrals', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(TablerIcons.arrows_exchange, size: 250, color: Colors.white.withOpacity(0.05)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GROW YOUR NETWORK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildOption(
                    context,
                    title: 'New Referral',
                    subtitle: 'Connect a lead with a trusted member',
                    icon: TablerIcons.plus,
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReferralPage())),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'TRACK PERFORMANCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildOption(
                    context,
                    title: 'Received Referrals',
                    subtitle: 'Manage and update incoming business',
                    icon: TablerIcons.arrow_down_left,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: true))),
                  ),
                  const SizedBox(height: 16),
                  _buildOption(
                    context,
                    title: 'Sent Referrals',
                    subtitle: 'Monitor progress of your shares',
                    icon: TablerIcons.arrow_up_right,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsPage(isReceived: false))),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(TablerIcons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
