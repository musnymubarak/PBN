import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/features/profile/portfolio_edit_page.dart';

class VerificationStatusPage extends StatefulWidget {
  const VerificationStatusPage({super.key});

  @override
  State<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  final _apiClient = ApiClient();

  bool _loading = true;
  bool _submitting = false;

  double _businessValue = 0.0;
  bool _valueMet = false;
  bool _canRequest = false;

  String? _status;
  String? _rejectionReason;
  Map<String, dynamic> _portfolioChecks = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await _apiClient.get('/verification-requests/me/status');
      if (res.data != null && res.data['data'] != null) {
        final data = res.data['data'];
        setState(() {
          _businessValue = (data['business_value'] as num?)?.toDouble() ?? 0.0;
          _valueMet = data['business_value_met'] ?? false;
          _canRequest = data['can_request'] ?? false;
          _status = data['status'];
          _rejectionReason = data['rejection_reason'];
          _portfolioChecks = data['portfolio_checks'] ?? {};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestVerification() async {
    setState(() => _submitting = true);
    try {
      await _apiClient.post('/verification-requests/me/request');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadStatus();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to submit request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Verification Status',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _sectionHeader('Verification Checklist'),
                  _buildChecklistCard(),
                  const SizedBox(height: 32),
                  if (_canRequest) _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    Color color;
    String title;
    String description;

    if (_status == null) {
      icon = TablerIcons.shield_off;
      color = AppColors.textMuted;
      title = 'NOT VERIFIED';
      description = 'Generate LKR 25,000.00 value and complete your business portfolio to request your verification badge.';
    } else if (_status == 'pending') {
      icon = TablerIcons.shield_half;
      color = const Color(0xFFF59E0B);
      title = 'REVIEW PENDING';
      description = 'Your background verification request is currently under review by our Admin Team. We will notify you shortly.';
    } else if (_status == 'approved') {
      icon = TablerIcons.shield_check;
      color = AppColors.success;
      title = 'VERIFIED';
      description = 'Congratulations! Your profile is verified. You are an approved verified network member.';
    } else {
      icon = TablerIcons.shield_x;
      color = AppColors.error;
      title = 'REJECTED';
      description = 'Your verification request was rejected. Please review the reason below, update your profile, and request again.';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppColors.shadowMd,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_status == 'rejected' && _rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REJECTION REASON:',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rejectionReason!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          _checklistRow(
            icon: TablerIcons.coin,
            color: _valueMet ? AppColors.success : AppColors.textMuted,
            title: 'Business Value Generated',
            subtitle: 'LKR ${_businessValue.toStringAsFixed(2)} / LKR 25,000.00',
            isChecked: _valueMet,
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.photo,
            color: (_portfolioChecks['has_logo'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Upload Business Logo',
            subtitle: 'Brand identity image',
            isChecked: _portfolioChecks['has_logo'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.link,
            color: (_portfolioChecks['has_website'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Set Business Website',
            subtitle: 'Company online website',
            isChecked: _portfolioChecks['has_website'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.file_text,
            color: (_portfolioChecks['has_br'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Set Business Registration (BR) Number',
            subtitle: 'Unique legal registration ID',
            isChecked: _portfolioChecks['has_br'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.calendar_time,
            color: (_portfolioChecks['has_established'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Set Established Year',
            subtitle: 'Year of starting operation',
            isChecked: _portfolioChecks['has_established'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.map_pin,
            color: (_portfolioChecks['has_address'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Set Business Address & Location',
            subtitle: 'Physical site address',
            isChecked: _portfolioChecks['has_address'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.file_type_pdf,
            color: (_portfolioChecks['has_brochure'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Upload Company Profile Brochure',
            subtitle: 'PDF overview presentation',
            isChecked: _portfolioChecks['has_brochure'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
          const Divider(height: 1, indent: 60),
          _checklistRow(
            icon: TablerIcons.brand_linkedin,
            color: (_portfolioChecks['has_social'] == true) ? AppColors.success : AppColors.textMuted,
            title: 'Link Social Networks',
            subtitle: 'LinkedIn, Facebook or Instagram profile link',
            isChecked: _portfolioChecks['has_social'] == true,
            onTapFix: () => _navigateToEditPortfolio(),
          ),
        ],
      ),
    );
  }

  Widget _checklistRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isChecked,
    VoidCallback? onTapFix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isChecked)
            const Icon(TablerIcons.circle_check_filled, color: AppColors.success, size: 20)
          else if (onTapFix != null)
            TextButton(
              onPressed: onTapFix,
              child: Text(
                'FIX',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            const Icon(TablerIcons.circle, color: AppColors.textMuted, size: 20)
        ],
      ),
    );
  }

  Future<void> _navigateToEditPortfolio() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PortfolioEditPage()),
    );
    _loadStatus();
  }

  Widget _buildSubmitButton() {
    return InkWell(
      onTap: _submitting ? null : _requestVerification,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.goldGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.goldGlow,
        ),
        child: Center(
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'REQUEST VERIFICATION BADGE',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
