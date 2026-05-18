import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/core/services/club_service.dart';
import 'package:pbn/core/services/community_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/horizontal_club.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _service = CommunityService();
  final _appService = ApplicationService();
  final _clubService = ClubService();

  final _contentCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _contentFocus = FocusNode();

  String _postType = 'general'; // general | lead | rfp
  String _visibility = 'chapter'; // chapter | network | club
  DateTime? _deadline;
  String? _selectedIndustryId;
  String? _selectedClubId;

  List<IndustryCategory> _industries = [];
  List<HorizontalClub> _clubs = [];
  bool _submitting = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _budgetCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _appService.getIndustryCategories(),
        _clubService.listClubs(),
      ]);
      if (mounted) {
        setState(() {
          _industries = results[0] as List<IndustryCategory>;
          _clubs = results[1] as List<HorizontalClub>;
          _fetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _selectDeadline() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Theme the date picker to the navy + gold palette.
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              textStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (_contentCtrl.text.trim().isEmpty) return false;
    if (_postType != 'general') {
      // Leads & RFPs need an industry target so they reach the right people.
      if (_selectedIndustryId == null) return false;
    }
    if (_visibility == 'club' && _selectedClubId == null) return false;
    return true;
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty || _submitting) return;
    HapticFeedback.selectionClick();

    setState(() => _submitting = true);
    try {
      final newPost = await _service.createPost(
        content,
        postType: _postType,
        visibility: _visibility,
        budgetRange: _postType != 'general' ? _budgetCtrl.text : null,
        deadline: _postType != 'general' ? _deadline : null,
        targetIndustryId:
            _postType != 'general' ? _selectedIndustryId : null,
        targetClubId: _visibility == 'club' ? _selectedClubId : null,
      );
      if (mounted) Navigator.pop(context, newPost);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share post. Please try again.',
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
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(TablerIcons.x, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Post',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _postTypeSubtitle(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      body: sk.Skeletonizer(
        enabled: _fetching,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: _buildForm(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _postTypeSubtitle() {
    switch (_postType) {
      case 'lead':
        return 'Sharing an active opportunity';
      case 'rfp':
        return 'Requesting proposals';
      case 'general':
      default:
        return 'Share with your chapter';
    }
  }

  Widget _buildForm() {
    final sections = <Widget>[
      _sectionHeader('Post Type'),
      const SizedBox(height: 10),
      _buildTypeCards(),
      const SizedBox(height: 22),
      _sectionHeader('Content'),
      const SizedBox(height: 10),
      _buildContentField(),
      if (_postType != 'general') ...[
        const SizedBox(height: 22),
        _sectionHeader('Opportunity Details'),
        const SizedBox(height: 10),
        _buildOpportunityCard(),
      ],
      const SizedBox(height: 22),
      _sectionHeader('Audience'),
      const SizedBox(height: 10),
      _buildVisibilityChips(),
      if (_visibility == 'club') ...[
        const SizedBox(height: 10),
        _buildClubPicker(),
      ],
      const SizedBox(height: 22),
      _buildAttachmentTeaser(),
      const SizedBox(height: 32),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
  // POST TYPE CARDS — three palette-tinted picker cards
  // ──────────────────────────────────────────────────────────
  Widget _buildTypeCards() {
    return Row(
      children: [
        Expanded(
          child: _typeCard(
            value: 'general',
            label: 'General',
            sub: 'Share update',
            icon: TablerIcons.news,
            tint: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeCard(
            value: 'lead',
            label: 'Lead',
            sub: 'Open opportunity',
            icon: TablerIcons.flame,
            tint: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeCard(
            value: 'rfp',
            label: 'RFP',
            sub: 'Request quotes',
            icon: TablerIcons.clipboard_list,
            tint: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _typeCard({
    required String value,
    required String label,
    required String sub,
    required IconData icon,
    required Color tint,
  }) {
    final selected = _postType == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: tint.withValues(alpha: 0.08),
        highlightColor: tint.withValues(alpha: 0.04),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _postType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.18),
                      tint.withValues(alpha: 0.06),
                    ],
                  )
                : const LinearGradient(colors: AppColors.surfaceGradient),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.7),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? null : AppColors.shadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tint.withValues(alpha: selected ? 0.30 : 0.18),
                      tint.withValues(alpha: selected ? 0.10 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tint.withValues(alpha: selected ? 0.40 : 0.22),
                  ),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? tint : AppColors.text,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CONTENT FIELD
  // ──────────────────────────────────────────────────────────
  Widget _buildContentField() {
    final length = _contentCtrl.text.length;
    const maxLen = 1000;
    final hasFocus = _contentFocus.hasFocus;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFocus
              ? AppColors.accent.withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.7),
          width: hasFocus ? 1.4 : 1,
        ),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _contentCtrl,
            focusNode: _contentFocus,
            onTap: () => setState(() {}),
            maxLines: 8,
            minLines: 5,
            maxLength: maxLen,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
              height: 1.55,
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              hintText: _contentHint(),
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.55,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$length / $maxLen',
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: length >= maxLen
                  ? AppColors.error
                  : AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _contentHint() {
    switch (_postType) {
      case 'lead':
        return 'Describe the lead — who, what, when. The more context, '
            'the better members can respond.';
      case 'rfp':
        return 'What are you looking for? Include scope, deliverables, '
            'and the kind of partner you want to hear from.';
      case 'general':
      default:
        return "What's on your mind? Share an update, a win, or "
            'something on your roadmap.';
    }
  }

  // ──────────────────────────────────────────────────────────
  // OPPORTUNITY DETAILS — budget + deadline + industry
  // ──────────────────────────────────────────────────────────
  Widget _buildOpportunityCard() {
    return Container(
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
      child: Column(
        children: [
          _inputRow(
            icon: TablerIcons.coin,
            tint: AppColors.accent,
            label: 'BUDGET / VALUE',
            child: TextField(
              controller: _budgetCtrl,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'e.g. LKR 50,000 – 150,000',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _hairline(),
          _inputRow(
            icon: TablerIcons.calendar_event,
            tint: AppColors.accentBlue,
            label: 'DEADLINE',
            child: GestureDetector(
              onTap: _selectDeadline,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'Pick a date'
                          : DateFormat('EEEE, MMM d, yyyy')
                              .format(_deadline!),
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: _deadline == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: _deadline == null
                            ? AppColors.textMuted
                            : AppColors.text,
                      ),
                    ),
                  ),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(TablerIcons.x,
                            size: 14, color: AppColors.textMuted),
                      ),
                    ),
                  const Icon(TablerIcons.chevron_right,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          _hairline(),
          _inputRow(
            icon: TablerIcons.briefcase,
            tint: AppColors.accentBlue,
            label: 'TARGET INDUSTRY',
            isRequired: true,
            child: _paletteDropdown<String>(
              hint: 'Select an industry',
              value: _selectedIndustryId,
              items: _industries
                  .map((i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(i.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedIndustryId = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required Color tint,
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.18),
                  tint.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tint.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hairline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _paletteDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        isDense: true,
        value: value,
        icon: const Icon(TablerIcons.chevron_down,
            size: 16, color: AppColors.textMuted),
        hint: Text(
          hint,
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        dropdownColor: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // VISIBILITY
  // ──────────────────────────────────────────────────────────
  Widget _buildVisibilityChips() {
    return Row(
      children: [
        Expanded(
          child: _visibilityCard(
            value: 'chapter',
            label: 'My Chapter',
            sub: 'Members only',
            icon: TablerIcons.building_community,
            tint: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _visibilityCard(
            value: 'network',
            label: 'Network',
            sub: 'All chapters',
            icon: TablerIcons.world,
            tint: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _visibilityCard(
            value: 'club',
            label: 'Club',
            sub: 'Specific club',
            icon: TablerIcons.users_group,
            tint: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _visibilityCard({
    required String value,
    required String label,
    required String sub,
    required IconData icon,
    required Color tint,
  }) {
    final selected = _visibility == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: tint.withValues(alpha: 0.08),
        highlightColor: tint.withValues(alpha: 0.04),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _visibility = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.18),
                      tint.withValues(alpha: 0.06),
                    ],
                  )
                : const LinearGradient(colors: AppColors.surfaceGradient),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.7),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? null : AppColors.shadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? tint : AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? tint : AppColors.text,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubPicker() {
    return Container(
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
      child: _inputRow(
        icon: TablerIcons.users_group,
        tint: AppColors.accent,
        label: 'HORIZONTAL CLUB',
        isRequired: true,
        child: _paletteDropdown<String>(
          hint: _clubs.isEmpty
              ? 'No clubs available yet'
              : 'Select a horizontal club',
          value: _selectedClubId,
          items: _clubs
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
              .toList(),
          onChanged: _clubs.isEmpty
              ? null
              : (v) => setState(() => _selectedClubId = v),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ATTACHMENT TEASER — replaces the prior grey "Coming Soon" card
  // ──────────────────────────────────────────────────────────
  Widget _buildAttachmentTeaser() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textMuted.withValues(alpha: 0.14),
                  AppColors.textMuted.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.18)),
            ),
            child: const Icon(TablerIcons.photo,
                size: 15, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Images',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Image attachments coming soon.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.22)),
            ),
            child: Text(
              'SOON',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BOTTOM CTA BAR — sticky gold "PUBLISH POST" + ghost cancel
  // ──────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _ghostCancel()),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _publishCta(),
          ),
        ],
      ),
    );
  }

  Widget _ghostCancel() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _submitting ? null : () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CANCEL',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publishCta() {
    final enabled = _canSubmit;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? _submit : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.textMuted.withValues(alpha: 0.45),
                      AppColors.textMuted.withValues(alpha: 0.30),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: _submitting
                ? const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'PUBLISHING…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ]
                : [
                    const Icon(TablerIcons.send,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      _publishLabel(),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  String _publishLabel() {
    switch (_postType) {
      case 'lead':
        return 'PUBLISH LEAD';
      case 'rfp':
        return 'PUBLISH RFP';
      case 'general':
      default:
        return 'PUBLISH POST';
    }
  }
}
