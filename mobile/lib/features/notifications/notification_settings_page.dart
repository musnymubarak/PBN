import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/services/notification_service.dart';
import 'package:pbn/models/notification_settings.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _service = NotificationService();
  NotificationSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await _service.getSettings();
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  Future<void> _toggle(String key, bool val) async {
    if (_settings == null) return;

    final updated = _settings!.copyWith(
      newPosts: key == 'new_posts' ? val : null,
      postActivity: key == 'post_activity' ? val : null,
      meetingUpdates: key == 'meeting_updates' ? val : null,
      chapterAnnouncements: key == 'chapter_announcements' ? val : null,
      newRewards: key == 'new_rewards' ? val : null,
      newMembers: key == 'new_members' ? val : null,
    );

    setState(() => _settings = updated);

    try {
      await _service.updateSettings(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: $e')),
        );
        // Revert UI if failed
        _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Customize what you receive push notifications for. You will still see all activity in your in-app notification center.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                _settingSection(
                  'Community',
                  [
                    _toggleItem(
                      'New Chapter Posts',
                      'Alerts when someone in your chapter shares a new post',
                      TablerIcons.news,
                      _settings!.newPosts,
                      (v) => _toggle('new_posts', v),
                    ),
                    _toggleItem(
                      'Activity on My Posts',
                      'Likes and comments on your community updates',
                      TablerIcons.thumb_up,
                      _settings!.postActivity,
                      (v) => _toggle('post_activity', v),
                    ),
                    _toggleItem(
                      'New Member Announcements',
                      'Stay updated when new members join your chapter',
                      TablerIcons.user_plus,
                      _settings!.newMembers,
                      (v) => _toggle('new_members', v),
                    ),
                  ],
                ),
                const Divider(),
                _settingSection(
                  'Meetings & Events',
                  [
                    _toggleItem(
                      'Meeting Updates',
                      'RSVP confirmations and schedule changes',
                      TablerIcons.calendar_event,
                      _settings!.meetingUpdates,
                      (v) => _toggle('meeting_updates', v),
                    ),
                    _toggleItem(
                      'Chapter Announcements',
                      'Direct messages and broadcasts from your chapter team',
                      TablerIcons.message_report,
                      _settings!.chapterAnnouncements,
                      (v) => _toggle('chapter_announcements', v),
                    ),
                  ],
                ),
                const Divider(),
                _settingSection(
                  'Rewards & Offers',
                  [
                    _toggleItem(
                      'New Rewards',
                      'Alerts about new privilege card partner offers',
                      TablerIcons.gift,
                      _settings!.newRewards,
                      (v) => _toggle('new_rewards', v),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _settingSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _toggleItem(
      String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}
