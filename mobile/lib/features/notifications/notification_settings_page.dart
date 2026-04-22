import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
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
      referralActivity: key == 'referral_activity' ? val : null,
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
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  color: Colors.white,
                  child: const Text(
                    'Customize what you receive push notifications for. You will still see all activity in your in-app notification center.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                _settingSection(
                  'Referrals & Leads',
                  [
                    _toggleItem(
                      'Referral Activity',
                      'New leads received and status changes on your referrals',
                      TablerIcons.transfer_in,
                      _settings!.referralActivity,
                      (v) => _toggle('referral_activity', v),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _settingSection(String title, List<Widget> items) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _toggleItem(
      String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      activeTrackColor: AppColors.accent.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
