import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/event_service.dart';

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
      // Find the updated version of this specific event
      final latestEvent = events.firstWhere((e) => e.id == _currentEvent.id);
      if (mounted) {
        setState(() {
          _currentEvent = latestEvent;
        });
      }
    } catch (_) {
      // Slient fail if network unavailable, local cache will persist
    }
  }

  Future<void> _handleRSVP(String status) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.updateRSVP(_currentEvent.id, status);
      
      // Refresh local event data to show updated RSVP list/status
      final updatedEvents = await _eventService.listEvents();
      final updatedEvent = updatedEvents.firstWhere((e) => e.id == _currentEvent.id);
      
      if (mounted) {
        setState(() {
          _currentEvent = updatedEvent;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'going' ? 'Requested successfully!' : 'Meeting ignored.'),
            backgroundColor: status == 'going' ? Colors.green : Colors.grey[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        if (status == 'not_going') {
          Navigator.pop(context); // Optional: Close page if they ignore?
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(_currentEvent.startAt);
    final endTime = _currentEvent.endAt != null ? DateTime.parse(_currentEvent.endAt!) : null;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    final rsvpStatus = _currentEvent.getRsvpStatus(userId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: TablerIcons.calendar_event,
                    title: 'Date & Time',
                    subtitle: '${DateFormat('EEEE, MMMM d, yyyy').format(startTime)}\n'
                        '${DateFormat('h:mm a').format(startTime)}${endTime != null ? ' - ${DateFormat('h:mm a').format(endTime)}' : ''}',
                  ),
                  const SizedBox(height: 16),
                  if (_currentEvent.location != null && _currentEvent.location!.isNotEmpty)
                    _buildInfoCard(
                      icon: TablerIcons.map_pin,
                      title: 'Location',
                      subtitle: _currentEvent.location!,
                      actionIcon: TablerIcons.directions,
                      onAction: () async {
                        final url = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(_currentEvent.location!)}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map.')));
                          }
                        }
                      },
                    ),
                  if (_currentEvent.meetingLink != null && _currentEvent.meetingLink!.isNotEmpty)
                    _buildInfoCard(
                      icon: TablerIcons.video,
                      title: 'Virtual Meeting',
                      subtitle: _currentEvent.meetingLink!,
                      actionIcon: TablerIcons.external_link,
                      onAction: () async {
                        var link = _currentEvent.meetingLink!;
                        if (!link.startsWith('http')) {
                          link = 'https://$link';
                        }
                        final url = Uri.parse(link);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
                          }
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  _buildRsvpStats(),
                  const SizedBox(height: 120), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, rsvpStatus),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final String? fullImageUrl = _currentEvent.imageUrl != null
        ? (_currentEvent.imageUrl!.startsWith('http')
            ? _currentEvent.imageUrl
            : '${ApiConfig.staticUrl}${_currentEvent.imageUrl}')
        : null;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (fullImageUrl != null)
              CachedNetworkImage(
                imageUrl: fullImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderImage(),
              )
            else
              _buildPlaceholderImage(),
            // Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Price Tag Overlay
            Positioned(
              top: 100,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B), // Gold/Amber
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.ticket, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'LKR ${NumberFormat('#,##0').format(_currentEvent.fee)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(TablerIcons.arrow_left, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(
          TablerIcons.calendar_event,
          size: 80,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _currentEvent.eventType.toUpperCase(),
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _currentEvent.title.toUpperCase(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A2540),
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)], // Light Amber Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                child: const Icon(TablerIcons.cash, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'REGISTRATION FEE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF92400E), letterSpacing: 1),
                  ),
                  Text(
                    'LKR ${NumberFormat('#,##0').format(_currentEvent.fee)} per attendee',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A2540)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, color: AppColors.secondary, size: 20),
              onPressed: onAction,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this meeting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _currentEvent.description ?? 'No description provided for this event.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.text.withOpacity(0.8),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_currentEvent.confirmedRsvpsCount}', 'Going'),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildStatItem('—', 'Waitlist'),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildStatItem('Open', 'Availability'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, String? rsvpStatus) {
    bool isGoing = rsvpStatus == 'going';
    bool isNotGoing = rsvpStatus == 'not_going';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: isGoing 
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(TablerIcons.circle_check, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'YOU ARE REGISTERED',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                          ),
                        ],
                      ),
                    )
                  : (rsvpStatus == 'requested'
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(TablerIcons.clock, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'WAITING FOR APPROVAL',
                                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleRSVP('going'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                'RESERVE SPOT • LKR ${NumberFormat('#,##0').format(_currentEvent.fee)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                              ),
                        )),
              ),
              if (!isGoing && rsvpStatus != 'requested') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleRSVP('not_going'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isNotGoing ? Colors.red : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isNotGoing ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isNotGoing ? 'IGNORED' : 'IGNORE',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
