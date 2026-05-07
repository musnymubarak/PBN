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
        _buildActionIcon(
          icon: TablerIcons.messages,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityPage()),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildActionIcon(
              icon: TablerIcons.bell,
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (notifs.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
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
              ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionIcon({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}
