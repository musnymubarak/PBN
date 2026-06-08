/// A single home-carousel slide served by `GET /home/slides`.
///
/// The backend renders a generic list of these so admins can change the
/// carousel (content, order, schedule, audience) without an app update.
/// For the auto-event slide types the backend also fills [startAt],
/// [location] and [eventId] from the next upcoming event.
class HomeSlide {
  final String id;
  final String slideType; // custom | next_virtual_event | next_physical_event
  final String? badgeLabel;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? ctaLabel;
  final String ctaActionType; // none | route | url | event | maps
  final String? ctaActionValue;

  // Extras present on resolved dynamic-event slides.
  final String? eventId;
  final String? startAt;
  final String? location;

  HomeSlide({
    required this.id,
    this.slideType = 'custom',
    this.badgeLabel,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.ctaLabel,
    this.ctaActionType = 'none',
    this.ctaActionValue,
    this.eventId,
    this.startAt,
    this.location,
  });

  factory HomeSlide.fromJson(Map<String, dynamic> json) => HomeSlide(
        id: json['id'] ?? '',
        slideType: json['slide_type'] ?? 'custom',
        badgeLabel: json['badge_label'],
        title: json['title'],
        subtitle: json['subtitle'],
        imageUrl: json['image_url'],
        ctaLabel: json['cta_label'],
        ctaActionType: json['cta_action_type'] ?? 'none',
        ctaActionValue: json['cta_action_value'],
        eventId: json['event_id'],
        startAt: json['start_at'],
        location: json['location'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slide_type': slideType,
        'badge_label': badgeLabel,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'cta_label': ctaLabel,
        'cta_action_type': ctaActionType,
        'cta_action_value': ctaActionValue,
        'event_id': eventId,
        'start_at': startAt,
        'location': location,
      };
}
