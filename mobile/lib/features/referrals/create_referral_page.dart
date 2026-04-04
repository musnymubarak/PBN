import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/models/member.dart';

class CreateReferralPage extends StatefulWidget {
  const CreateReferralPage({super.key});

  @override
  State<CreateReferralPage> createState() => _CreateReferralPageState();
}

class _CreateReferralPageState extends State<CreateReferralPage> {
  final _referralService = ReferralService();
  final _chapterService = ChapterService();

  List<Member> _members = [];
  Member? _selectedMember;
  final _leadNameController = TextEditingController();
  final _leadContactController = TextEditingController();
  final _leadEmailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final memberships = await _chapterService.getMyMemberships();
      if (memberships.isNotEmpty) {
        _members = await _chapterService.getChapterMembers(memberships.first.chapter.id);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMembers = false);
  }

  Future<void> _submit() async {
    if (_selectedMember == null) { _showError('Please select a member'); return; }
    if (_leadNameController.text.isEmpty) { _showError('Please enter lead name'); return; }
    if (_leadContactController.text.isEmpty) { _showError('Please enter lead contact'); return; }

    setState(() => _loading = true);
    try {
      await _referralService.createReferral(
        targetUserId: _selectedMember!.userId,
        leadName: _leadNameController.text.trim(),
        leadContact: _leadContactController.text.trim(),
        leadEmail: _leadEmailController.text.trim().isEmpty ? null : _leadEmailController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral submitted successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _leadNameController.clear(); _leadContactController.clear(); _leadEmailController.clear(); _notesController.clear();
        setState(() { _selectedMember = null; });
      }
    } catch (e) {
      _showError('Failed to submit referral');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New Referral', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('SELECT MEMBER'),
          const SizedBox(height: 8),
          _loadingMembers
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Member>(
                      value: _selectedMember,
                      hint: const Text('Choose a member...'),
                      isExpanded: true,
                      items: _members.map((m) => DropdownMenuItem(value: m, child: Text('${m.fullName} — ${m.industry}'))).toList(),
                      onChanged: (m) => setState(() => _selectedMember = m),
                    ),
                  ),
                ),
          const SizedBox(height: 24),

          _sectionLabel('LEAD INFORMATION'),
          const SizedBox(height: 8),
          _inputField(_leadNameController, 'Lead Name', TablerIcons.user, required: true),
          const SizedBox(height: 14),
          _inputField(_leadContactController, 'Lead Contact Number', TablerIcons.phone, keyboardType: TextInputType.phone, required: true),
          const SizedBox(height: 14),
          _inputField(_leadEmailController, 'Lead Email (optional)', TablerIcons.mail, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _inputField(_notesController, 'Notes (optional)', TablerIcons.notes, maxLines: 3),
          const SizedBox(height: 32),

          CustomButton(text: 'SUBMIT REFERRAL', onPressed: _submit, isLoading: _loading),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2));

  Widget _inputField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool required = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon, size: 20) : null,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
