import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/event_service.dart';
import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';
import 'package:pbn/features/events/event_detail_page.dart';
import 'package:pbn/models/event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  final _service = EventService();
  final _chapterService = ChapterService();

  late final TabController _tabController;

  List<Event> _events = [];
  bool _loading = true;
  bool _loadError = false;
  String? _currentUserId;

  // Each tab owns its scroll position so the desktop Scrollbar never
  // sees two positions on the same PrimaryScrollController during a
  // tab swipe.
  final _upcomingScroll = ScrollController();
  final _finishedScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upcomingScroll.dispose();
    _finishedScroll.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      if (_currentUserId == null) {
        final user = await AuthService().getProfile();
        _currentUserId = user.id;
      }

      // Filter to events belonging to chapters the user is in — same
      // business rule as before.
      final memberships = await _chapterService.getMyMemberships();
      final myChapterIds = memberships.map((m) => m.chapter.id).toSet();

      final results = await _service.listEvents();
      final myEvents = results
          .where((e) => myChapterIds.contains(e.chapterId))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

      if (mounted) {
        setState(() {
          _events = myEvents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // PLACEHOLDER IMAGES
  // Same fallback Unsplash sources as before — used only when an event
  // has no image_url. Keeps the visual quality high on empty data.
  // ──────────────────────────────────────────────────────────
  String _placeholderImage(Event event) {
    if (event.eventType == 'flagship') {
      return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=800';
    }
    final t = event.title.toLowerCase();
    if (t.contains('connect') || t.contains('network')) {
      return 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=800';
    }
    return 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=800';
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = _events
        .where((e) => DateTime.parse(e.startAt).isAfter(now))
        .toList();
    final finished = _events
        .where((e) => DateTime.parse(e.startAt).isBefore(now))
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt)); // newest finished first

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 60,
            floating: true,
            snap: true,
            title: Text(
              'Meetings & Events',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
            actions: const [PbnAppBarActions()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.text,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorSize: TabBarIndicatorSize.label,
                      // P-9 gold underline (was navy).
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                            color: AppColors.accent, width: 3),
                        borderRadius:
                            BorderRadius.all(Radius.circular(2)),
                        insets: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                      unselectedLabelStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                      overlayColor:
                          WidgetStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(WidgetState.pressed)) {
                            return AppColors.accent
                                .withValues(alpha: 0.06);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return AppColors.accent
                                .withValues(alpha: 0.04);
                          }
                          return null;
                        },
                      ),
                      tabs: const [
                        Tab(text: 'UPCOMING'),
                        Tab(text: 'FINISHED'),
                      ],
                    ),
                    Container(height: 1, color: AppColors.borderLight),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: sk.Skeletonizer(
          enabled: _loading,
          enableSwitchAnimation: true,
          effect: sk.ShimmerEffect(
            baseColor: AppColors.surfaceAlt,
            highlightColor: Colors.white.withValues(alpha: 0.9),
            duration: const Duration(milliseconds: 1400),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTab(
                events: _loading ? _skeletonEvents() : upcoming,
                scroll: _upcomingScroll,
                isUpcoming: true,
              ),
              _buildTab(
                events: _loading ? _skeletonEvents() : finished,
                scroll: _finishedScroll,
                isUpcoming: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stand-in records used while [_loading] so the Skeletonizer has
  /// realistically-shaped placeholders instead of empty white.
  List<Event> _skeletonEvents() {
    return List.generate(
      3,
      (i) => Event(
        id: 'skeleton-$i',
        title: 'Chapter Connect Meeting — Q4 Strategy',
        description:
            'Quarterly chapter session covering ROI updates, new member intros, and the roadmap.',
        startAt: DateTime.now()
            .add(Duration(days: 3 + i * 4))
            .toIso8601String(),
        chapterId: 'skeleton',
        eventType: i.isEven ? 'physical' : 'virtual',
        location: 'Cinnamon Grand Colombo',
        meetingLink: 'https://meet.example/chapter',
        rsvps: const [],
        fee: 2500,
      ),
    );
  }

  Widget _buildTab({
    required List<Event> events,
    required ScrollController scroll,
    required bool isUpcoming,
  }) {
    final now = DateTime.now();
    final thisMonth = _events
        .where((e) {
          final dt = DateTime.parse(e.startAt);
          return dt.year == now.year && dt.month == now.month;
        })
        .length;
    final attending = _events
        .where((e) =>
            _currentUserId != null &&
            e.getRsvpStatus(_currentUserId!) == 'going')
        .length;

    final sections = <Widget>[
      if (_loadError) ...[
        _buildErrorBanner(),
        const SizedBox(height: 14),
      ],
      _buildHeroCard(events: events, isUpcoming: isUpcoming),
      const SizedBox(height: 14),
      _buildStatStrip(
        total: events.length,
        thisMonth: thisMonth,
        attending: attending,
        isUpcoming: isUpcoming,
      ),
      const SizedBox(height: 24),
      _sectionHeader(
        isUpcoming ? 'Upcoming Meetings' : 'Past Meetings',
        trailing: events.isEmpty ? null : '${events.length} TOTAL',
      ),
      if (events.isEmpty && !_loading)
        _buildEmptyState(isUpcoming
            ? 'No upcoming meetings scheduled.'
            : 'No past meetings on record yet.')
      else
        ...events.map((e) => _buildEventCard(e, isUpcoming: isUpcoming)),
      const SizedBox(height: 32),
    ];

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.primary,
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
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
  // HERO CARD (P-2)
  // Upcoming → "NEXT MEETING" + next event title + countdown chip.
  // Finished → "MEETINGS COMPLETED" + count.
  // ──────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required List<Event> events,
    required bool isUpcoming,
  }) {
    final eyebrow = isUpcoming ? 'NEXT MEETING' : 'MEETINGS COMPLETED';
    String headline;
    String subline;
    Widget? chip;

    if (isUpcoming) {
      if (events.isEmpty) {
        headline = 'No meetings scheduled';
        subline = 'New chapter meetings will appear here as soon as your '
            'chapter leads publish them.';
      } else {
        final next = events.first;
        final dt = DateTime.parse(next.startAt).toLocal();
        headline = next.title;
        subline = DateFormat('EEEE, MMM d • h:mm a').format(dt);

        final diff = dt.difference(DateTime.now());
        final label = _countdownLabel(diff);
        if (label != null) chip = _heroChip(label);
      }
    } else {
      headline = events.isEmpty ? '0' : '${events.length}';
      subline = events.isEmpty
          ? 'You haven\'t attended any meetings yet.'
          : 'Total meetings hosted by your chapter so far.';
    }

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
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUpcoming
                        ? TablerIcons.calendar_event
                        : TablerIcons.history,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headline,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: isUpcoming ? 22 : 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isUpcoming ? -0.5 : -2,
                      height: 1.05,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: isUpcoming ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subline,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  if (chip != null) ...[
                    const SizedBox(height: 16),
                    chip,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _countdownLabel(Duration diff) {
    if (diff.isNegative) return null;
    if (diff.inDays >= 1) {
      final d = diff.inDays;
      return d == 1 ? 'TOMORROW' : 'IN $d DAYS';
    }
    final h = diff.inHours;
    if (h >= 1) return h == 1 ? 'IN 1 HOUR' : 'IN $h HOURS';
    final m = diff.inMinutes;
    if (m > 0) return 'IN $m MIN';
    return 'STARTING NOW';
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.clock_hour_4,
              color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // STAT STRIP (P-3)
  // ──────────────────────────────────────────────────────────
  Widget _buildStatStrip({
    required int total,
    required int thisMonth,
    required int attending,
    required bool isUpcoming,
  }) {
    Widget tile(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
                      label,
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
        tile(
          isUpcoming ? TablerIcons.calendar_event : TablerIcons.history,
          AppColors.accentBlue,
          '$total',
          isUpcoming ? 'UPCOMING' : 'PAST',
        ),
        const SizedBox(width: 8),
        tile(TablerIcons.calendar_month, AppColors.accent, '$thisMonth',
            'THIS MONTH'),
        const SizedBox(width: 8),
        tile(TablerIcons.discount_check, AppColors.success, '$attending',
            'ATTENDING'),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // ERROR BANNER
  // ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.10),
            AppColors.warning.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.18),
                  AppColors.warning.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.22)),
            ),
            child: const Icon(TablerIcons.alert_triangle,
                color: AppColors.warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Couldn't load meetings",
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Pull down to refresh or tap retry.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                HapticFeedback.selectionClick();
                _loadEvents();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.30)),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warning,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // EMPTY STATE (P-10)
  // ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(TablerIcons.calendar_off,
                size: 36, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            'Nothing here yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
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
  // EVENT CARD — premium image card with navy date badge,
  // P-8 type pill, gold fee pill, and a tinted info row footer.
  // ──────────────────────────────────────────────────────────
  Widget _buildEventCard(Event event, {required bool isUpcoming}) {
    final startDt = DateTime.parse(event.startAt).toLocal();
    final day = DateFormat('dd').format(startDt);
    final month = DateFormat('MMM').format(startDt).toUpperCase();
    final timeLabel = DateFormat('EEE, MMM d • h:mm a').format(startDt);

    final fullImageUrl = event.imageUrl != null
        ? (event.imageUrl!.startsWith('http')
            ? event.imageUrl!
            : '${ApiConfig.staticUrl}${event.imageUrl}')
        : null;
    final imageUrl = fullImageUrl ?? _placeholderImage(event);

    final isVirtual = event.eventType == 'virtual';
    final isFlagship = event.eventType == 'flagship';

    // Type pill color follows design-system §8:
    //   virtual → accentBlue (contact / digital), physical → success
    //   (active in-real-world), flagship → gold (premium).
    final Color typeTint = isFlagship
        ? AppColors.accent
        : (isVirtual ? AppColors.accentBlue : AppColors.success);
    final String typeLabel = isFlagship
        ? 'FLAGSHIP'
        : (isVirtual ? 'ONLINE' : 'IN-PERSON');
    final IconData typeIcon = isFlagship
        ? TablerIcons.crown
        : (isVirtual ? TablerIcons.video : TablerIcons.map_pin);

    final myStatus = _currentUserId == null
        ? null
        : event.getRsvpStatus(_currentUserId!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.surfaceGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7)),
              boxShadow: AppColors.shadowMd,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover + overlays ─────────────────────
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(
                            color: AppColors.surfaceAlt,
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.10),
                                  AppColors.primary.withValues(alpha: 0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(TablerIcons.photo_off,
                                  size: 36,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.25)),
                            ),
                          ),
                        ),
                        // Bottom gradient overlay for legibility of any
                        // overlaid chip.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary
                                      .withValues(alpha: 0.45),
                                ],
                                stops: const [0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // ── Date badge top-left ──────────────
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _dateBadge(day: day, month: month),
                        ),
                        // ── Type pill top-right ──────────────
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _typePill(
                            label: typeLabel,
                            tint: typeTint,
                            icon: typeIcon,
                          ),
                        ),
                        // ── Fee pill bottom-right ───────────
                        if (event.fee > 0)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: _feePill(event.fee),
                          ),
                      ],
                    ),
                  ),

                  // ── Body ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time row
                        Row(
                          children: [
                            const Icon(TablerIcons.clock,
                                size: 13, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                timeLabel,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          event.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Location row
                        _detailRow(
                          icon: isVirtual
                              ? TablerIcons.link
                              : TablerIcons.map_pin,
                          tint: AppColors.accentBlue,
                          value: isVirtual
                              ? (event.meetingLink ?? 'Virtual meeting')
                              : (event.location ?? 'To be announced'),
                        ),
                        if (event.description != null &&
                            event.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            event.description!,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 14),
                        // Footer: RSVP count + view-details CTA
                        Row(
                          children: [
                            _rsvpChip(event.rsvps.length, myStatus),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  isUpcoming
                                      ? 'VIEW DETAILS'
                                      : 'VIEW SUMMARY',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(TablerIcons.chevron_right,
                                    size: 14, color: AppColors.accent),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBadge({required String day, required String month}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            month,
            style: GoogleFonts.dmSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            day,
            style: GoogleFonts.dmSans(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typePill({
    required String label,
    required Color tint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.40), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: tint,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feePill(double fee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.ticket, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            'LKR ${NumberFormat('#,##0').format(fee)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color tint,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
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
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _rsvpChip(int count, String? myStatus) {
    // Reflect the user's own RSVP if known, otherwise show the headcount.
    final isGoing = myStatus == 'going';
    final tint = isGoing ? AppColors.success : AppColors.textSecondary;

    final label = isGoing
        ? "You're going · $count"
        : '$count interested';
    final icon =
        isGoing ? TablerIcons.discount_check : TablerIcons.users_group;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: tint),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: tint,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
