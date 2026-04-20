class NotificationSettings {
  final bool newPosts;
  final bool postActivity;
  final bool meetingUpdates;
  final bool chapterAnnouncements;
  final bool newRewards;
  final bool newMembers;

  NotificationSettings({
    required this.newPosts,
    required this.postActivity,
    required this.meetingUpdates,
    required this.chapterAnnouncements,
    required this.newRewards,
    required this.newMembers,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newPosts: json['new_posts'] ?? true,
      postActivity: json['post_activity'] ?? true,
      meetingUpdates: json['meeting_updates'] ?? true,
      chapterAnnouncements: json['chapter_announcements'] ?? true,
      newRewards: json['new_rewards'] ?? true,
      newMembers: json['new_members'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_posts': newPosts,
      'post_activity': postActivity,
      'meeting_updates': meetingUpdates,
      'chapter_announcements': chapterAnnouncements,
      'new_rewards': newRewards,
      'new_members': newMembers,
    };
  }

  NotificationSettings copyWith({
    bool? newPosts,
    bool? postActivity,
    bool? meetingUpdates,
    bool? chapterAnnouncements,
    bool? newRewards,
    bool? newMembers,
  }) {
    return NotificationSettings(
      newPosts: newPosts ?? this.newPosts,
      postActivity: postActivity ?? this.postActivity,
      meetingUpdates: meetingUpdates ?? this.meetingUpdates,
      chapterAnnouncements: chapterAnnouncements ?? this.chapterAnnouncements,
      newRewards: newRewards ?? this.newRewards,
      newMembers: newMembers ?? this.newMembers,
    );
  }
}
