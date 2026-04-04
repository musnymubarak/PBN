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
  void initState() { super.initState(); _loadCategories(); }

  Future<void> _loadCategories() async {
    try { _categories = await _service.getIndustryCategories(); } catch (_) {}
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!'),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Apply to PBN',
        style: TextStyle(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(TablerIcons.file_plus, color: AppColors.accent, size: 32),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Join Prime Business Network',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Fill in your details to start your application',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          _label('FULL NAME'), const SizedBox(height: 6),
          _field(_nameCtrl, 'Your full name', TablerIcons.user),
          const SizedBox(height: 16),
          _label('BUSINESS NAME'), const SizedBox(height: 6),
          _field(_businessCtrl, 'Company name', TablerIcons.building),
          const SizedBox(height: 16),
          _label('CONTACT NUMBER'), const SizedBox(height: 6),
          _field(_phoneCtrl, '+94XXXXXXXXX', TablerIcons.phone,
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _label('EMAIL'), const SizedBox(height: 6),
          _field(_emailCtrl, 'email@example.com', TablerIcons.mail,
            keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('DISTRICT'), const SizedBox(height: 6),
          _field(_districtCtrl, 'Colombo', TablerIcons.map_pin),
          const SizedBox(height: 16),
          _label('INDUSTRY'), const SizedBox(height: 6),
          _loadingCategories
              ? const Center(child: Padding(padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary)))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<IndustryCategory>(
                      value: _selectedCategory,
                      hint: const Text('Select industry...'),
                      isExpanded: true,
                      items: _categories.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (c) => setState(() => _selectedCategory = c),
                    )),
                ),
          const SizedBox(height: 32),
          CustomButton(text: 'SUBMIT APPLICATION',
            onPressed: _submit, isLoading: _submitting),
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: TextStyle(
    fontSize: 11, fontWeight: FontWeight.w800,
    color: Colors.grey.shade400, letterSpacing: 1.2));

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: c, keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
