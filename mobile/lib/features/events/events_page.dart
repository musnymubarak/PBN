import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/event_service.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/event.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'event_detail_page.dart';
import 'package:pbn/core/constants/api_config.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _service = EventService();
  final _chapterService = ChapterService();
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
      
      // Fetch user's memberships to filter by chapter
      final memberships = await _chapterService.getMyMemberships();
      final myChapterIds = memberships.map((m) => m.chapter.id).toSet();
      
      final results = await _service.listEvents();
      
      // Filter by chapter (only show meetings for chapters the user belongs to)
      final myEvents = results.where((e) => myChapterIds.contains(e.chapterId)).toList();
      
      // Sort by start date
      myEvents.sort((a, b) => a.startAt.compareTo(b.startAt));
      _events = myEvents;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }


  String _getPlaceholderImage(Event event) {
    if (event.eventType == 'flagship') {
      return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=800'; // Architectural Skyscraper
    }
    if (event.title.toLowerCase().contains('connect') || event.title.toLowerCase().contains('network')) {
      return 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=800'; // Team collaboration
    }
    return 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=800'; // Modern office interior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Facebook-like light grey background
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MEETINGS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 2.5)),
            const SizedBox(height: 2),
            const Text('Meetings & Events',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B1B1B),
                    letterSpacing: -0.8)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: _events.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _events.length,
                      itemBuilder: (context, index) => _buildFacebookStyleEventCard(_events[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
              child: Icon(TablerIcons.calendar_event, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('No Upcoming Meetings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Text('Check back later for new events.', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFacebookStyleEventCard(Event event) {
    final DateTime startDt = DateTime.parse(event.startAt).toLocal();
    final String day = DateFormat('dd').format(startDt);
    final String month = DateFormat('MMM').format(startDt).toUpperCase();
    final String time = DateFormat('EEEE • h:mm a').format(startDt);
    
    final String? fullImageUrl = event.imageUrl != null
        ? (event.imageUrl!.startsWith('http')
            ? event.imageUrl
            : '${ApiConfig.staticUrl}${event.imageUrl}')
        : null;

    final String placeholderUrl = _getPlaceholderImage(event);
    
    final status = _currentUserId != null ? event.getRsvpStatus(_currentUserId!) : null;
    final bool isGoing = status == 'going';
    final bool isNotGoing = status == 'not_going';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Date Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl ?? placeholderUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(TablerIcons.photo_off, size: 40, color: AppColors.primary.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                // Date Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      children: [
                        Text(month, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                        Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
                      ],
                    ),
                  ),
                ),
                // Flagship / Virtual Badge
                Positioned(
                  bottom: 12,
                  right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber/Gold Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          const Icon(TablerIcons.ticket, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'LKR ${event.fee.toStringAsFixed(0)}', 
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                          ),
                        ],
                      ),
                    ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(TablerIcons.map_pin, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location ?? (event.meetingLink != null ? 'Virtual Meeting' : 'To be announced'),
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      event.description!, 
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  // RSVP Summary
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.rsvps.length} members are interested', 
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  // Action Buttons
                  // Navigation Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('View Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(TablerIcons.chevron_right, size: 16, color: AppColors.primary),
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
}
