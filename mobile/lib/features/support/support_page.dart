import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // ── Support contact constants (single source of truth) ────────
  static const String _supportPhone = '+94777140803';
  static const String _whatsappNumber = '94777140803'; // wa.me without '+'
  static const String _supportEmail = 'info@primebusines.network';
  static const String _businessHours = 'Mon – Sat, 9:00 AM – 6:00 PM';

  static const String _facebookUrl =
      'https://www.facebook.com/profile.php?id=61589257288388';
  static const String _linkedinUrl =
      'https://linkedin.com/company/prime-business-network';
  static const String _youtubeUrl =
      'https://www.youtube.com/channel/UCJHWSU9Zag3Y0yBM3DG60Hg';

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

  void _whatsappWithTopic(String topic) {
    HapticFeedback.selectionClick();
    final encoded =
        Uri.encodeComponent('Hi PBN Support, I need help with: $topic');
    _launchUrl('https://wa.me/$_whatsappNumber?text=$encoded');
  }

  void _emailWithTopic(String topic) {
    HapticFeedback.selectionClick();
    final subject = Uri.encodeComponent('[$topic] – PBN App');
    final body = Uri.encodeComponent(
        'Hi PBN Support,\n\nI need help with: $topic.\n\nDetails:\n');
    _launchUrl('mailto:$_supportEmail?subject=$subject&body=$body');
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _buildHeroCard(),
      const SizedBox(height: 22),
      _sectionHeader('Browse by Topic'),
      _categoryTile(
        icon: TablerIcons.bug,
        title: 'Technical Support',
        subtitle: 'Report bugs or app issues by email',
        tint: AppColors.accentBlue,
        onTap: () => _emailWithTopic('Technical Support'),
      ),
      _categoryTile(
        icon: TablerIcons.credit_card,
        title: 'Billing & Payments',
        subtitle: 'View invoices and payment history',
        tint: AppColors.accent,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/payments');
        },
      ),
      _categoryTile(
        icon: TablerIcons.trending_up,
        title: 'Growth Support',
        subtitle: 'Chat with us about more referrals',
        tint: AppColors.success,
        onTap: () => _whatsappWithTopic('Growth Support'),
      ),
      const SizedBox(height: 22),
      _sectionHeader('Frequently Asked'),
      _faqTile(
        question: 'How do I update my industry code?',
        answer:
            'You can edit your industry details from the Member settings or by contacting your chapter administrator.',
      ),
      _faqTile(
        question: 'When is the next physical meetup?',
        answer:
            'Physical Flagship meetups occur once every month. Details are posted in the "Schedule" tab.',
      ),
      _faqTile(
        question: 'How are conversion rates calculated?',
        answer:
            'The dashboard tracks successful referrals divided by the total referrals given by your business.',
      ),
      _faqTile(
        question: 'Can I export my networking data?',
        answer:
            'Currently, all data is maintained securely within the app for a unified experience.',
      ),
      const SizedBox(height: 22),
      _sectionHeader('Follow Us'),
      _buildSocialRow(),
      const SizedBox(height: 24),
      _buildFooterInfo(),
      const SizedBox(height: 32),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.list(
              children: List.generate(sections.length, (i) {
                final delayMs = (i * 35).clamp(0, 280);
                return sections[i]
                    .animate(delay: delayMs.ms)
                    .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                    .slideY(
                        begin: 0.10,
                        end: 0,
                        duration: 320.ms,
                        curve: Curves.easeOutCubic);
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP BAR
  // ──────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      floating: true,
      snap: true,
      title: Text(
        'Support & Feedback',
        style: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
          letterSpacing: -0.5,
        ),
      ),
      actions: const [PbnAppBarActions()],
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (gold bar + bold title)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO CARD — navy gradient with ambient gold glow + contact row
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppColors.goldGlow,
                        ),
                        child: const Icon(TablerIcons.lifebuoy,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SUPPORT CENTER',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: 0.45),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(TablerIcons.bolt,
                                size: 10, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text(
                              'AVG. RESPONSE < 1H',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _heroContactAction(
                        icon: TablerIcons.phone,
                        label: 'Call',
                        tint: AppColors.accentBlue,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _launchUrl('tel:$_supportPhone');
                        },
                      ),
                      const SizedBox(width: 10),
                      _heroContactAction(
                        icon: TablerIcons.brand_whatsapp,
                        label: 'WhatsApp',
                        tint: AppColors.success,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _launchUrl('https://wa.me/$_whatsappNumber');
                        },
                      ),
                      const SizedBox(width: 10),
                      _heroContactAction(
                        icon: TablerIcons.mail,
                        label: 'Email',
                        tint: AppColors.accent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _launchUrl('mailto:$_supportEmail');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroContactAction({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tint.withValues(alpha: 0.45),
                width: 0.9,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tint.withValues(alpha: 0.30),
                        tint.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: tint.withValues(alpha: 0.5)),
                  ),
                  child: Icon(icon, color: tint, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CATEGORY TILE
  // ──────────────────────────────────────────────────────────
  Widget _categoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: tint.withValues(alpha: 0.06),
          highlightColor: tint.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tint.withValues(alpha: 0.18),
                        tint.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color: tint.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, color: tint, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.text,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(TablerIcons.chevron_right,
                      color: AppColors.textMuted, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FAQ TILE — premium expansion with gold chevron when open
  // ──────────────────────────────────────────────────────────
  Widget _faqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: AppColors.accent,
          collapsedIconColor: AppColors.textMuted,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.help_circle,
                size: 15, color: AppColors.accent),
          ),
          title: Text(
            question,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SOCIAL ROW
  // ──────────────────────────────────────────────────────────
  Widget _buildSocialRow() {
    return Row(
      children: [
        _socialTile(
          icon: TablerIcons.brand_facebook,
          label: 'Facebook',
          tint: const Color(0xFF1877F2),
          onTap: () => _launchUrl(_facebookUrl),
        ),
        const SizedBox(width: 10),
        _socialTile(
          icon: TablerIcons.brand_linkedin,
          label: 'LinkedIn',
          tint: const Color(0xFF0A66C2),
          onTap: () => _launchUrl(_linkedinUrl),
        ),
        const SizedBox(width: 10),
        _socialTile(
          icon: TablerIcons.brand_youtube,
          label: 'YouTube',
          tint: const Color(0xFFFF0033),
          onTap: () => _launchUrl(_youtubeUrl),
        ),
      ],
    );
  }

  Widget _socialTile({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.surfaceGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tint.withValues(alpha: 0.18),
                        tint.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: tint.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, color: tint, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FOOTER INFO — business hours + brand line
  // ──────────────────────────────────────────────────────────
  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.clock_hour_4,
                size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BUSINESS HOURS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _businessHours,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
