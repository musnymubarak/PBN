import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/models/chapter.dart';

class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});
  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final _service = ApplicationService();
  int _currentStep = 0;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  
  List<IndustryCategory> _categories = [];
  IndustryCategory? _selectedCategory;
  bool _loadingCategories = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _service.getIndustryCategories();
    } catch (_) {}
    if (mounted) setState(() => _loadingCategories = false);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _businessCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _districtCtrl.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.submitApplication(
        fullName: _nameCtrl.text.trim(),
        businessName: _businessCtrl.text.trim(),
        contactNumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        industryCategoryId: _selectedCategory!.id,
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(TablerIcons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Application Sent!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 12),
            Text('We will review your application and get back to you soon.', 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(text: 'DONE', onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }, backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BECOME A MEMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2)),
            Text('PBN Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
          ],
        ),
      ),
      body: _loadingCategories 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0 ? _buildBusinessStep() : _buildPersonalStep(),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _stepDot(0, 'Business'),
          Expanded(child: Container(height: 2, color: _currentStep > 0 ? AppColors.primary : Colors.grey.shade200)),
          _stepDot(1, 'Personal'),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    bool active = _currentStep == index;
    bool completed = _currentStep > index;
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active || completed ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active || completed ? AppColors.primary : Colors.grey.shade300, width: 2),
            boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10)] : null,
          ),
          child: Center(
            child: completed 
              ? const Icon(TablerIcons.check, size: 16, color: Colors.white)
              : Text('${index + 1}', style: TextStyle(color: active ? Colors.white : Colors.grey.shade400, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w900 : FontWeight.w700, color: active ? AppColors.primary : Colors.grey.shade400, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _instruction('Tell us about your business to help us find the right chapter.'),
        const SizedBox(height: 32),
        _modernField(_businessCtrl, 'Company Name', TablerIcons.building),
        const SizedBox(height: 20),
        _modernField(_districtCtrl, 'Working District', TablerIcons.map_pin),
        const SizedBox(height: 20),
        const Text('INDUSTRY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        _industryDropdown(),
        const SizedBox(height: 48),
        CustomButton(text: 'CONTINUE', onPressed: () => setState(() => _currentStep = 1), backgroundColor: AppColors.primary),
      ],
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _instruction('How should we reach out to you once reviewed?'),
        const SizedBox(height: 32),
        _modernField(_nameCtrl, 'Full Name', TablerIcons.user),
        const SizedBox(height: 20),
        _modernField(_emailCtrl, 'Email Address', TablerIcons.mail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _modernField(_phoneCtrl, 'Contact Number', TablerIcons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('BACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
            )),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: CustomButton(text: 'SUBMIT APPLICATION', onPressed: _submit, isLoading: _submitting, backgroundColor: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _instruction(String text) {
    return Text(text, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.5));
  }

  Widget _modernField(TextEditingController c, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter $hint...',
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade100)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _industryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IndustryCategory>(
          value: _selectedCategory,
          hint: const Text('Select your industry...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          isExpanded: true,
          icon: const Icon(TablerIcons.chevron_down, size: 18),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))).toList(),
          onChanged: (c) => setState(() => _selectedCategory = c),
        ),
      ),
    );
  }
}
