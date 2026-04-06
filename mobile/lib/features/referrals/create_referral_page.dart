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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Referral', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingMembers 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            child: Column(children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionCard(
                    title: 'TARGET MEMBER',
                    icon: TablerIcons.users,
                    child: _buildMemberDropdown(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'LEAD DETAILS',
                    icon: TablerIcons.user_plus,
                    child: Column(children: [
                      _inputField(_leadNameController, 'Full Name', TablerIcons.user),
                      const SizedBox(height: 16),
                      _inputField(_leadContactController, 'Phone Number', TablerIcons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _inputField(_leadEmailController, 'Email Address', TablerIcons.mail, keyboardType: TextInputType.emailAddress),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'REFERRAL DESCRIPTION',
                    icon: TablerIcons.notes,
                    child: _inputField(_descriptionController, 'Explain how the member can help this lead...', null, maxLines: 5),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'SUBMIT REFERRAL', 
                    onPressed: _submit, 
                    isLoading: _loading,
                    backgroundColor: AppColors.accent,
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ]),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Text(
        'Generate more business for your fellow chapter members.',
        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
        ]),
        const Divider(height: 30),
        child,
      ]),
    );
  }

  Widget _buildMemberDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Member>(
          value: _selectedMember,
          hint: const Text('Choose a person...', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: _members.map((m) => DropdownMenuItem(
            value: m, 
            child: Text('${m.fullName} (${m.industry})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.4)) : null,
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
