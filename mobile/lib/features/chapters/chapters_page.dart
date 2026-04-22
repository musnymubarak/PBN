import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/chapter.dart';

import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

class ChaptersPage extends StatefulWidget {
  const ChaptersPage({super.key});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  final _service = ChapterService();
  List<Chapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _loading = true);
    try {
      _chapters = await _service.listChapters();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Global Presence',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadChapters,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Network Overview Split Card ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Active Global Chapters',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Text('${_chapters.length}',
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Rapidly Expanding in 2024', 
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 16),

                  if (_chapters.isEmpty)
                    _buildEmptyState()
                  else
                    ..._chapters.map((chapter) => _buildModernChapterCard(chapter)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(TablerIcons.building_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No active chapters found', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChapterCard(Chapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(TablerIcons.building_community, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                if (chapter.description != null)
                  Text(chapter.description!, 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (chapter.meetingSchedule != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(TablerIcons.calendar_event, size: 10, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(chapter.meetingSchedule!.toUpperCase(), 
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(TablerIcons.chevron_right, color: Colors.grey.shade300, size: 18),
        ],
      ),
    );
  }
}
