import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/models/chapter.dart';
import 'package:pbn/models/marketplace.dart';

class CreateListingPage extends StatefulWidget {
  final MarketplaceListing? listing; // edit mode if provided

  const CreateListingPage({super.key, this.listing});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _marketService = MarketplaceService();
  final _appService = ApplicationService();
  final _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _regPriceController;
  late TextEditingController _memPriceController;
  late TextEditingController _priceNoteController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  ListingCategory _category = ListingCategory.product;
  String? _selectedIndustryId;
  List<IndustryCategory> _industries = [];
  List<XFile> _images = [];
  bool _loading = false;
  bool _submitting = false;

  bool get _isEdit => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _titleController = TextEditingController(text: widget.listing?.title);
    _descController =
        TextEditingController(text: widget.listing?.description);
    _regPriceController =
        TextEditingController(text: widget.listing?.regularPrice?.toString());
    _memPriceController =
        TextEditingController(text: widget.listing?.memberPrice?.toString());
    _priceNoteController =
        TextEditingController(text: widget.listing?.priceNote);
    _whatsappController = TextEditingController(
        text: widget.listing?.whatsappNumber ?? user?.phoneNumber);
    _emailController = TextEditingController(
        text: widget.listing?.contactEmail ?? user?.email);
    _phoneController = TextEditingController(
        text: widget.listing?.contactPhone ?? user?.phoneNumber);

    if (_isEdit) {
      _category = widget.listing!.category;
      _selectedIndustryId = widget.listing!.industryCategoryId;
    }

    _loadIndustries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _regPriceController.dispose();
    _memPriceController.dispose();
    _priceNoteController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // DATA
  // ──────────────────────────────────────────────────────────
  Future<void> _loadIndustries() async {
    setState(() => _loading = true);
    try {
      final items = await _appService.getIndustryCategories();
      setState(() {
        _industries = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    HapticFeedback.selectionClick();
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
        if (_images.length > _maxImages) {
          _images = _images.sublist(0, _maxImages);
        }
      });
    }
  }

  void _removeImage(int index) {
    HapticFeedback.selectionClick();
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIndustryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an industry')),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _submitting = true);
    try {
      List<String> imageUrls = widget.listing?.imageUrls ?? [];

      if (_images.isNotEmpty) {
        final List<String> uploadedUrls = [];
        for (var image in _images) {
          final url = await _marketService.uploadImage(image.path);
          uploadedUrls.add(ApiConfig.staticUrl + url);
        }
        imageUrls = uploadedUrls;
      }

      if (!_isEdit) {
        await _marketService.createListing(
          title: _titleController.text,
          description: _descController.text,
          category: _category,
          industryCategoryId: _selectedIndustryId!,
          regularPrice: double.tryParse(_regPriceController.text),
          memberPrice: double.tryParse(_memPriceController.text),
          priceNote: _priceNoteController.text,
          imageUrls: imageUrls,
          whatsappNumber: _whatsappController.text,
          contactEmail: _emailController.text,
          contactPhone: _phoneController.text,
        );
      } else {
        await _marketService.updateListing(
          widget.listing!.id,
          title: _titleController.text,
          description: _descController.text,
          category: _category,
          industryCategoryId: _selectedIndustryId,
          regularPrice: double.tryParse(_regPriceController.text),
          memberPrice: double.tryParse(_memPriceController.text),
          priceNote: _priceNoteController.text,
          imageUrls: imageUrls,
          whatsappNumber: _whatsappController.text,
          contactEmail: _emailController.text,
          contactPhone: _phoneController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Listing updated!' : 'Listing posted!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save listing')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(
          _isEdit ? 'Edit Listing' : 'Post a Listing',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Images',
                        trailing: '${_images.length}/$_maxImages'),
                    _buildImagePicker(),
                    const SizedBox(height: 22),
                    _sectionHeader('Listing Details'),
                    _buildLabel('Title'),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g. Premium Office Furniture',
                      icon: TablerIcons.text_caption,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Category'),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildLabel('Industry'),
                    _buildIndustryDropdown(),
                    const SizedBox(height: 16),
                    _buildLabel('Description'),
                    _buildTextField(
                      controller: _descController,
                      hint:
                          'Describe your product or service in detail…',
                      icon: TablerIcons.align_left,
                      maxLines: 4,
                      validator: (v) => (v == null || v.length < 10)
                          ? 'Description too short'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    _sectionHeader('Pricing'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Regular Price (LKR)'),
                              _buildTextField(
                                controller: _regPriceController,
                                hint: 'e.g. 50000',
                                icon: TablerIcons.currency_dollar,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Member Price (LKR)'),
                              _buildTextField(
                                controller: _memPriceController,
                                hint: 'e.g. 45000',
                                icon: TablerIcons.discount_check,
                                iconTint: AppColors.accent,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Price Note (optional)'),
                    _buildTextField(
                      controller: _priceNoteController,
                      hint: 'e.g. Starting from / Per hour',
                      icon: TablerIcons.info_circle,
                    ),
                    const SizedBox(height: 22),
                    _sectionHeader('Contact'),
                    _buildLabel('WhatsApp Number'),
                    _buildTextField(
                      controller: _whatsappController,
                      hint: 'e.g. +94777123456',
                      icon: TablerIcons.brand_whatsapp,
                      iconTint: AppColors.success,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Contact Email'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'e.g. sales@mybusiness.com',
                      icon: TablerIcons.mail,
                      iconTint: AppColors.accent,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Contact Phone'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'e.g. 0112345678',
                      icon: TablerIcons.phone,
                      iconTint: AppColors.accentBlue,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 12),
                    _buildModerationFootnote(),
                  ],
                ),
              ),
            ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION HEADER (P-1)
  // ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.accent.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.28)),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // IMAGE PICKER
  // ──────────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    final canAddMore = _images.length < _maxImages;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          if (canAddMore)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.surfaceGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.goldGradient),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: AppColors.goldGlow,
                        ),
                        child: const Icon(TablerIcons.camera_plus,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _images.isEmpty ? 'ADD PHOTOS' : 'ADD MORE',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (canAddMore && _images.isNotEmpty) const SizedBox(width: 10),
          for (var i = 0; i < _images.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _buildImagePreview(i),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(int i) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              File(_images[i].path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AppColors.error,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _removeImage(i),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(TablerIcons.x, color: Colors.white, size: 11),
              ),
            ),
          ),
        ),
        if (i == 0)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.goldGradient),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'COVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // FIELDS
  // ──────────────────────────────────────────────────────────
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Color? iconTint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.dmSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.1,
      ),
      decoration: _inputDecoration(hint: hint, icon: icon, iconTint: iconTint),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Color? iconTint,
  }) {
    final tint = iconTint ?? AppColors.textMuted;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(icon, color: tint, size: 16),
            ),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 36, minHeight: 36),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ListingCategory>(
      initialValue: _category,
      style: GoogleFonts.dmSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      decoration: _inputDecoration(
        hint: 'Select category',
        icon: TablerIcons.category,
      ),
      items: ListingCategory.values
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(
                  _categoryLabel(c),
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          HapticFeedback.selectionClick();
          setState(() => _category = v);
        }
      },
    );
  }

  String _categoryLabel(ListingCategory c) {
    switch (c) {
      case ListingCategory.product:
        return 'Product';
      case ListingCategory.service:
        return 'Service';
      case ListingCategory.consultation:
        return 'Consultation';
    }
  }

  Widget _buildIndustryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedIndustryId,
      isExpanded: true,
      style: GoogleFonts.dmSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      decoration: _inputDecoration(
        hint: 'Select industry',
        icon: TablerIcons.briefcase,
      ),
      items: _industries
          .map((i) => DropdownMenuItem(
                value: i.id,
                child: Text(
                  i.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ))
          .toList(),
      onChanged: (v) {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndustryId = v);
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // SUBMIT
  // ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _submitting ? null : _submit,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: _submitting
                  ? LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.5),
                        AppColors.accent.withValues(alpha: 0.35),
                      ],
                    )
                  : const LinearGradient(
                      colors: AppColors.goldGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _submitting ? null : AppColors.goldGlow,
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEdit
                              ? TablerIcons.device_floppy
                              : TablerIcons.send,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEdit ? 'SAVE CHANGES' : 'POST LISTING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModerationFootnote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'Listings are reviewed before going live. You\'ll be notified when approved.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.textMuted,
          height: 1.5,
        ),
      ),
    );
  }
}
