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
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try { _entries = await _service.getLeaderboard(period: _period); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Column(children: [
        // ── Period Filter ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _periodChip('This Month', 'this_month'),
            const SizedBox(width: 8),
            _periodChip('This Quarter', 'this_quarter'),
            const SizedBox(width: 8),
            _periodChip('This Year', 'this_year'),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _entries.isEmpty
                  ? Center(child: Text('No leaderboard data', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) => _buildEntry(i, _entries[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () { setState(() => _period = value); _loadData(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildEntry(int index, dynamic entry) {
    final rank = index + 1;
    final name = entry['full_name'] ?? 'Unknown';
    final count = entry['referral_count'] ?? 0;
    final isTop3 = rank <= 3;
    final accent = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : rank == 3 ? const Color(0xFFCD7F32) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isTop3 ? Border.all(color: accent.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: isTop3 ? accent.withOpacity(0.15) : AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Center(child: isTop3
              ? Icon(TablerIcons.trophy, size: 18, color: accent)
              : Text('#$rank', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade400, fontSize: 13))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(name, style: TextStyle(fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600, fontSize: 14))),
        Text('$count referrals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isTop3 ? accent : AppColors.textSecondary)),
      ]),
    );
  }
}
