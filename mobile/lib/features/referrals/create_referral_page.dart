import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/core/services/referral_service.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/models/member.dart';
import 'package:pbn/models/user.dart';

class CreateReferralPage extends StatefulWidget {
  const CreateReferralPage({super.key});

  @override
  State<CreateReferralPage> createState() => _CreateReferralPageState();
}

class _CreateReferralPageState extends State<CreateReferralPage> {
  final _referralService = ReferralService();
  final _chapterService = ChapterService();
  final _authService = AuthService();

  List<Member> _members = [];
  Member? _selectedMember;
  User? _currentUser;
  
  final _leadNameController = TextEditingController();
  final _leadContactController = TextEditingController();
  final _leadEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _loading = false;
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _currentUser = await _authService.getProfile();
      final memberships = await _chapterService.getMyMemberships();
      if (memberships.isNotEmpty) {
        final allMembers = await _chapterService.getChapterMembers(memberships.first.chapter.id);
        // Exclude current user from receiving their own referral
        _members = allMembers.where((m) => m.userId != _currentUser?.id).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMembers = false);
  }

  Future<void> _submit() async {
    if (_selectedMember == null) { _showError('Please select a member'); return; }
    if (_leadNameController.text.trim().isEmpty) { _showError('Please enter lead name'); return; }
    if (_leadContactController.text.trim().isEmpty) { _showError('Please enter lead contact'); return; }
    if (_leadEmailController.text.trim().isEmpty) { _showError('Please enter lead email'); return; }
    if (_descriptionController.text.trim().isEmpty) { _showError('Please enter referral description'); return; }

    setState(() => _loading = true);
    try {
      await _referralService.createReferral(
        targetUserId: _selectedMember!.userId,
        leadName: _leadNameController.text.trim(),
        leadContact: _leadContactController.text.trim(),
        leadEmail: _leadEmailController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Referral submitted successfully!'), 
          backgroundColor: Colors.green, 
          behavior: SnackBarBehavior.floating
        ));
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      _showError('Failed to submit referral. Please try again.');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: Colors.redAccent, 
      behavior: SnackBarBehavior.floating
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Referral', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)
        ),
        centerTitle: false,
      ),
      body: _loadingMembers 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Generate high-quality business opportunities for your fellow members.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
                const SizedBox(height: 32),
                
                _buildSectionLabel('Target recipient'),
                _buildMemberDropdown(),
                
                const SizedBox(height: 32),
                _buildSectionLabel('Lead contact info'),
                _inputField(_leadNameController, 'Lead Full Name', TablerIcons.user),
                const SizedBox(height: 12),
                _inputField(_leadContactController, 'Phone Number', TablerIcons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _inputField(_leadEmailController, 'Email Address (Optional)', TablerIcons.mail, keyboardType: TextInputType.emailAddress),
                
                const SizedBox(height: 32),
                _buildSectionLabel('Referral details'),
                _inputField(_descriptionController, 'Explain how the recipient can help this lead...', null, maxLines: 5),
                
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: _loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT REFERRAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
    );
  }

  Widget _buildMemberDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Member>(
          value: _selectedMember,
          hint: const Text('Choose a recipient...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
          isExpanded: true,
          icon: const Icon(TablerIcons.chevron_down, size: 20, color: Colors.black),
          items: _members.map((m) => DropdownMenuItem(
            value: m, 
            child: Text('${m.fullName} (${m.industry})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black))
          )).toList(),
          onChanged: (m) => setState(() => _selectedMember = m),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData? icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primary) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}
