import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/models/application.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final _service = ApplicationService();
  List<Application> _apps = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _apps = await _service.getMyApplications(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Applications', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _apps.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(TablerIcons.file_off, size: 48, color: Colors.grey.shade300), const SizedBox(height: 12),
                  Text('No applications', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: _apps.length,
                  itemBuilder: (ctx, i) => _card(_apps[i]),
                )),
    );
  }

  Widget _card(Application app) {
    final color = app.status == 'approved' ? Colors.green : app.status == 'rejected' ? Colors.red : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(app.businessName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(app.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
        ]),
        const SizedBox(height: 6),
        Text('${app.fullName} • ${app.district}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text('Applied: ${app.createdAt.split('T').first}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }
}
