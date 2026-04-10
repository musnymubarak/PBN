import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/constants/api_config.dart';
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
      final chapters = await _chapterService.listChapters();
      List<Member> allMembers = [];
      for (var chapter in chapters) {
        final members = await _chapterService.getChapterMembers(chapter.id);
        allMembers.addAll(members);
      }
      _members = allMembers;
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP HEADER: Dark Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      member.profilePhoto != null 
                          ? '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${member.profilePhoto}'
                          : 'https://i.pravatar.cc/150?u=${member.userId}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: const Color(0xFF1E3A8A),
                        child: Center(
                          child: Text(member.initials,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(member.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // BOTTOM CONTENT: White Background
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(member.industry.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5)),
                ),
                if (member.chapterName != null && member.chapterName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(member.chapterName!.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 0.5)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
