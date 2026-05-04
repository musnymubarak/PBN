import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/matchmaking_service.dart';
import 'package:pbn/models/matchmaking.dart';

class BusinessMatchingProfilePage extends StatefulWidget {
  const BusinessMatchingProfilePage({super.key});

  @override
  State<BusinessMatchingProfilePage> createState() => _BusinessMatchingProfilePageState();
}

class _BusinessMatchingProfilePageState extends State<BusinessMatchingProfilePage> {
  final _service = MatchmakingService();
  final _descriptionCtrl = TextEditingController();
  final _servicesCtrl = TextEditingController();
  final _lookingForCtrl = TextEditingController();
  final _sectorsCtrl = TextEditingController();
  
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.getProfile();
      if (mounted) {
        setState(() {
          _descriptionCtrl.text = profile.businessDescription ?? '';
          _servicesCtrl.text = profile.servicesOffered.join(', ');
          _lookingForCtrl.text = profile.lookingFor.join(', ');
          _sectorsCtrl.text = profile.targetSectors.join(', ');
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _service.updateProfile({
        'business_description': _descriptionCtrl.text.trim(),
        'services_offered': _servicesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'looking_for': _lookingForCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'target_sectors': _sectorsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matching profile updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MATCHING PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            ),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildField(
                label: 'BUSINESS DESCRIPTION',
                hint: 'Briefly describe what your business does...',
                controller: _descriptionCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _buildField(
                label: 'SERVICES YOU OFFER',
                hint: 'e.g. Web Design, SEO, Hosting (comma separated)',
                controller: _servicesCtrl,
              ),
              const SizedBox(height: 24),
              _buildField(
                label: 'WHAT ARE YOU LOOKING FOR?',
                hint: 'e.g. Legal Advice, Office Space (comma separated)',
                controller: _lookingForCtrl,
              ),
              const SizedBox(height: 24),
              _buildField(
                label: 'TARGET SECTORS',
                hint: 'e.g. Real Estate, Healthcare (comma separated)',
                controller: _sectorsCtrl,
              ),
              const SizedBox(height: 40),
              const Text(
                'Tip: The more specific you are, the better our AI can find compatible partners for you.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(TablerIcons.sparkles, size: 48, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Optimize Your Matches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text)),
        const SizedBox(height: 8),
        Text(
          'Tell us what you do and who you want to meet to get better business recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required String hint, required TextEditingController controller, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }
}
