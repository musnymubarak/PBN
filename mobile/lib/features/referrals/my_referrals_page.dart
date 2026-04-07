import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/models/referral.dart';

class MyReferralsPage extends StatefulWidget {
  final bool isReceived; // true for Received, false for Sent
  const MyReferralsPage({super.key, required this.isReceived});

  @override
  State<MyReferralsPage> createState() => _MyReferralsPageState();
}

class _MyReferralsPageState extends State<MyReferralsPage> {
  final _service = ReferralService();
  List<Referral> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (widget.isReceived) {
        _referrals = await _service.getReceivedReferrals();
      } else {
        _referrals = await _service.getGivenReferrals();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReceived ? 'Received Referrals' : 'Sent Referrals';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _referrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _referrals.length,
                      itemBuilder: (context, i) => _buildCard(_referrals[i]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(TablerIcons.arrows_exchange, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          widget.isReceived ? 'No referrals received yet' : 'No referrals sent yet',
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ]),
    );
  }

  Widget _buildCard(Referral ref) {
    final color = _statusColor(ref.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.isReceived ? () => _showStatusUpdate(ref) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ref.leadName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      widget.isReceived ? 'Shared by ${ref.fromUser.fullName}' : 'Sent to ${ref.targetUser.fullName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(ref.statusLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(children: [
                Icon(TablerIcons.calendar_event, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(_formatDate(ref.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (widget.isReceived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(TablerIcons.edit, size: 12, color: AppColors.accent),
                      SizedBox(width: 6),
                      Text('UPDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accent)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 20),
              if (ref.leadContact.isNotEmpty) _buildContactRow(TablerIcons.phone, ref.leadContact),
              if (ref.leadEmail != null && ref.leadEmail!.isNotEmpty) ...[
                if (ref.leadContact.isNotEmpty) const SizedBox(height: 10),
                _buildContactRow(TablerIcons.mail, ref.leadEmail!),
              ],
              if (ref.description != null && ref.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Text(ref.description!, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.5)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
    ]);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso.split('T').first; }
  }

  void _showStatusUpdate(Referral ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _UpdateStatusSheet(referral: ref, onUpdate: _loadData),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted': return Colors.blue;
      case 'contacted': return Colors.orange;
      case 'negotiation': return const Color(0xFF8B5CF6);
      case 'in_progress': return AppColors.accent;
      case 'success': return Colors.green;
      case 'closed_lost': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _UpdateStatusSheet extends StatefulWidget {
  final Referral referral;
  final VoidCallback onUpdate;
  const _UpdateStatusSheet({required this.referral, required this.onUpdate});

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final _service = ReferralService();
  final _descriptionController = TextEditingController();
  late String _selectedStatus;
  bool _loading = false;

  final List<Map<String, String>> _statuses = [
    {'value': 'submitted', 'label': 'Submitted'},
    {'value': 'contacted', 'label': 'Contacted'},
    {'value': 'negotiation', 'label': 'Negotiation'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'success', 'label': 'Success'},
    {'value': 'closed_lost', 'label': 'Lost'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.referral.status;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _service.updateStatus(widget.referral.id, _selectedStatus, description: _descriptionController.text.trim());
      widget.onUpdate();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Update Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(TablerIcons.x, size: 20, color: Colors.grey),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Lead: ${widget.referral.leadName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          const Text('CURRENT PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildStatusGrid(),
          const SizedBox(height: 32),
          const Text('STATUS NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add an update...',
              filled: true, fillColor: AppColors.background.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(text: 'UPDATE STATUS', onPressed: _submit, isLoading: _loading, backgroundColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: _statuses.map((s) {
        final isSelected = _selectedStatus == s['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedStatus = s['value']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 2),
            ),
            child: Text(s['label']!, style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}
