import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/models/member.dart';
import 'package:pbn/models/user.dart';

class CreateReferralPage extends StatefulWidget {
  const CreateReferralPage({super.key});

  @override
  State<CreateReferralPage> createState() => _CreateReferralPageState();
}

class _CreateReferralPageState extends State<CreateReferralPage> {
  final _referralService = ReferralService();
  final _chapterService = ChapterService();
  final _authService = AuthService();

  List<Member> _members = [];
  Member? _selectedMember;
  User? _currentUser;

  final _leadNameController = TextEditingController();
  final _leadContactController = TextEditingController();
  final _leadEmailController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _leadNameController.dispose();
    _leadContactController.dispose();
    _leadEmailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      _currentUser = await _authService.getProfile();
      final memberships = await _chapterService.getMyMemberships();
      if (memberships.isNotEmpty) {
        final allMembers =
            await _chapterService.getChapterMembers(memberships.first.chapter.id);
        _members =
            allMembers.where((m) => m.userId != _currentUser?.id).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMembers = false);
  }

  Future<void> _submit() async {
    if (_selectedMember == null) {
      _showError('Please select a member');
      return;
    }
    if (_leadNameController.text.trim().isEmpty) {
      _showError('Please enter lead name');
      return;
    }
    if (_leadContactController.text.trim().isEmpty) {
      _showError('Please enter lead contact');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter referral description');
      return;
    }

    setState(() => _loading = true);
    try {
      await _referralService.createReferral(
        targetUserId: _selectedMember!.userId,
        leadName: _leadNameController.text.trim(),
        leadContact: _leadContactController.text.trim(),
        leadEmail: _leadEmailController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        _showSuccess('Opportunity submitted successfully');
        Navigator.pop(context);
      }
    } catch (_) {
      _showError("Couldn't submit. Try again.");
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
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

  @override
  Widget build(BuildContext context) {
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
          'New Business Opportunity',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _loadingMembers
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              child: _buildAnimated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Generate high-quality business opportunities for your fellow members.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeader('Target Recipient'),
                    _buildMemberDropdown(),
                    const SizedBox(height: 28),
                    _sectionHeader('Lead Contact Info'),
                    _buildContactCard(),
                    const SizedBox(height: 28),
                    _sectionHeader('Opportunity Details'),
                    _buildDescriptionCard(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimated(Widget child) {
    return Animate(
      effects: [
        FadeEffect(duration: 320.ms, curve: Curves.easeOutCubic),
        SlideEffect(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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
  // DROPDOWN — P-4 styled
  // ──────────────────────────────────────────────────────────
  Widget _buildMemberDropdown() {
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
        children: [
          _iconContainer(TablerIcons.user, AppColors.accentBlue),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Member>(
                value: _selectedMember,
                isExpanded: true,
                isDense: false,
                hint: Text(
                  'Select a member…',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                icon: const Icon(
                  TablerIcons.chevron_down,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                items: _members
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          '${m.fullName} (${m.industry})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (m) => setState(() => _selectedMember = m),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CONTACT CARD — P-4 icon-row pattern with hairline dividers
  // ──────────────────────────────────────────────────────────
  Widget _buildContactCard() {
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
          _inputRow(
            controller: _leadNameController,
            icon: TablerIcons.user,
            hint: 'Lead Full Name',
            keyboardType: TextInputType.name,
          ),
          _hairlineDivider(),
          _inputRow(
            controller: _leadContactController,
            icon: TablerIcons.phone,
            hint: 'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          _hairlineDivider(),
          _inputRow(
            controller: _leadEmailController,
            icon: TablerIcons.mail,
            hint: 'Email (Optional)',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _inputRow({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _iconContainer(icon, AppColors.accentBlue),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
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

  Widget _hairlineDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
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
  // DESCRIPTION CARD — textarea card, no icon prefix
  // ──────────────────────────────────────────────────────────
  Widget _buildDescriptionCard() {
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
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        minLines: 5,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Explain how the recipient can help this lead…',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: 1.5,
          ),
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SUBMIT BUTTON — gold gradient pill, radius 16
  // ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
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
                  'SUBMIT OPPORTUNITY',
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
