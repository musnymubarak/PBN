import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/event_service.dart';
import 'package:pbn/models/event.dart';
import 'package:pbn/features/payments/payment_service.dart';
import 'package:pbn/core/widgets/custom_alert.dart';
import 'package:pbn/features/payments/payment_webview_page.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _eventService = EventService();
  bool _isLoading = false;
  late Event _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _refreshEventDataSilently();
  }

  Future<void> _refreshEventDataSilently() async {
    try {
      final events = await _eventService.listEvents();
      final latest = events.firstWhere((e) => e.id == _currentEvent.id);
      if (mounted) setState(() => _currentEvent = latest);
    } catch (_) {
      // Silent — local copy stays in place.
    }
  }

  Future<void> _handleRSVP(String status) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.updateRSVP(_currentEvent.id, status);

      final updated = await _eventService.listEvents();
      final fresh = updated.firstWhere((e) => e.id == _currentEvent.id);

      if (!mounted) return;
      setState(() {
        _currentEvent = fresh;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'going'
                ? 'Requested successfully!'
                : 'Meeting ignored.',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor:
              status == 'going' ? AppColors.success : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (status == 'not_going' && mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status. Please try again.',
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

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(_currentEvent.startAt).toLocal();
    final endTime = _currentEvent.endAt != null
        ? DateTime.parse(_currentEvent.endAt!).toLocal()
        : null;
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    final rsvpStatus = _currentEvent.getRsvpStatus(userId);

    final sections = <Widget>[
      _buildIdentityRow(),
      const SizedBox(height: 16),
      _buildTitleBlock(),
      const SizedBox(height: 22),
      _sectionHeader('Meeting Details'),
      const SizedBox(height: 10),
      _buildInfoCard(startTime, endTime),
      const SizedBox(height: 22),
      if ((_currentEvent.description ?? '').trim().isNotEmpty) ...[
        _sectionHeader('About this Meeting'),
        const SizedBox(height: 10),
        _buildDescriptionCard(),
        const SizedBox(height: 22),
      ],
      _sectionHeader('RSVP Pulse'),
      const SizedBox(height: 10),
      _buildRsvpCard(rsvpStatus),
      const SizedBox(height: 140), // clear sticky bottom bar
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHero(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
      bottomNavigationBar: _buildBottomActions(rsvpStatus),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HERO (SliverAppBar) — full-width image, navy fade, gold fee
  // ──────────────────────────────────────────────────────────
  Widget _buildHero() {
    final fullImageUrl = _currentEvent.imageUrl != null
        ? (_currentEvent.imageUrl!.startsWith('http')
            ? _currentEvent.imageUrl!
            : '${ApiConfig.staticUrl}${_currentEvent.imageUrl}')
        : null;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      surfaceTintColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _circleIconButton(
          icon: TablerIcons.arrow_left,
          onTap: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (fullImageUrl != null)
              CachedNetworkImage(
                imageUrl: fullImageUrl,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  color: AppColors.surfaceAlt,
                ),
                errorWidget: (ctx, url, err) => _placeholderImage(),
              )
            else
              _placeholderImage(),

            // Navy fade from bottom so the title/CTA chips overlaid at
            // the page edges read against any image.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.30),
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Gold fee badge anchored bottom-right of the hero — used
            // only when the event actually charges a fee.
            if (_currentEvent.fee > 0)
              Positioned(
                bottom: 18,
                right: 18,
                child: _feePill(_currentEvent.fee),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.20), width: 0.8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          TablerIcons.calendar_event,
          size: 80,
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
    );
  }

  Widget _feePill(double fee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.ticket, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Text(
            'LKR ${NumberFormat('#,##0').format(fee)}',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // IDENTITY ROW — type pill matching the list page
  // ──────────────────────────────────────────────────────────
  Widget _buildIdentityRow() {
    final isVirtual = _currentEvent.eventType == 'virtual';
    final isFlagship = _currentEvent.eventType == 'flagship';
    final Color tint = isFlagship
        ? AppColors.accent
        : (isVirtual ? AppColors.accentBlue : AppColors.success);
    final String label = isFlagship
        ? 'FLAGSHIP'
        : (isVirtual ? 'ONLINE' : 'IN-PERSON');
    final IconData icon = isFlagship
        ? TablerIcons.crown
        : (isVirtual ? TablerIcons.video : TablerIcons.map_pin);

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: tint.withValues(alpha: 0.35), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: tint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 11, color: tint),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: tint,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // TITLE BLOCK — DM Sans heading + day-of-week summary chip
  // ──────────────────────────────────────────────────────────
  Widget _buildTitleBlock() {
    final dt = DateTime.parse(_currentEvent.startAt).toLocal();
    final dayLabel = DateFormat('EEEE • h:mm a').format(dt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentEvent.title,
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.7,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(TablerIcons.clock,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              dayLabel,
              style: GoogleFonts.dmSans(
                color: AppColors.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
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
  // INFO CARD — date / location / link / fee rows (P-4)
  // ──────────────────────────────────────────────────────────
  Widget _buildInfoCard(DateTime start, DateTime? end) {
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(start);
    final timeLabel = end != null
        ? '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}'
        : DateFormat('h:mm a').format(start);

    final rows = <Widget>[
      _infoRow(
        icon: TablerIcons.calendar_event,
        tint: AppColors.accent,
        label: 'DATE & TIME',
        value: '$dateLabel\n$timeLabel',
      ),
    ];

    if ((_currentEvent.location ?? '').trim().isNotEmpty) {
      rows.add(_hairline());
      rows.add(_infoRow(
        icon: TablerIcons.map_pin,
        tint: AppColors.accentBlue,
        label: 'LOCATION',
        value: _currentEvent.location!,
        actionIcon: TablerIcons.directions,
        onAction: () => _openMaps(_currentEvent.location!),
      ));
    }

    if ((_currentEvent.meetingLink ?? '').trim().isNotEmpty) {
      rows.add(_hairline());
      rows.add(_infoRow(
        icon: TablerIcons.video,
        tint: AppColors.accentBlue,
        label: 'VIRTUAL MEETING',
        value: _currentEvent.meetingLink!,
        actionIcon: TablerIcons.external_link,
        onAction: () => _openLink(_currentEvent.meetingLink!),
      ));
    }

    if (_currentEvent.fee > 0) {
      rows.add(_hairline());
      rows.add(_infoRow(
        icon: TablerIcons.ticket,
        tint: AppColors.accent,
        label: 'REGISTRATION FEE',
        value:
            'LKR ${NumberFormat('#,##0').format(_currentEvent.fee)} per attendee',
      ));
    }

    return Container(
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
      child: Column(children: rows),
    );
  }

  Widget _hairline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.1,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAction?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: tint.withValues(alpha: 0.22)),
                    ),
                    child: Icon(actionIcon, size: 14, color: tint),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String location) async {
    final url = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(location)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map.')),
      );
    }
  }

  Future<void> _openLink(String link) async {
    var normalized = link;
    if (!normalized.startsWith('http')) {
      normalized = 'https://$normalized';
    }
    final url = Uri.parse(normalized);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // DESCRIPTION CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Text(
        _currentEvent.description!,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          height: 1.6,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // RSVP PULSE CARD — navy hero-style with three real metrics:
  // Going / Total RSVPs / Your Status. Replaces the prior fake
  // "Waitlist —" / "Availability Open" placeholders.
  // ──────────────────────────────────────────────────────────
  Widget _buildRsvpCard(String? myStatus) {
    final going = _currentEvent.confirmedRsvpsCount;
    final total = _currentEvent.rsvps.length;

    final String myLabel;
    final Color myTint;
    if (myStatus == 'going') {
      myLabel = 'Going';
      myTint = AppColors.success;
    } else if (myStatus == 'requested') {
      myLabel = 'Pending';
      myTint = AppColors.warning;
    } else if (myStatus == 'not_going') {
      myLabel = 'Ignored';
      myTint = AppColors.textMuted;
    } else {
      myLabel = '—';
      myTint = AppColors.textMuted;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.20),
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
                  Expanded(
                    child: _rsvpStat(
                      icon: TablerIcons.discount_check,
                      value: '$going',
                      label: 'GOING',
                      tint: AppColors.success,
                    ),
                  ),
                  _rsvpDivider(),
                  Expanded(
                    child: _rsvpStat(
                      icon: TablerIcons.users_group,
                      value: '$total',
                      label: 'RESPONSES',
                      tint: AppColors.accent,
                    ),
                  ),
                  _rsvpDivider(),
                  Expanded(
                    child: _rsvpStat(
                      icon: TablerIcons.user,
                      value: myLabel,
                      label: 'YOUR STATUS',
                      tint: myTint,
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

  Widget _rsvpDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  Widget _rsvpStat({
    required IconData icon,
    required String value,
    required String label,
    required Color tint,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: tint, size: 18),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ──────────────────────────────────────────────────────────
  Widget _buildBottomActions(String? rsvpStatus) {
    final isGoing = rsvpStatus == 'going';
    final isRequested = rsvpStatus == 'requested';
    final isNotGoing = rsvpStatus == 'not_going';

    Widget content;
    if (isGoing) {
      content = _statusBanner(
        icon: TablerIcons.discount_check,
        tint: AppColors.success,
        title: "YOU'RE REGISTERED",
        sub: 'See you at the meeting.',
      );
    } else if (isRequested) {
      content = _statusBanner(
        icon: TablerIcons.clock,
        tint: AppColors.warning,
        title: 'WAITING FOR APPROVAL',
        sub: 'Your chapter lead will confirm shortly.',
      );
    } else {
      content = Row(
        children: [
          Expanded(
            flex: 2,
            child: _primaryCta(),
          ),
          const SizedBox(width: 10),
          Expanded(child: _ignoreButton(isNotGoing)),
        ],
      );
    }

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
      child: content,
    );
  }

  Widget _statusBanner({
    required IconData icon,
    required Color tint,
    required String title,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.14),
            tint.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withValues(alpha: 0.22),
                  tint.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tint.withValues(alpha: 0.30)),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: tint,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta() {
    final feeLabel = _currentEvent.fee > 0
        ? ' • LKR ${NumberFormat('#,##0').format(_currentEvent.fee)}'
        : '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading
            ? null
            : () async {
                HapticFeedback.selectionClick();
                if (_currentEvent.fee > 0) {
                  setState(() => _isLoading = true);
                  try {
                    final res = await PaymentService().initiatePayment(
                      paymentType: 'meeting_fee',
                      amount: _currentEvent.fee,
                      eventId: _currentEvent.id,
                    );
                    final paymentPageUrl = res['payment_url'];
                    final paymentId = res['payment_id'];
                    
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    
                    final reqId = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentWebViewPage(
                          paymentPageUrl: paymentPageUrl,
                          paymentId: paymentId,
                        ),
                      ),
                    );
                    
                    if (reqId != null) {
                      _refreshEventDataSilently();
                      if (!mounted) return;
                      CustomAlert.show(
                        context,
                        isSuccess: true,
                        title: 'Payment Successful',
                        message: 'Payment successful, waiting for approval.',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      CustomAlert.show(
                        context,
                        isSuccess: false,
                        title: 'Payment Failed',
                        message: 'Failed to initiate payment: ${e.toString()}',
                      );
                    }
                  }
                } else {
                  _handleRSVP('going');
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.goldGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // No Center here — Center expands to its parent's bounded
          // constraints, which made the button fill the entire
          // Scaffold.bottomNavigationBar slot. Row(mainAxisSize.min,
          // mainAxisAlignment.center) sizes to content instead.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: _isLoading
                ? const [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ]
                : [
                    const Icon(TablerIcons.bolt,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'RESERVE SPOT$feeLabel',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _ignoreButton(bool isNotGoing) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading
            ? null
            : () {
                HapticFeedback.selectionClick();
                _handleRSVP('not_going');
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNotGoing
                  ? AppColors.error.withValues(alpha: 0.30)
                  : AppColors.border,
              width: 1,
            ),
          ),
          // Same fix as _primaryCta — see comment there.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isNotGoing ? 'IGNORED' : 'IGNORE',
                style: GoogleFonts.dmSans(
                  color: isNotGoing
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontSize: 12,
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
}
