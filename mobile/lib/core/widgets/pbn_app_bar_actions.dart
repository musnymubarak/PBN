import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/features/community/community_page.dart';

class PbnAppBarActions extends StatelessWidget {
  const PbnAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationProvider>();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(TablerIcons.messages, color: AppColors.text, size: 24),
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const CommunityPage())
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(TablerIcons.bell, color: AppColors.text, size: 24),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (notifs.unreadCount > 0)
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${notifs.unreadCount}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
