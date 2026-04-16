import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbn/core/constants/app_colors.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String supportPhone = '+94777140803';
    const String supportEmail = 'info@primebusines.network';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HELP CENTER',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text('Support & Feedback',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header Split Card ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                // Top Dark Header
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How can we help you?',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Our average response time is under 1 hour during business hours.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
                    ],
                  ),
                ),
                // Bottom Quick Contact
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _contactAction(TablerIcons.phone, 'Call Us', Colors.blue, () {
                        _launchUrl('tel:$supportPhone');
                      }),
                      const SizedBox(width: 12),
                      _contactAction(TablerIcons.brand_whatsapp, 'WhatsApp', Colors.green, () {
                        // WhatsApp wa.me links should not include the '+' prefix
                        _launchUrl('https://wa.me/94777140803');
                      }),
                      const SizedBox(width: 12),
                      _contactAction(TablerIcons.mail, 'Email', Colors.pink, () {
                        _launchUrl('mailto:$supportEmail');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('FREQUENTLY ASKED',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),

          _buildFaqTile('How do I update my industry code?', 'You can edit your industry details from the Member settings or by contacting your chapter administrator.'),
          _buildFaqTile('When is the next physical meetup?', 'Physical Flagship meetups occur once every month. Details are posted in the "Schedule" tab.'),
          _buildFaqTile('How are conversion rates calculated?', 'The dashboard tracks successful referrals divided by the total deals given by your business.'),
          
          const SizedBox(height: 32),
          const Text('SUPPORT CATEGORIES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          
          _categoryTile(TablerIcons.database, 'Technical Support', 'Report bugs or app issues'),
          _categoryTile(TablerIcons.credit_card, 'Billing & Payments', 'Membership fees & receipts'),
          _categoryTile(TablerIcons.trending_up, 'Growth Support', 'How to get more referrals'),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _contactAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(TablerIcons.chevron_right, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}
