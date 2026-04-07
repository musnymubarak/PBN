import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'dart:ui';
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
    
    String formattedPhone = _phoneCtrl.text.trim().replaceAll(' ', '');
    // Standardize to Sri Lanka format +94XXXXXXXXX
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+94${formattedPhone.substring(1)}';
    } else if (formattedPhone.startsWith('94')) {
      formattedPhone = '+$formattedPhone';
    } else if (!formattedPhone.startsWith('+') && formattedPhone.length == 9) {
      formattedPhone = '+94$formattedPhone';
    }

    try {
      await _service.submitApplication(
        fullName: _nameCtrl.text.trim(),
        businessName: _businessCtrl.text.trim(),
        contactNumber: formattedPhone,
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background Image with Scrim ──────────────────────────
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=1200',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF0F172A)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.9), const Color(0xFF0F172A).withOpacity(0.75), Colors.black.withOpacity(0.95)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(TablerIcons.arrow_left, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BECOME A MEMBER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          Text('PBN Application', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                _buildProgressIndicator(),

                Expanded(
                  child: _loadingCategories 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: _currentStep == 0 ? _buildBusinessStep() : _buildPersonalStep(),
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      child: Row(
        children: [
          _stepDot(0, 'Business'),
          Expanded(child: Container(height: 2, color: _currentStep > 0 ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.1))),
          _stepDot(1, 'Personal'),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    bool active = _currentStep == index;
    bool completed = _currentStep > index;
    final themeColor = const Color(0xFFF59E0B);
    
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: active || completed ? themeColor : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: active || completed ? themeColor : Colors.white.withOpacity(0.1), width: 2),
            boxShadow: active ? [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 15)] : null,
          ),
          child: Center(
            child: completed 
              ? const Icon(TablerIcons.check, size: 18, color: Colors.black)
              : Text('${index + 1}', style: TextStyle(color: active ? Colors.black : Colors.white38, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: active ? themeColor : Colors.white38, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 1 of 2', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('Business Intelligence', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text('Tell us about your company to match you with the right network chapter.', 
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
        const SizedBox(height: 40),
        _modernField(_businessCtrl, 'Company Name', TablerIcons.building),
        const SizedBox(height: 24),
        _modernField(_districtCtrl, 'Working District', TablerIcons.map_pin),
        const SizedBox(height: 24),
        const Text('INDUSTRY SECTOR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        _industryDropdown(),
        const SizedBox(height: 48),
        CustomButton(text: 'CONTINUE TO PERSONAL', onPressed: () => setState(() => _currentStep = 1)),
      ],
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2 of 2', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('Lead Representative', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text('Provide your primary contact details for our membership review board.', 
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
        const SizedBox(height: 40),
        _modernField(_nameCtrl, 'Full Name', TablerIcons.user),
        const SizedBox(height: 24),
        _modernField(_emailCtrl, 'Email Address', TablerIcons.mail, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 24),
        _modernField(_phoneCtrl, 'Direct Contact', TablerIcons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('BACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38)),
            )),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: CustomButton(text: 'SUBMIT APPLICATION', onPressed: _submit, isLoading: _submitting)),
          ],
        ),
      ],
    );
  }

  Widget _modernField(TextEditingController c, String label, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        TextField(
          controller: c,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Enter $label...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(icon, size: 20, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _industryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IndustryCategory>(
          value: _selectedCategory,
          dropdownColor: const Color(0xFF1E293B),
          hint: Text('Select your industry...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.3))),
          isExpanded: true,
          icon: const Icon(TablerIcons.chevron_down, size: 18, color: Colors.white38),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))).toList(),
          onChanged: (c) => setState(() => _selectedCategory = c),
        ),
      ),
    );
  }
}

