class Event {
  final String id;
  final String title;
  final String? description;
  final String startAt;
  final String? endAt;
  final String? location;
  final String? meetingLink;
  final String chapterId;
  final String eventType;
  final List<dynamic> rsvps;
  final bool isPublished;
  final String? imageUrl;
  final double fee;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    this.location,
    this.meetingLink,
    required this.chapterId,
    this.eventType = 'virtual',
    this.rsvps = const [],
    this.isPublished = true,
    this.imageUrl,
    this.fee = 0.0,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        startAt: json['start_at'] ?? '',
        endAt: json['end_at'],
        location: json['location'],
        meetingLink: json['meeting_link'],
        chapterId: json['chapter_id'] ?? '',
        eventType: json['event_type'] ?? 'virtual',
        rsvps: json['rsvps'] ?? [],
        isPublished: json['is_published'] ?? true,
        imageUrl: json['image_url'],
        fee: (json['fee'] != null) ? (json['fee'] is int ? (json['fee'] as int).toDouble() : json['fee'].toDouble()) : 0.0,
      );

  String? getRsvpStatus(String userId) {
    if (rsvps.isEmpty) return null;
    try {
      final rsvp = rsvps.firstWhere(
        (r) => r['user']['id'] == userId,
        orElse: () => null,
      );
      return rsvp?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  int get confirmedRsvpsCount => rsvps.where((r) => r['status'] == 'going').length;
}
