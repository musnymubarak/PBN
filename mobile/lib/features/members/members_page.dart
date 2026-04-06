import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/member.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _chapterService = ChapterService();
  List<Member> _members = [];
  List<Member> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final memberships = await _chapterService.getMyMemberships();
      if (memberships.isNotEmpty) {
        _members = await _chapterService.getChapterMembers(memberships.first.chapter.id);
      }
    } catch (_) {}
    _filtered = _members;
    if (mounted) setState(() => _loading = false);
  }

  void _filterMembers(String query) {
    setState(() {
      _search = query;
      _filtered = _members.where((m) => m.fullName.toLowerCase().contains(query.toLowerCase()) || m.industry.toLowerCase().contains(query.toLowerCase()) || m.company.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NETWORK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2)),
            Text('${_members.length} Members', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: _filterMembers,
              decoration: InputDecoration(
                hintText: 'Search by name or industry...',
                prefixIcon: const Icon(TablerIcons.search, size: 20, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _buildModernMemberCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(TablerIcons.users_group, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(_search.isEmpty ? 'No members found' : 'No results for "$_search"', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _buildModernMemberCard(Member member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative background shape
            Positioned(right: -10, top: -10, child: Icon(TablerIcons.square_rotated, color: AppColors.primary.withOpacity(0.03), size: 100)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(member.initials, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.text, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                              child: Text(member.industry.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.background),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COMPANY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(member.company, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ],
                      ),
                      Row(
                        children: [
                          _contactBtn(TablerIcons.phone, Colors.blue),
                          const SizedBox(width: 8),
                          _contactBtn(TablerIcons.messages, const Color(0xFF10B981)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
