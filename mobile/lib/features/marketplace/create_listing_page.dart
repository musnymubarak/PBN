import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/services/application_service.dart';
import 'package:pbn/core/services/marketplace_service.dart';
import 'package:pbn/models/marketplace.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/models/chapter.dart';

class CreateListingPage extends StatefulWidget {
  final MarketplaceListing? listing; // If provided, we are editing

  const CreateListingPage({super.key, this.listing});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
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

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _titleController = TextEditingController(text: widget.listing?.title);
    _descController = TextEditingController(text: widget.listing?.description);
    _regPriceController = TextEditingController(text: widget.listing?.regularPrice?.toString());
    _memPriceController = TextEditingController(text: widget.listing?.memberPrice?.toString());
    _priceNoteController = TextEditingController(text: widget.listing?.priceNote);
    
    // Pre-fill contact info from user profile if NEW listing
    _whatsappController = TextEditingController(text: widget.listing?.whatsappNumber ?? user?.phoneNumber);
    _emailController = TextEditingController(text: widget.listing?.contactEmail ?? user?.email);
    _phoneController = TextEditingController(text: widget.listing?.contactPhone ?? user?.phoneNumber);
    
    if (widget.listing != null) {
      _category = widget.listing!.category;
      _selectedIndustryId = widget.listing!.industryCategoryId;
    }
    
    _loadIndustries();
  }

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
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
        if (_images.length > 5) _images = _images.sublist(0, 5);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIndustryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an industry')));
      return;
    }

    setState(() => _submitting = true);
    try {
      // Real Upload:
      List<String> imageUrls = widget.listing?.imageUrls ?? [];
      
      if (_images.isNotEmpty) {
        final List<String> uploadedUrls = [];
        for (var image in _images) {
          final url = await _marketService.uploadImage(image.path);
          uploadedUrls.add(ApiConfig.staticUrl + url);
        }
        imageUrls = uploadedUrls;
      }

      if (widget.listing == null) {
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
          SnackBar(content: Text(widget.listing == null ? 'Listing posted!' : 'Listing updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save listing')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.listing == null ? 'Post New Listing' : 'Edit Listing',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    const Text('Product Images (Max 5)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: const Icon(TablerIcons.camera_plus, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ..._images.map((img) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildLabel('Title *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration('e.g. Premium Office Furniture'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Category'),
                    DropdownButtonFormField<ListingCategory>(
                      value: _category,
                      decoration: _buildInputDecoration('Select category'),
                      items: ListingCategory.values.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      )).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Industry *'),
                    DropdownButtonFormField<String>(
                      value: _selectedIndustryId,
                      decoration: _buildInputDecoration('Select industry'),
                      items: _industries.map((i) => DropdownMenuItem(
                        value: i.id,
                        child: Text(i.name),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIndustryId = v),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Description *'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: _buildInputDecoration('Describe your product or service in detail...'),
                      validator: (v) => (v == null || v.length < 10) ? 'Description too short' : null,
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),

                    const Text('Pricing Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Regular Price (LKR)'),
                              TextFormField(
                                controller: _regPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration('e.g. 50000'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Member Price (LKR)'),
                              TextFormField(
                                controller: _memPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration('e.g. 45000'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Price Note (Optional)'),
                    TextFormField(
                      controller: _priceNoteController,
                      decoration: _buildInputDecoration('e.g. Starting from / Per hour'),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),

                    const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 20),

                    _buildLabel('WhatsApp Number'),
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration('e.g. +94777123456'),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Contact Email'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('e.g. sales@mybusiness.com'),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Contact Phone'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration('e.g. 0112345678'),
                    ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(widget.listing == null ? 'Post Listing' : 'Save Changes',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
