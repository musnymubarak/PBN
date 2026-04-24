import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/services/dashboard_service.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/providers/auth_provider.dart';

import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _service = DashboardService();
  List<dynamic> _entries = [];
  bool _loading = true;
  String _period = 'this_month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Only show full screen loading if we don't have any data yet
    if (_entries.isEmpty) {
      setState(() => _loading = true);
    }
    
    try {
      final auth = context.read<AuthProvider>();
      final newEntries = await _service.getLeaderboard(
        chapterId: auth.user?.chapterId,
        period: _period,
      );
      if (mounted) {
        setState(() {
          _entries = newEntries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Leaderboard',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5)),
          ],
        ),
        actions: [
          PbnAppBarActions(),
        ],
      ),
      body: _loading && _entries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Segmented Control
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildPeriodSelector(),
                            ),
                            
                            // Podium
                            if (_entries.isNotEmpty) 
                              _buildPodium(_entries),
                              
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Remaining List
                      if (_entries.length > 3)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildEntry(index + 4, _entries[index + 3]),
                            ),
                            childCount: _entries.length - 3,
                          ),
                        )
                      else if (_entries.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(TablerIcons.mood_empty, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No referrals yet!',
                                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                  if (_loading && _entries.isNotEmpty)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _periodTab('This Month', 'this_month')),
          Expanded(child: _periodTab('This Quarter', 'this_quarter')),
          Expanded(child: _periodTab('This Year', 'this_year')),
          Expanded(child: _periodTab('All Time', 'all_time')),
        ],
      ),
    );
  }

  Widget _periodTab(String label, String value) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () {
        setState(() => _period = value);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  color: selected ? AppColors.text : Colors.grey.shade500)),
        ),
      ),
    );
  }

  Widget _buildPodium(List<dynamic> entries) {
    final top1 = entries.length >= 1 ? entries[0] : null;
    final top2 = entries.length >= 2 ? entries[1] : null;
    final top3 = entries.length >= 3 ? entries[2] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 24, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2
          if (top2 != null)
            Expanded(child: _buildPodiumAvatar(top2, 2, const Color(0xFF94A3B8))),
          
          // Rank 1
          if (top1 != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildPodiumAvatar(top1, 1, const Color(0xFFF59E0B)),
              ),
            ),
            
          // Rank 3
          if (top3 != null)
            Expanded(child: _buildPodiumAvatar(top3, 3, const Color(0xFFB45309))),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar(dynamic user, int rank, Color color) {
    final name = (user['full_name'] ?? 'Unknown').toString().split(' ').first;
    final count = user['sent_count'] ?? 0;
    final initials = _getInitials(user['full_name']?.toString() ?? '?');
    
    final double avatarSize = rank == 1 ? 84 : 64;
    
    String? profilePhoto = user['profile_photo'];
    final bool hasPhoto = profilePhoto != null && profilePhoto.isNotEmpty;
    String imageUrl = hasPhoto
        ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$profilePhoto'
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (rank == 1)
          const Icon(TablerIcons.crown, color: Color(0xFFF59E0B), size: 32),
        if (rank == 1)
          const SizedBox(height: 8),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasPhoto ? Colors.white : color.withOpacity(0.1),
                border: Border.all(color: color, width: rank == 1 ? 4 : 3),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: hasPhoto 
                  ? Image.network(
                      imageUrl,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: rank == 1 ? 28 : 20),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: rank == 1 ? 28 : 20),
                      ),
                    ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(TablerIcons.users, size: 12, color: color),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntry(int rank, dynamic entry) {
    final name = (entry['full_name'] ?? 'Unknown').toString();
    final count = entry['sent_count'] ?? 0;
    final initials = _getInitials(name);
    
    String? profilePhoto = entry['profile_photo'];
    final bool hasPhoto = profilePhoto != null && profilePhoto.isNotEmpty;
    String imageUrl = hasPhoto
        ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}$profilePhoto'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Rank text
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
          ),
          
          // Avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: hasPhoto ? null : const LinearGradient(
                colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: hasPhoto ? Colors.white : null,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: hasPhoto 
                ? Image.network(
                    imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Center(
                      child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF475569), fontSize: 13))
                    ),
                  )
                : Center(
                    child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF475569), fontSize: 13))
                  ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Name
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text, letterSpacing: -0.2)),
          ),
          
          // Referral Stats
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
          const SizedBox(width: 4),
          const Icon(TablerIcons.users, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
