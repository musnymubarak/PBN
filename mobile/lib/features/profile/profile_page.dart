import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/reward.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _chapterService = ChapterService();
  final _rewardService = RewardService();
  List<Membership> _memberships = [];
  PrivilegeCard? _card;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _chapterService.getMyMemberships(),
        _rewardService.getMyCard(),
      ]);
      _memberships = results[0] as List<Membership>;
      _card = results[1] as PrivilegeCard?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(padding: const EdgeInsets.all(20), children: [
              // ── Avatar Card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(18)),
                    child: Center(child: Text(user?.initials ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.fullName ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(user?.phoneNumber ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                    if (user?.email != null) Text(user!.email!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Info Cards ───────────────────────────
              _infoTile(TablerIcons.badge, 'Role', user?.role.toUpperCase() ?? ''),
              _infoTile(TablerIcons.calendar, 'Member Since', user?.createdAt.split('T').first ?? ''),

              // ── Memberships ──────────────────────────
              if (_memberships.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('My Chapters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ..._memberships.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(TablerIcons.building, color: AppColors.accent, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.chapter.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(m.industryCategory.name, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(m.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: m.isActive ? Colors.green : Colors.grey)),
                    ),
                  ]),
                )),
              ],

              // ── Privilege Card ────────────────────────
              if (_card != null) ...[
                const SizedBox(height: 20),
                const Text('Privilege Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _infoTile(TablerIcons.credit_card, 'Card Number', _card!.cardNumber),
                _infoTile(TablerIcons.star, 'Tier', _card!.tier.toUpperCase()),
                _infoTile(TablerIcons.coin, 'Points', '${_card!.points}'),
              ],

              const SizedBox(height: 32),
              // ── Logout ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                  icon: const Icon(TablerIcons.logout, size: 20),
                  label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade100,
                    foregroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
      ]),
    );
  }
}
