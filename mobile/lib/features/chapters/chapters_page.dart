import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/districts.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/core/widgets/pbn_bottom_sheet.dart';
import 'package:pbn/features/members/members_page.dart';
import 'package:pbn/models/chapter.dart';

class ChaptersPage extends StatefulWidget {
  const ChaptersPage({super.key});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  final _service = ChapterService();
  final _searchCtrl = TextEditingController();

  List<Chapter> _chapters = [];
  bool _loading = true;
  String? _selectedDistrict;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() => _loading = true);
    try {
      _chapters = await _service.listChapters();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ──────────────────────────────────────────────────────────
  // DATA HELPERS
  // ──────────────────────────────────────────────────────────
  List<Chapter> _applyFilters(List<Chapter> source) {
    return source.where((c) {
      final matchesDistrict =
          _selectedDistrict == null || c.district == _selectedDistrict;
      final matchesSearch = _search.isEmpty ||
          c.name.toLowerCase().contains(_search.toLowerCase()) ||
          c.district.toLowerCase().contains(_search.toLowerCase());
      return matchesDistrict && matchesSearch;
    }).toList();
  }

  Chapter? _homeChapter(String? userChapterId) {
    if (userChapterId == null) return null;
    for (final c in _chapters) {
      if (c.id == userChapterId) return c;
    }
    return null;
  }

  Set<String> get _representedDistricts =>
      _chapters.map((c) => c.district).toSet();

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final home = _homeChapter(user?.chapterId);
    final filtered = _applyFilters(_chapters);
    // Exclude home chapter from explore list so it isn't shown twice.
    final exploreChapters =
        filtered.where((c) => home == null || c.id != home.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sk.Skeletonizer(
        enabled: _loading,
        enableSwitchAnimation: true,
        effect: sk.ShimmerEffect(
          baseColor: AppColors.surfaceAlt,
          highlightColor: Colors.white.withValues(alpha: 0.9),
          duration: const Duration(milliseconds: 1400),
        ),
        child: RefreshIndicator(
          onRefresh: _loadChapters,
          color: AppColors.accent,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: _buildAnimatedSections(home, exploreChapters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedSections(
      Chapter? home, List<Chapter> exploreChapters) {
    final sections = <Widget>[
      _buildHeroStats(),
      const SizedBox(height: 22),
      if (home != null) ...[
        _sectionHeader('Your Home Chapter', accent: 'YOU'),
        _buildHomeChapterCard(home),
        const SizedBox(height: 22),
      ],
      _sectionHeader(
        home == null ? 'Discover Chapters' : 'Explore the Network',
        trailing: _chapters.isEmpty
            ? null
            : '${exploreChapters.length} CHAPTER${exploreChapters.length == 1 ? '' : 'S'}',
      ),
      _buildSearchBar(),
      const SizedBox(height: 12),
      _buildDistrictFilter(),
      const SizedBox(height: 16),
      if (exploreChapters.isEmpty)
        _buildEmptyState()
      else
        ...exploreChapters.map((c) => _buildChapterCard(c, isHome: false)),
      const SizedBox(height: 32),
    ];

    return List.generate(sections.length, (i) {
      final delayMs = (i * 35).clamp(0, 280);
      return sections[i]
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
          .slideY(
              begin: 0.10,
              end: 0,
              duration: 320.ms,
              curve: Curves.easeOutCubic);
    });
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
        'Global Presence',
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
  Widget _sectionHeader(String title, {String? trailing, String? accent}) {
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
          if (accent != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.goldGradient),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                accent,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          if (trailing != null && accent == null)
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
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO STATS — premium navy with ambient gold glow
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroStats() {
    final total = _chapters.length;
    final districts = _representedDistricts.length;
    final active = _chapters.where((c) => c.isActive).length;

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
                        child: const Icon(TablerIcons.world_pin,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'NETWORK OVERVIEW',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _statBlock('$total', 'Chapters'),
                      _verticalDivider(),
                      _statBlock('$districts', 'Districts'),
                      _verticalDivider(),
                      _statBlock('$active', 'Active'),
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

  Widget _statBlock(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.05,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR
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
          hintText: 'Search by chapter name…',
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
  // DISTRICT FILTER CHIPS
  // ──────────────────────────────────────────────────────────
  Widget _buildDistrictFilter() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _filterChip(null, 'All', countOverride: _chapters.length),
          ...sriLankaDistricts.map((d) {
            final count = _chapters.where((c) => c.district == d).length;
            if (count == 0) return const SizedBox.shrink();
            return _filterChip(d, d, countOverride: count);
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label, {int? countOverride}) {
    final isSelected = _selectedDistrict == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDistrict = value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
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
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppColors.shadowSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
                if (countOverride != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.85)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '$countOverride',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HOME CHAPTER CARD — premium navy with full feature set
  // ──────────────────────────────────────────────────────────
  Widget _buildHomeChapterCard(Chapter c) {
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
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.goldGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.goldGlow,
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(TablerIcons.building_community,
                              color: AppColors.accent, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.name,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(TablerIcons.map_pin,
                                    size: 12, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  c.district,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (c.description != null && c.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      c.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _glassChip(
                        icon: TablerIcons.discount_check_filled,
                        label: 'HOME CHAPTER',
                        color: AppColors.accent,
                      ),
                      if (c.meetingSchedule != null &&
                          c.meetingSchedule!.trim().isNotEmpty)
                        _glassChip(
                          icon: TablerIcons.calendar_event,
                          label: c.meetingSchedule!.toUpperCase(),
                          color: Colors.white,
                        ),
                      _glassChip(
                        icon: c.isActive
                            ? TablerIcons.circle_check_filled
                            : TablerIcons.circle_off,
                        label: c.isActive ? 'ACTIVE' : 'INACTIVE',
                        color: c.isActive
                            ? const Color(0xFF34D399)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ghostButton(
                          icon: TablerIcons.users_group,
                          label: 'VIEW MEMBERS',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MembersPage()),
            );
                          },
                        ),
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

  Widget _glassChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border:
            Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
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

  Widget _ghostButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.goldGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.goldGlow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // CHAPTER CARD (explore list)
  // ──────────────────────────────────────────────────────────
  Widget _buildChapterCard(Chapter c, {required bool isHome}) {
    final districtColor = _districtAccent(c.district);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            _showChapterDetails(c);
          },
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gold-ringed icon
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.goldSoftGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(TablerIcons.building_community,
                            color: AppColors.primary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.text,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!c.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'INACTIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: districtColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(TablerIcons.map_pin,
                                    size: 10, color: districtColor),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.district,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: districtColor,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                          if (c.description != null &&
                              c.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              c.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (c.meetingSchedule != null &&
                    c.meetingSchedule!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.18),
                              AppColors.accent.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: 0.28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(TablerIcons.calendar_event,
                                size: 10, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              c.meetingSchedule!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(TablerIcons.chevron_right,
                            size: 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
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
            child: const Icon(TablerIcons.building_off,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            _search.isNotEmpty
                ? 'No matching chapters'
                : 'No chapters in this district',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _search.isNotEmpty
                ? 'Try a different keyword or clear the search.'
                : 'Try clearing the district filter to see all chapters.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CHAPTER DETAILS — bottom sheet (unique view, not a member list)
  // ──────────────────────────────────────────────────────────
  void _showChapterDetails(Chapter c) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isMyChapter = user?.chapterId == c.id;
    // Members can only belong to one chapter, so the join CTA only makes
    // sense for prospects with no chapter yet.
    final canApply = user?.chapterId == null && c.isActive;

    showPbnBottomSheet(
      context,
      builder: (ctx) {
        return PbnBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.goldGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.goldGlow,
                      ),
                      child: const Icon(TablerIcons.building_community,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.name,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(TablerIcons.map_pin,
                                  size: 11, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                c.district,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Description
              if (c.description != null && c.description!.isNotEmpty) ...[
                _detailLabel('About'),
                const SizedBox(height: 6),
                Text(
                  c.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Quick facts
              _detailLabel('Quick Facts'),
              const SizedBox(height: 8),
              if (c.meetingSchedule != null &&
                  c.meetingSchedule!.trim().isNotEmpty)
                _factRow(
                  icon: TablerIcons.calendar_event,
                  label: 'Meeting',
                  value: c.meetingSchedule!,
                  tint: AppColors.accent,
                ),
              _factRow(
                icon: TablerIcons.map_pin,
                label: 'District',
                value: c.district,
                tint: AppColors.accentBlue,
              ),
              _factRow(
                icon: c.isActive
                    ? TablerIcons.circle_check
                    : TablerIcons.circle_off,
                label: 'Status',
                value: c.isActive ? 'Active' : 'Inactive',
                tint: c.isActive ? AppColors.success : AppColors.textMuted,
                isLast: true,
              ),
              // Action — context-aware:
              //   • Home chapter → quick path to its members
              //   • Prospect (no chapter yet) → apply to join this chapter
              //   • Existing member viewing another chapter → no CTA
              //     (one-chapter-per-member rule)
              if (isMyChapter) ...[
                const SizedBox(height: 20),
                _ghostButton(
                  icon: TablerIcons.users_group,
                  label: 'VIEW MEMBERS',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MembersPage()),
                    );
                  },
                ),
              ] else if (canApply) ...[
                const SizedBox(height: 20),
                _ghostButton(
                  icon: TablerIcons.send,
                  label: 'APPLY TO JOIN',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/apply');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.textMuted,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _factRow({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.18),
                  tint.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tint.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 13, color: tint),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────
  Color _districtAccent(String district) {
    // Deterministic palette-derived tint so each district has identity.
    final palette = [
      AppColors.accent,
      AppColors.accentBlue,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    final idx = district.hashCode.abs() % palette.length;
    return palette[idx];
  }
}
