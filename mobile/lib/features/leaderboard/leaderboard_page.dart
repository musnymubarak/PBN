import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/dashboard_service.dart';

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
    setState(() => _loading = true);
    try {
      _entries = await _service.getLeaderboard(period: _period);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PERFORMANCE RANKING',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text('Global Leaderboard',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // ── Podium Section (Top 3) ──────────────────────────
                  if (_entries.isNotEmpty) _buildPodium(_entries),
                  const SizedBox(height: 24),

                  // ── Period Selectors ───────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _periodChip('This Month', 'this_month'),
                        const SizedBox(width: 8),
                        _periodChip('This Quarter', 'this_quarter'),
                        const SizedBox(width: 8),
                        _periodChip('This Year', 'this_year'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('RANKING TABLE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  // ── Remaining List ──────────────────────────────
                  if (_entries.length > 3)
                    ..._entries.sublist(3).asMap().entries.map((e) => _buildEntry(e.key + 4, e.value))
                  else if (_entries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No ranking data for this period.',
                            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildPodium(List<dynamic> entries) {
    final top1 = entries.length >= 1 ? entries[0] : null;
    final top2 = entries.length >= 2 ? entries[1] : null;
    final top3 = entries.length >= 3 ? entries[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank 2
        if (top2 != null)
          _podiumItem(top2, 2, const Color(0xFFC0C0C0), 100),
        const SizedBox(width: 12),
        // Rank 1
        if (top1 != null)
          _podiumItem(top1, 1, const Color(0xFFFFD700), 125),
        const SizedBox(width: 12),
        // Rank 3
        if (top3 != null)
          _podiumItem(top3, 3, const Color(0xFFCD7F32), 90),
      ],
    );
  }

  Widget _podiumItem(dynamic user, int rank, Color color, double height) {
    final initials = (user['full_name'] ?? '?').split(' ').map((e) => e[0]).join();
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Center(child: Text(initials, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18))),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(TablerIcons.trophy, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user['full_name']?.split(' ').first ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${user['referral_count']} Deals',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () {
        setState(() => _period = value);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade100),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.white : AppColors.textSecondary, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEntry(int rank, dynamic entry) {
    final name = entry['full_name'] ?? 'Unknown';
    final count = entry['referral_count'] ?? 0;
    final initials = name.split(' ').map((e) => e[0]).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text('#$rank',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey.shade300, letterSpacing: -1)),
          const SizedBox(width: 16),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 13))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('Active Global Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
          const SizedBox(width: 4),
          const Icon(TablerIcons.briefcase, color: AppColors.primary, size: 14),
        ],
      ),
    );
  }
}
