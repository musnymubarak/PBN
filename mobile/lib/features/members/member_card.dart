import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/widgets/cached_avatar.dart';
import 'package:pbn/models/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
        boxShadow: AppColors.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Premium gold-ringed avatar (photo with initials fallback)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CachedAvatar(
                    imageUrl: member.profilePhoto,
                    initials: member.initials,
                    size: 52,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              TablerIcons.briefcase,
                              size: 11,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              member.industry,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              TablerIcons.building_community,
                              size: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              member.company,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.chevron_right,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
