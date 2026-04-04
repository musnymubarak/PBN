import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try { _events = await _service.listEvents(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rsvp(String eventId, String status) async {
    try {
      await _service.updateRSVP(eventId, status);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RSVP: $status'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update RSVP'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _events.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(TablerIcons.calendar_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No upcoming events', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, i) => _buildEventCard(_events[i]),
                  ),
                ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(TablerIcons.calendar_event, color: AppColors.accent, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              if (event.description != null)
                Text(event.description!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Icon(TablerIcons.clock, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(event.startAt.split('T').first, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              if (event.location != null) ...[
                const SizedBox(width: 16),
                Icon(TablerIcons.map_pin, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(child: Text(event.location!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
              ],
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _rsvpButton(event.id, 'attending', 'Accept', Colors.green),
              const SizedBox(width: 8),
              _rsvpButton(event.id, 'maybe', 'Maybe', Colors.orange),
              const SizedBox(width: 8),
              _rsvpButton(event.id, 'declined', 'Decline', Colors.red),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _rsvpButton(String eventId, String status, String label, Color color) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _rsvp(eventId, status),
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
