import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/api_client.dart';

class PortfolioEditPage extends StatefulWidget {
  const PortfolioEditPage({super.key});

  @override
  State<PortfolioEditPage> createState() => _PortfolioEditPageState();
}

class _PortfolioEditPageState extends State<PortfolioEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  final _businessNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _establishedYearCtrl = TextEditingController();
  final _brNumberCtrl = TextEditingController();
  final _googleMapsUrlCtrl = TextEditingController();
  final _linkedinUrlCtrl = TextEditingController();
  final _facebookUrlCtrl = TextEditingController();
  final _instagramUrlCtrl = TextEditingController();

  String? _logoUrl;
  String? _brochureUrl;
  String? _brochureName;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _establishedYearCtrl.dispose();
    _brNumberCtrl.dispose();
    _googleMapsUrlCtrl.dispose();
    _linkedinUrlCtrl.dispose();
    _facebookUrlCtrl.dispose();
    _instagramUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    try {
      final res = await _apiClient.get('/auth/me/business');
      if (res.data != null && res.data['data'] != null) {
        final data = res.data['data'];
        _businessNameCtrl.text = data['business_name'] ?? '';
        _descriptionCtrl.text = data['description'] ?? '';
        _websiteCtrl.text = data['website'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _establishedYearCtrl.text = data['established_year'] ?? '';
        _brNumberCtrl.text = data['br_number'] ?? '';
        _googleMapsUrlCtrl.text = data['google_maps_url'] ?? '';
        _linkedinUrlCtrl.text = data['linkedin_url'] ?? '';
        _facebookUrlCtrl.text = data['facebook_url'] ?? '';
        _instagramUrlCtrl.text = data['instagram_url'] ?? '';
        _logoUrl = data['logo_url'];
        _brochureUrl = data['brochure_url'];
        if (_brochureUrl != null) {
          _brochureName = _brochureUrl!.split('/').last;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final int fileSize = await pickedFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        _showError('Logo image too large. Max size is 5MB.');
        return;
      }

      setState(() => _saving = true);

      final bytes = await pickedFile.readAsBytes();
      final fileData = MultipartFile.fromBytes(bytes, filename: pickedFile.name);
      final formData = FormData.fromMap({'file': fileData});

      final res = await _apiClient.dio.post(
        '/auth/me/business/logo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.data != null && res.data['data'] != null) {
        setState(() {
          _logoUrl = res.data['data']['logo_url'];
        });
        _showSuccess('Logo uploaded successfully!');
      }
    } catch (e) {
      _showError('Failed to upload logo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadBrochure() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        _showError('PDF Brochure too large. Max size is 10MB.');
        return;
      }

      setState(() => _saving = true);

      final bytes = file.bytes ?? await XFile(file.path!).readAsBytes();
      final fileData = MultipartFile.fromBytes(bytes, filename: file.name);
      final formData = FormData.fromMap({'file': fileData});

      final res = await _apiClient.dio.post(
        '/auth/me/business/brochure',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.data != null && res.data['data'] != null) {
        setState(() {
          _brochureUrl = res.data['data']['brochure_url'];
          _brochureName = file.name;
        });
        _showSuccess('Brochure PDF uploaded successfully!');
      }
    } catch (e) {
      _showError('Failed to upload brochure PDF.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = {
        'business_name': _businessNameCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'established_year': _establishedYearCtrl.text.trim(),
        'br_number': _brNumberCtrl.text.trim(),
        'google_maps_url': _googleMapsUrlCtrl.text.trim(),
        'linkedin_url': _linkedinUrlCtrl.text.trim(),
        'facebook_url': _facebookUrlCtrl.text.trim(),
        'instagram_url': _instagramUrlCtrl.text.trim(),
      };

      await _apiClient.put('/auth/me/business', data: payload);
      _showSuccess('Portfolio updated successfully!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to update portfolio.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiClient().dio.options.baseUrl.split('/api')[0];
    final fullLogoUrl = _logoUrl != null
        ? (_logoUrl!.startsWith('http') ? _logoUrl : '$baseUrl$_logoUrl')
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Portfolio',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'SAVE',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildLogoUploadSection(fullLogoUrl),
                  const SizedBox(height: 24),
                  _sectionHeader('Brand & Links'),
                  _buildTextField(
                    label: 'BUSINESS NAME',
                    controller: _businessNameCtrl,
                    hint: 'e.g. Acme Corp',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Business Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'WEBSITE URL',
                    controller: _websiteCtrl,
                    hint: 'https://example.com',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'LINKEDIN PROFILE',
                    controller: _linkedinUrlCtrl,
                    hint: 'https://linkedin.com/in/...',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'FACEBOOK PAGE',
                    controller: _facebookUrlCtrl,
                    hint: 'https://facebook.com/...',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'INSTAGRAM HANDLE',
                    controller: _instagramUrlCtrl,
                    hint: 'https://instagram.com/...',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader('Deep Business Info'),
                  _buildTextField(
                    label: 'BUSINESS REGISTRATION (BR) NUMBER',
                    controller: _brNumberCtrl,
                    hint: 'BR123456',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'ESTABLISHED YEAR',
                    controller: _establishedYearCtrl,
                    hint: 'e.g. 2018',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'PHYSICAL ADDRESS',
                    controller: _addressCtrl,
                    hint: 'Full business address...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'GOOGLE MAPS LINK',
                    controller: _googleMapsUrlCtrl,
                    hint: 'https://maps.app.goo.gl/...',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'BUSINESS DESCRIPTION',
                    controller: _descriptionCtrl,
                    hint: 'Tell other members what you do...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader('Media & Assets'),
                  _buildBrochureUploadSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUploadSection(String? fullLogoUrl) {
    return Center(
      child: Column(
        children: [
          Text(
            'BUSINESS LOGO',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saving ? null : _pickAndUploadLogo,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: AppColors.shadowSm,
                image: fullLogoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(fullLogoUrl),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: fullLogoUrl == null
                  ? const Icon(
                      TablerIcons.photo_plus,
                      color: AppColors.textMuted,
                      size: 28,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload logo image (JPG/PNG)',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
          )
        ],
      ),
    );
  }

  Widget _buildBrochureUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              TablerIcons.file_type_pdf,
              color: AppColors.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Profile / PDF Brochure',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _brochureName ?? 'No document selected',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : _pickAndUploadBrochure,
            icon: const Icon(TablerIcons.upload, color: AppColors.primary),
            tooltip: 'Upload Brochure',
          ),
        ],
      ),
    );
  }
}
