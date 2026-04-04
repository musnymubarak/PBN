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
      // First get my memberships to find my chapter
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
      appBar: AppBar(title: const Text('Chapter Members', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterMembers,
              decoration: InputDecoration(
                hintText: 'Search members...', prefixIcon: const Icon(TablerIcons.search, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(TablerIcons.users_group, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(_search.isEmpty ? 'No members found' : 'No results for "$_search"', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _buildMemberCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(member.initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('${member.industry} • ${member.company}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ])),
        Icon(TablerIcons.chevron_right, color: Colors.grey.shade300, size: 20),
      ]),
    );
  }
}
