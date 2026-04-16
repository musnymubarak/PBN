import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/event_service.dart';
import 'package:pbn/models/event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _service = EventService();
  List<Event> _events = [];
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      if (_currentUserId == null) {
        final user = await AuthService().getProfile();
        _currentUserId = user.id;
      }
      _events = await _service.listEvents();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rsvp(String eventId, String status) async {
    try {
      await _service.updateRSVP(eventId, status);
      await _loadEvents(); // Refresh to show updated states
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update RSVP'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating));
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final physicalEvents =
        _events.where((e) => e.eventType == 'flagship').toList();
    final onlineEvents =
        _events.where((e) => e.eventType != 'flagship').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MONTHLY SCHEDULE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text('Events & Meetings',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _events.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    children: [
                      if (physicalEvents.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(TablerIcons.building,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text('Main Physical Meetup',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...physicalEvents.map((e) => _buildPhysicalCard(e)),
                        const SizedBox(height: 24),
                      ],
                      if (onlineEvents.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(TablerIcons.device_laptop,
                                color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            const Text('Weekly Online Connects',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...onlineEvents.map((e) => _buildVirtualCard(e)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(TablerIcons.calendar_off, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('No upcoming scheduled events',
          style: TextStyle(
              color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _buildPhysicalCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              right: -10,
              bottom: -10,
              child: Icon(TablerIcons.building_skyscraper,
                  size: 140, color: Colors.white.withOpacity(0.04))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(TablerIcons.calendar_star,
                          color: AppColors.accent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          if (event.description != null)
                            Text(event.description!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(TablerIcons.clock,
                              color: Colors.white.withOpacity(0.5), size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDate(event.startAt),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(TablerIcons.map_pin,
                              color: Colors.white.withOpacity(0.5), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(event.location ?? 'TBD',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(event),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Event event) {
    if (_currentUserId == null) return const SizedBox.shrink();
    
    final status = event.getRsvpStatus(_currentUserId!);
    
    if (status == 'going') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TablerIcons.check, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text('JOINED',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ],
        ),
      );
    }
    
    if (status == 'not_going') {
       return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
        ),
        child: const Center(
          child: Text('PASSED',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
      );
    }

    return Row(
      children: [
        _rsvpGlassButton(event.id, 'going', 'Going', Colors.greenAccent),
        const SizedBox(width: 12),
        _rsvpGlassButton(event.id, 'not_going', 'Pass', Colors.redAccent),
      ],
    );
  }

  Widget _buildVirtualCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(TablerIcons.video,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.text,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(_formatDate(event.startAt),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (event.meetingLink != null)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(TablerIcons.link, size: 16),
                    label: const Text('Join Zoom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade100.withOpacity(0.2),
                      foregroundColor: Colors.blueAccent.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('TBA',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              _buildVirtualRSVP(event),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualRSVP(Event event) {
    if (_currentUserId == null) return const SizedBox.shrink();
    final status = event.getRsvpStatus(_currentUserId!);

    if (status == 'going') {
      return Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text('JOINED',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      );
    }

    return Expanded(
      flex: 2,
      child: OutlinedButton(
        onPressed: () => _rsvp(event.id, 'going'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const Text('RSVP',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _rsvpGlassButton(
      String eventId, String status, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _rsvp(eventId, status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
