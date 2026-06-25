import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/core/widgets/pbn_bottom_sheet.dart';
import 'package:pbn/features/members/member_card.dart';
import 'package:pbn/features/referrals/create_referral_page.dart';
import 'package:pbn/models/member.dart';

enum _MemberScope { myChapter, global }

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String _search = '';
  String? _selectedIndustry;
  _MemberScope _scope = _MemberScope.myChapter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MemberProvider>();
      if (provider.members.isEmpty) {
        provider.fetchMembers();
      } else {
        provider.fetchMembers(background: true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // DATA HELPERS
  // ──────────────────────────────────────────────────────────
  List<Member> _scoped(List<Member> all) {
    return _scope == _MemberScope.myChapter
        ? all.where((m) => m.isSameChapter).toList()
        : all.where((m) => !m.isSameChapter).toList();
  }

  List<Member> _filtered(List<Member> source) {
    return source.where((m) {
      final matchesSearch = _search.isEmpty ||
          m.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          m.industry.toLowerCase().contains(_search.toLowerCase()) ||
          m.company.toLowerCase().contains(_search.toLowerCase());
      final matchesIndustry =
          _selectedIndustry == null || m.industry == _selectedIndustry;
      return matchesSearch && matchesIndustry;
    }).toList();
  }

  bool get _hasActiveFilters => _selectedIndustry != null || _search.isNotEmpty;

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedIndustry = null;
      _search = '';
    });
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final allMembers = provider.members;
    final myChapter = allMembers.where((m) => m.isSameChapter).toList();
    final globalMembers = allMembers.where((m) => !m.isSameChapter).toList();
    final scoped = _scoped(allMembers);
    final visible = _filtered(scoped);

    // Industries are sourced from the **current scope** so the chip set
    // matches what the user is actually browsing.
    final industries = scoped.map((m) => m.industry).toSet().toList()..sort();

    final verifiedCount =
        allMembers.where((m) => m.verificationLevel != 'none').length;
    final chapterCount = allMembers
        .where((m) => m.chapterName != null && m.chapterName!.isNotEmpty)
        .map((m) => m.chapterName!)
        .toSet()
        .length;

    final loading = provider.loading && allMembers.isEmpty;

    final sections = <Widget>[
      _buildHero(myChapterCount: myChapter.length, globalCount: globalMembers.length),
      const SizedBox(height: 14),
      _buildStatStrip(
        myChapterCount: myChapter.length,
        chapterCount: chapterCount,
        verifiedCount: verifiedCount,
      ),
      const SizedBox(height: 22),
      _buildScopeToggle(
          myChapterCount: myChapter.length, globalCount: globalMembers.length),
      const SizedBox(height: 16),
      _buildSearchBar(),
      if (industries.isNotEmpty) ...[
        const SizedBox(height: 10),
        _buildIndustryChips(industries),
      ],
      const SizedBox(height: 18),
      _sectionHeader(
        _scope == _MemberScope.myChapter
            ? 'Members In Your Chapter'
            : 'Global Directory',
        trailing: '${visible.length}',
      ),
      if (provider.error != null && allMembers.isEmpty)
        _buildErrorState(provider.error!)
      else if (visible.isEmpty && !loading)
        _buildEmptyState()
      else
        ...visible.map(
          (m) => MemberCard(
            member: m,
            onTap: () => _showMemberDetailBottomSheet(m),
          ),
        ),
      const SizedBox(height: 100),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: loading,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: RefreshIndicator(
          onRefresh: () => provider.fetchMembers(),
          color: AppColors.accent,
          child: CustomScrollView(
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
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP BAR (P-13)
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
        'Network Directory',
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
  // SECTION HEADER (P-1)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? trailing}) {
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
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.accent.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.28)),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO CARD (P-2)
  // ──────────────────────────────────────────────────────────
  Widget _buildHero({required int myChapterCount, required int globalCount}) {
    final activeCount = _scope == _MemberScope.myChapter
        ? myChapterCount
        : globalCount;

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
            color: AppColors.accent.withValues(alpha: 0.10),
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
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
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
                        child: const Icon(TablerIcons.users_group,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'YOUR NETWORK',
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
                    _scope == _MemberScope.myChapter
                        ? '$activeCount in your chapter'
                        : '$activeCount across the network',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 24,
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
                  const SizedBox(height: 6),
                  Text(
                    _scope == _MemberScope.myChapter
                        ? 'Members of your home chapter you can connect with directly.'
                        : 'Members from other chapters across PBN.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _scope = _scope == _MemberScope.myChapter
                                ? _MemberScope.global
                                : _MemberScope.myChapter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.goldGradient),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.goldGlow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _scope == _MemberScope.myChapter
                                    ? TablerIcons.world
                                    : TablerIcons.building_community,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _scope == _MemberScope.myChapter
                                    ? 'BROWSE GLOBAL'
                                    : 'BACK TO MY CHAPTER',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STAT STRIP (P-3)
  // ──────────────────────────────────────────────────────────
  Widget _buildStatStrip({
    required int myChapterCount,
    required int chapterCount,
    required int verifiedCount,
  }) {
    Widget chip(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: color, size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(TablerIcons.user_circle, AppColors.accentBlue,
            '$myChapterCount', 'My Chapter'),
        const SizedBox(width: 8),
        chip(TablerIcons.building_community, AppColors.accent,
            '$chapterCount', 'Chapters'),
        const SizedBox(width: 8),
        chip(TablerIcons.discount_check, AppColors.success,
            '$verifiedCount', 'Verified'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // SCOPE TOGGLE (gold underline tabs — P-9, inline variant)
  // ──────────────────────────────────────────────────────────
  Widget _buildScopeToggle({
    required int myChapterCount,
    required int globalCount,
  }) {
    Widget tab(_MemberScope scope, String label, int count) {
      final isActive = _scope == scope;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _scope = scope);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: isActive
                              ? AppColors.text
                              : AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 2,
                    width: isActive ? 52 : 0,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.goldGradient,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          tab(_MemberScope.myChapter, 'My Chapter', myChapterCount),
          tab(_MemberScope.global, 'Global', globalCount),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR (P-6)
  // ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search by name, industry or company…',
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(TablerIcons.search,
              color: AppColors.textMuted, size: 18),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(TablerIcons.x,
                      color: AppColors.textMuted, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: GoogleFonts.dmSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INDUSTRY CHIPS (P-7)
  // ──────────────────────────────────────────────────────────
  Widget _buildIndustryChips(List<String> industries) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _chip(null, 'All'),
          ...industries.map((i) => _chip(i, i)),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final isSelected = _selectedIndustry == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndustry = value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: AppColors.goldGradient)
                  : const LinearGradient(
                      colors: AppColors.surfaceGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.55)
                    : AppColors.border.withValues(alpha: 0.7),
                width: isSelected ? 1.2 : 1,
              ),
              boxShadow: isSelected
                  ? AppColors.goldGlow
                  : AppColors.shadowSm,
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.text,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE (P-10)
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final hasFilters = _hasActiveFilters;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(TablerIcons.user_search,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters ? 'No matches in this view' : 'No members yet',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try removing a filter or switching to the other tab.'
                : 'Members will appear here as the network grows.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.goldGradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.goldGlow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(TablerIcons.refresh,
                          color: Colors.white, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'CLEAR FILTERS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ERROR STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                size: 28, color: AppColors.error),
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load members",
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.read<MemberProvider>().fetchMembers(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.goldGlow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.refresh,
                        color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'TRY AGAIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // MEMBER DETAIL BOTTOM SHEET (premium navy hero + tinted rows)
  // ──────────────────────────────────────────────────────────
  void _showMemberDetailBottomSheet(Member member) {
    showPbnBottomSheet(
      context,
      builder: (ctx) {
        return PbnBottomSheet(
          child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailHero(member),
                      const SizedBox(height: 18),
                      _detailLabel('About'),
                      const SizedBox(height: 8),
                      _detailInfoCard([
                        _premiumInfoRow(
                          icon: TablerIcons.building_community,
                          iconColor: AppColors.accent,
                          label: 'CHAPTER',
                          value: member.chapterName ?? 'Unknown',
                        ),
                        _hairlineDivider(),
                        _premiumInfoRow(
                          icon: TablerIcons.briefcase,
                          iconColor: AppColors.accentBlue,
                          label: 'INDUSTRY',
                          value: member.industry,
                        ),
                        _hairlineDivider(),
                        _premiumInfoRow(
                          icon: TablerIcons.building_store,
                          iconColor: AppColors.accent,
                          label: 'COMPANY',
                          value: member.company,
                        ),
                      ]),
                      _buildBusinessPortfolioSection(member),
                      if (member.isSameChapter) ...[
                        const SizedBox(height: 18),
                        _detailLabel('Contact'),
                        const SizedBox(height: 8),
                        _detailInfoCard([
                          _premiumInfoRow(
                            icon: TablerIcons.phone,
                            iconColor: AppColors.accentBlue,
                            label: 'PHONE',
                            value: member.phoneNumber ?? 'Not shared',
                          ),
                          _hairlineDivider(),
                          _premiumInfoRow(
                            icon: TablerIcons.mail,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'EMAIL',
                            value: member.email ?? 'Not shared',
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _detailActionButton(
                                icon: TablerIcons.phone,
                                label: 'CALL',
                                tint: AppColors.accentBlue,
                                onTap: member.phoneNumber == null
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        launchUrl(Uri.parse(
                                            'tel:${member.phoneNumber}'));
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _detailActionButton(
                                icon: TablerIcons.brand_whatsapp,
                                label: 'WHATSAPP',
                                tint: AppColors.success,
                                onTap: member.phoneNumber == null
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        final phone = member.phoneNumber!
                                            .replaceAll(
                                                RegExp(r'\D'), '');
                                        launchUrl(
                                          Uri.parse('https://wa.me/$phone'),
                                          mode:
                                              LaunchMode.externalApplication,
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _detailActionButton(
                                icon: TablerIcons.mail,
                                label: 'EMAIL',
                                tint: AppColors.accent,
                                onTap: member.email == null
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        launchUrl(Uri.parse(
                                            'mailto:${member.email}'));
                                      },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.border
                                    .withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(TablerIcons.lock,
                                    color: AppColors.textMuted, size: 16),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Contact details are only visible to members of the same chapter.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateReferralPage(initialMember: member),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.goldGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.goldGlow,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(TablerIcons.send, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'SEND OPPORTUNITY',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildDetailHero(Member member) {
    final tierColor = _tierColor(member.verificationLevel);
    final hasTier = member.verificationLevel.toLowerCase() != 'none';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 170,
                height: 170,
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppColors.goldGlow,
                    ),
                    child: CachedAvatar(
                      imageUrl: member.profilePhoto,
                      initials: member.initials,
                      size: 72,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.primary,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.fullName,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.company,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (member.isSameChapter)
                              _glassPill(
                                icon: TablerIcons.discount_check_filled,
                                label: 'SAME CHAPTER',
                                color: AppColors.accent,
                              ),
                            if (hasTier)
                              _glassPill(
                                icon: TablerIcons.discount_check_filled,
                                label: member.verificationLevel.toUpperCase(),
                                color: tierColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailInfoCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _hairlineDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _premiumInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.18),
                  iconColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: iconColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailActionButton({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      tint.withValues(alpha: 0.22),
                      tint.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppColors.textMuted.withValues(alpha: 0.10),
                      AppColors.textMuted.withValues(alpha: 0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? tint.withValues(alpha: 0.32)
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: enabled ? tint : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: enabled ? tint : AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tierColor(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E7EB);
      case 'gold':
        return AppColors.accent;
      case 'silver':
        return AppColors.textMuted;
      case 'verified':
        return AppColors.accentBlue;
      default:
        return AppColors.accent;
    }
  }

  Widget _buildBusinessPortfolioSection(Member member) {
    final hasLogo = member.businessLogoUrl != null && member.businessLogoUrl!.isNotEmpty;
    final hasDesc = member.businessDescription != null && member.businessDescription!.isNotEmpty;
    final hasWeb = member.businessWebsite != null && member.businessWebsite!.isNotEmpty;
    final hasAddr = member.businessAddress != null && member.businessAddress!.isNotEmpty;
    final hasEst = member.businessEstablishedYear != null && member.businessEstablishedYear!.isNotEmpty;
    final hasBr = member.businessBrNumber != null && member.businessBrNumber!.isNotEmpty;
    final hasBrochure = member.businessBrochureUrl != null && member.businessBrochureUrl!.isNotEmpty;
    final hasMaps = member.businessGoogleMapsUrl != null && member.businessGoogleMapsUrl!.isNotEmpty;
    
    final hasSocials = (member.businessLinkedinUrl != null && member.businessLinkedinUrl!.isNotEmpty) ||
                       (member.businessFacebookUrl != null && member.businessFacebookUrl!.isNotEmpty) ||
                       (member.businessInstagramUrl != null && member.businessInstagramUrl!.isNotEmpty);

    if (!hasLogo && !hasDesc && !hasWeb && !hasAddr && !hasEst && !hasBr && !hasBrochure && !hasSocials) {
      return const SizedBox.shrink();
    }

    final baseUrl = ApiClient().dio.options.baseUrl.split('/api')[0];
    final fullLogoUrl = hasLogo
        ? (member.businessLogoUrl!.startsWith('http')
            ? member.businessLogoUrl!
            : '$baseUrl${member.businessLogoUrl}')
        : null;
    final fullBrochureUrl = hasBrochure
        ? (member.businessBrochureUrl!.startsWith('http')
            ? member.businessBrochureUrl!
            : '$baseUrl${member.businessBrochureUrl}')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _detailLabel('Business Portfolio'),
        const SizedBox(height: 8),
        Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fullLogoUrl != null) ...[
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: AppColors.shadowSm,
                      image: DecorationImage(
                        image: NetworkImage(fullLogoUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (hasDesc) ...[
                Text(
                  member.businessDescription!,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _hairlineDivider(),
                const SizedBox(height: 10),
              ],
              if (hasEst) ...[
                _portfolioDetailRow(
                  icon: TablerIcons.calendar_time,
                  iconColor: Colors.amber,
                  label: 'ESTABLISHED IN',
                  value: member.businessEstablishedYear!,
                ),
                const SizedBox(height: 10),
              ],
              if (hasBr) ...[
                _portfolioDetailRow(
                  icon: TablerIcons.file_text,
                  iconColor: Colors.blueGrey,
                  label: 'BUSINESS REGISTRATION NO',
                  value: member.businessBrNumber!,
                ),
                const SizedBox(height: 10),
              ],
              if (hasWeb) ...[
                _portfolioDetailRow(
                  icon: TablerIcons.world,
                  iconColor: AppColors.accentBlue,
                  label: 'WEBSITE',
                  value: member.businessWebsite!,
                  onTap: () => launchUrl(Uri.parse(member.businessWebsite!), mode: LaunchMode.externalApplication),
                ),
                const SizedBox(height: 10),
              ],
              if (hasAddr) ...[
                _portfolioDetailRow(
                  icon: TablerIcons.map_pin,
                  iconColor: Colors.redAccent,
                  label: 'ADDRESS',
                  value: member.businessAddress!,
                  onTap: hasMaps
                      ? () => launchUrl(Uri.parse(member.businessGoogleMapsUrl!), mode: LaunchMode.externalApplication)
                      : null,
                  actionWidget: hasMaps
                      ? const Icon(TablerIcons.map, color: Colors.redAccent, size: 16)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
              if (fullBrochureUrl != null) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.file_type_pdf, color: AppColors.accentBlue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Brochure',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fullBrochureUrl.split('/').last,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(fullBrochureUrl), mode: LaunchMode.externalApplication),
                        child: const Text(
                          'DOWNLOAD',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (hasSocials) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (member.businessLinkedinUrl != null && member.businessLinkedinUrl!.isNotEmpty)
                      _socialIconButton(
                        icon: TablerIcons.brand_linkedin,
                        color: const Color(0xFF0077B5),
                        url: member.businessLinkedinUrl!,
                      ),
                    if (member.businessFacebookUrl != null && member.businessFacebookUrl!.isNotEmpty)
                      _socialIconButton(
                        icon: TablerIcons.brand_facebook,
                        color: const Color(0xFF1877F2),
                        url: member.businessFacebookUrl!,
                      ),
                    if (member.businessInstagramUrl != null && member.businessInstagramUrl!.isNotEmpty)
                      _socialIconButton(
                        icon: TablerIcons.brand_instagram,
                        color: const Color(0xFFE1306C),
                        url: member.businessInstagramUrl!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _portfolioDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? actionWidget,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? AppColors.accentBlue : AppColors.text,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (actionWidget != null) ...[
              const SizedBox(width: 8),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _socialIconButton({
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
