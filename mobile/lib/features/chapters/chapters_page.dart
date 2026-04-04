import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/chapter.dart';

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
  void initState() { super.initState(); _loadChapters(); }

  Future<void> _loadChapters() async {
    setState(() => _loading = true);
    try { _chapters = await _service.listChapters(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chapters', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _chapters.isEmpty
              ? Center(child: Text('No chapters available', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
              : RefreshIndicator(
                  onRefresh: _loadChapters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chapters.length,
                    itemBuilder: (context, i) => _buildChapterCard(_chapters[i]),
                  ),
                ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: const Icon(TablerIcons.building, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(chapter.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
          if (chapter.description != null) ...[
            const SizedBox(height: 4),
            Text(chapter.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (chapter.meetingSchedule != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(TablerIcons.calendar, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(chapter.meetingSchedule!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ]),
          ],
        ])),
        Icon(TablerIcons.chevron_right, color: Colors.grey.shade300, size: 20),
      ]),
    );
  }
}
