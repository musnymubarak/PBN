class Event {
  final String id;
  final String title;
  final String? description;
  final String startAt;
  final String? endAt;
  final String? location;
  final String chapterId;
  final bool isPublished;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    this.location,
    required this.chapterId,
    this.isPublished = true,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        startAt: json['start_at'] ?? '',
        endAt: json['end_at'],
        location: json['location'],
        chapterId: json['chapter_id'] ?? '',
        isPublished: json['is_published'] ?? true,
      );
}
