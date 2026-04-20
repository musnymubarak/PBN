import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/models/referral.dart';

class MyReferralsPage extends StatefulWidget {
  final bool isReceived; 
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
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isReceived ? 'INCOMING TRACKER' : 'OUTGOING TRACKER',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _referrals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _referrals.length,
                      itemBuilder: (context, i) => _buildModernCard(_referrals[i]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(TablerIcons.folder_off, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          widget.isReceived ? 'No referrals received yet' : 'No referrals sent yet',
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ]),
    );
  }

  Widget _buildModernCard(Referral ref) {
    final color = _statusColor(ref.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => _showDetails(ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(TablerIcons.briefcase, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.leadName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(
                      widget.isReceived ? 'From: ${ref.fromUser.fullName}' : 'To: ${ref.targetUser.fullName}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(ref.statusLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(_formatDate(ref.createdAt), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
                ],
              ),
            ],
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
  final _roiController = TextEditingController();
  late String _selectedStatus;
  bool _loading = false;

  final List<Map<String, String>> _statuses = [
    {'value': 'submitted', 'label': 'New'},
    {'value': 'contacted', 'label': 'Contacted'},
    {'value': 'negotiation', 'label': 'Discussing'},
    {'value': 'in_progress', 'label': 'Waiting'},
    {'value': 'success', 'label': 'Success'},
    {'value': 'closed_lost', 'label': 'Lost'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.referral.status;
    if (widget.referral.actualValue != null) {
      _roiController.text = widget.referral.actualValue.toString();
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final textRoi = _roiController.text.trim();
      final roiValue = textRoi.isNotEmpty ? double.tryParse(textRoi) : null;
      await _service.updateStatus(widget.referral.id, _selectedStatus, description: _descriptionController.text.trim(), actualValue: roiValue);
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
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Split Style
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LEAD DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(widget.referral.leadName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(TablerIcons.x, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(TablerIcons.phone, 'Contact Number', widget.referral.leadContact),
                  if (widget.referral.leadEmail != null && widget.referral.leadEmail!.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    _buildDetailRow(TablerIcons.mail, 'Lead Email', widget.referral.leadEmail!),
                  ],
                  if (widget.referral.actualValue != null) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    _buildDetailRow(TablerIcons.cash, 'Realized ROI', 'LKR ${NumberFormat("#,##0").format(widget.referral.actualValue)}'),
                  ],
                  
                  if (widget.referral.description != null && widget.referral.description!.isNotEmpty) ...[
                     const SizedBox(height: 24),
                     Container(
                       padding: const EdgeInsets.all(20),
                       width: double.infinity,
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                         const Text('BUSINESS DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.0)),
                         const SizedBox(height: 12),
                         Text(widget.referral.description!, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5, fontWeight: FontWeight.w500)),
                       ]),
                     ),
                  ],
                  
                  if (widget.isReceived) ...[
                    const SizedBox(height: 32),
                    const Text('UPDATE REFERRAL STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildStatusGrid(),
                    const SizedBox(height: 24),
                    _buildInputField('Enter ROI / Referral Value (Optional)', _roiController, TablerIcons.cash, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildInputField('Internal update notes...', _descriptionController, TablerIcons.edit, maxLines: 2),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _loading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE UPDATES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true, fillColor: Colors.white,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 1.5),
            ),
            child: Text(s['label']!.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
          ),
        );
      }).toList(),
    );
  }
}
