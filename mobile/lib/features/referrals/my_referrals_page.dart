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
    final title = widget.isReceived ? 'Received Deals' : 'Sent Deals';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.black,
              child: _referrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _referrals.length,
                      itemBuilder: (context, i) => _buildCard(_referrals[i]),
                      physics: const AlwaysScrollableScrollPhysics(),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(TablerIcons.folder_off, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          widget.isReceived ? 'No deals received yet' : 'No deals sent yet',
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ]),
    );
  }

  Widget _buildCard(Referral ref) {
    final color = _statusColor(ref.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(ref), // Always enable click to show details
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(ref.leadName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(ref.statusLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  widget.isReceived ? 'From ${ref.fromUser.fullName}' : 'To ${ref.targetUser.fullName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                Text(_formatDate(ref.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso.split('T').first; }
  }

  void _showDetails(Referral ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _ReferralDetailsSheet(referral: ref, isReceived: widget.isReceived, onUpdate: _loadData),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted': return Colors.blue;
      case 'contacted': return Colors.orange;
      case 'negotiation': return const Color(0xFF8B5CF6);
      case 'in_progress': return Colors.black;
      case 'success': return Colors.green;
      case 'closed_lost': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _ReferralDetailsSheet extends StatefulWidget {
  final Referral referral;
  final bool isReceived;
  final VoidCallback onUpdate;
  const _ReferralDetailsSheet({required this.referral, required this.isReceived, required this.onUpdate});

  @override
  State<_ReferralDetailsSheet> createState() => _ReferralDetailsSheetState();
}

class _ReferralDetailsSheetState extends State<_ReferralDetailsSheet> {
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
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(widget.referral.leadName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black))),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: const Icon(TablerIcons.x, size: 20, color: Colors.black),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          
          // Contact Details
          _buildInfoRow(TablerIcons.phone, widget.referral.leadContact),
          if (widget.referral.leadEmail != null && widget.referral.leadEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(TablerIcons.mail, widget.referral.leadEmail!),
          ],
          
          if (widget.referral.description != null && widget.referral.description!.isNotEmpty) ...[
             const SizedBox(height: 24),
             Container(
               padding: const EdgeInsets.all(16),
               width: double.infinity,
               decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16)),
               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.0)),
                 const SizedBox(height: 8),
                 Text(widget.referral.description!, style: const TextStyle(fontSize: 14, color: Colors.black, height: 1.5)),
               ]),
             ),
          ],
          
          if (widget.isReceived) ...[
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 24),
            const Text('UPDATE STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildStatusGrid(),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Add an update note...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                child: Center(
                  child: _loading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 12),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
    ]);
  }

  Widget _buildStatusGrid() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _statuses.map((s) {
        final isSelected = _selectedStatus == s['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedStatus = s['value']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300, width: 1.5),
            ),
            child: Text(s['label']!, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}
