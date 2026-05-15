import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/features/referrals/widgets/referral_status_style.dart';
import 'package:pbn/models/referral.dart';

class MyReferralsPage extends StatefulWidget {
  final bool isReceived;
  const MyReferralsPage({super.key, required this.isReceived});

  @override
  State<MyReferralsPage> createState() => _MyReferralsPageState();
}

class _MyReferralsPageState extends State<MyReferralsPage> {
  final _service = ReferralService();
  List<Referral> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _referrals = widget.isReceived
          ? await _service.getReceivedReferrals()
          : await _service.getGivenReferrals();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isReceived ? 'Received Opportunities' : 'Given Opportunities';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.5,
          ),
        ),
        actions: const [PbnAppBarActions()],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _loadData,
              child: _referrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _referrals.length,
                      itemBuilder: (context, i) {
                        final delay = (i * 35).clamp(0, 280);
                        return Animate(
                          effects: [
                            FadeEffect(
                              duration: 320.ms,
                              delay: delay.ms,
                              curve: Curves.easeOutCubic,
                            ),
                            SlideEffect(
                              begin: const Offset(0, 0.10),
                              end: Offset.zero,
                              duration: 320.ms,
                              delay: delay.ms,
                              curve: Curves.easeOutCubic,
                            ),
                          ],
                          child: _buildCard(_referrals[i]),
                        );
                      },
                    ),
            ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // P-10 EMPTY STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final headline = widget.isReceived
        ? 'No referrals yet'
        : "You haven't given any referrals yet";
    final sub = widget.isReceived
        ? "When members refer leads to you, they'll appear here."
        : "Refer a lead to a fellow member to start growing your chapter's business.";

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: const Icon(
              TablerIcons.briefcase_off,
              size: 44,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (!widget.isReceived) ...[
          const SizedBox(height: 24),
          Center(child: _buildEmptyStateCta()),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEmptyStateCta() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReferralPage()),
        );
        if (mounted) _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.goldGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.goldGlow,
        ),
        child: Text(
          '+ NEW OPPORTUNITY',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // P-5 LIST ITEM CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildCard(Referral ref) {
    final style = referralStatusStyle(ref.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showDetails(ref);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: style.fg.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: style.fg.withValues(alpha: 0.20)),
                  ),
                  child: Icon(
                    TablerIcons.briefcase,
                    color: style.fg,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.leadName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isReceived
                            ? 'From: ${ref.fromUser.fullName}'
                            : 'To: ${ref.targetUser.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _statusPill(style),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      TablerIcons.chevron_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _formatDate(ref.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(ReferralStatusStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            style.label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: style.fg,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  void _showDetails(Referral ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      builder: (context) => _ReferralDetailsSheet(
        referral: ref,
        isReceived: widget.isReceived,
        onUpdate: _loadData,
      ),
    );
  }
}

class _ReferralDetailsSheet extends StatefulWidget {
  final Referral referral;
  final bool isReceived;
  final VoidCallback onUpdate;
  const _ReferralDetailsSheet({
    required this.referral,
    required this.isReceived,
    required this.onUpdate,
  });

  @override
  State<_ReferralDetailsSheet> createState() => _ReferralDetailsSheetState();
}

class _ReferralDetailsSheetState extends State<_ReferralDetailsSheet> {
  final _service = ReferralService();
  final _descriptionController = TextEditingController();
  final _roiController = TextEditingController();
  late String _selectedStatus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.referral.status;
    if (widget.referral.actualValue != null) {
      _roiController.text =
          widget.referral.actualValue!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _roiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final textRoi = _roiController.text.trim();
      final roiValue = textRoi.isNotEmpty ? double.tryParse(textRoi) : null;
      await _service.updateStatus(
        widget.referral.id,
        _selectedStatus,
        description: _descriptionController.text.trim(),
        actualValue: roiValue,
      );
      widget.onUpdate();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update status',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.referral;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(ref),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadInfoCard(ref),
                    const SizedBox(height: 24),
                    _sectionHeader('Opportunity Description'),
                    const SizedBox(height: 12),
                    _buildDescriptionCard(ref),
                    if (widget.isReceived) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('Update Business Status'),
                      const SizedBox(height: 12),
                      _buildStatusGrid(),
                      const SizedBox(height: 14),
                      _buildIconInput(
                        controller: _roiController,
                        icon: TablerIcons.coin,
                        tint: AppColors.accent,
                        hint: 'LKR amount',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _buildIconInput(
                        controller: _descriptionController,
                        icon: TablerIcons.edit,
                        tint: AppColors.accentBlue,
                        hint: 'Internal update notes…',
                        maxLines: 3,
                      ),
                    ],
                    if (ref.history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('History'),
                      const SizedBox(height: 12),
                      _buildHistoryTimeline(ref.history),
                    ],
                    if (widget.isReceived) ...[
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // P-2 SHEET HEADER — primaryGradient + gold ambient blob + drag handle
  // ──────────────────────────────────────────────────────────
  Widget _buildHeader(Referral ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEAD DETAILS',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ref.leadName,
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            TablerIcons.x,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Row(
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // LEAD INFO CARD — P-4 single card with hairline dividers
  // ──────────────────────────────────────────────────────────
  Widget _buildLeadInfoCard(Referral ref) {
    final hasEmail = ref.leadEmail != null && ref.leadEmail!.isNotEmpty;
    final roiValue = ref.actualValue ?? 0;
    final roiText = 'LKR ${NumberFormat('#,##0').format(roiValue)}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        children: [
          _infoRow(
            icon: TablerIcons.phone,
            tint: AppColors.accentBlue,
            label: 'CONTACT NUMBER',
            value: ref.leadContact,
          ),
          if (hasEmail) ...[
            _hairlineDivider(),
            _infoRow(
              icon: TablerIcons.mail,
              tint: AppColors.accentBlue,
              label: 'LEAD EMAIL',
              value: ref.leadEmail!,
            ),
          ],
          _hairlineDivider(),
          _infoRow(
            icon: TablerIcons.coin,
            tint: AppColors.accent,
            label: 'REALIZED ROI',
            value: roiText,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _iconContainer(icon, tint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hairlineDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _iconContainer(IconData icon, Color tint) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }

  // ──────────────────────────────────────────────────────────
  // DESCRIPTION CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildDescriptionCard(Referral ref) {
    final hasDesc =
        ref.description != null && ref.description!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Text(
        hasDesc ? ref.description! : 'No description provided',
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: hasDesc ? AppColors.text : AppColors.textMuted,
          height: 1.5,
          fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STATUS GRID — uses shared helper + canonical labels
  // ──────────────────────────────────────────────────────────
  Widget _buildStatusGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: referralStatusOrder.map((value) {
        final style = referralStatusStyle(value);
        final isSelected = _selectedStatus == value;
        return GestureDetector(
          onTap: () => setState(() => _selectedStatus = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? style.fg.withValues(alpha: 0.20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? style.fg.withValues(alpha: 0.40)
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              style.label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? style.fg : AppColors.text,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ICON-ROW INPUT — P-4 pattern
  // ──────────────────────────────────────────────────────────
  Widget _buildIconInput({
    required TextEditingController controller,
    required IconData icon,
    required Color tint,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 6 : 0),
            child: _iconContainer(icon, tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              minLines: 1,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HISTORY TIMELINE
  // ──────────────────────────────────────────────────────────
  Widget _buildHistoryTimeline(List<ReferralHistory> history) {
    final sorted = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: List.generate(sorted.length, (i) {
        final entry = sorted[i];
        final isLast = i == sorted.length - 1;
        return _historyItem(entry, isLast: isLast);
      }),
    );
  }

  Widget _historyItem(ReferralHistory entry, {required bool isLast}) {
    final newStyle = referralStatusStyle(entry.newStatus);
    final oldLabel = entry.oldStatus.isEmpty
        ? null
        : referralStatusStyle(entry.oldStatus).label;
    final newLabel = newStyle.label;
    final primary = oldLabel == null
        ? 'Created as $newLabel'
        : 'Status changed from $oldLabel → $newLabel';

    final hasNote =
        entry.description != null && entry.description!.trim().isNotEmpty;
    final secondary = hasNote
        ? '${_relativeTime(entry.createdAt)} · ${entry.description!.trim()}'
        : _relativeTime(entry.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: newStyle.dot,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: newStyle.fg.withValues(alpha: 0.30)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondary,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return '$h ${h == 1 ? 'hour' : 'hours'} ago';
      }
      if (diff.inDays < 7) {
        final d = diff.inDays;
        return '$d ${d == 1 ? 'day' : 'days'} ago';
      }
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  // ──────────────────────────────────────────────────────────
  // SAVE BUTTON — gold gradient pill
  // ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
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
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'SAVE UPDATES',
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
