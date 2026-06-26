import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/features/payments/payment_service.dart';

class UploadProofPage extends StatefulWidget {
  final String paymentId;
  final double amount;

  const UploadProofPage({super.key, required this.paymentId, required this.amount});

  @override
  State<UploadProofPage> createState() => _UploadProofPageState();
}

class _UploadProofPageState extends State<UploadProofPage> {
  final _paymentService = PaymentService();
  final _referenceController = TextEditingController();
  
  File? _selectedFile;
  String? _fileName;
  bool _isPdf = false;
  bool _isLoading = false;
  String _proofType = 'bank_transfer';

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _fileName = pickedFile.name;
          _isPdf = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        if (pickedFile.path != null) {
          setState(() {
            _selectedFile = File(pickedFile.path!);
            _fileName = pickedFile.name;
            _isPdf = true;
          });
        }
      }
    } catch (_) {}
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select Payment Proof',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(TablerIcons.camera, color: AppColors.primary),
                title: Text('Take Photo', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.photo, color: AppColors.primary),
                title: Text('Choose from Gallery', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.file_type_pdf, color: AppColors.primary),
                title: Text('Upload PDF Document', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitProof() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or PDF of your payment proof')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reference = _referenceController.text.trim();
      final finalReference = reference.isNotEmpty ? '$_proofType: $reference' : _proofType;

      final success = await _paymentService.uploadPaymentProof(
        widget.paymentId,
        _isPdf ? 'pdf' : 'image',
        finalReference,
        _selectedFile!.path,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof submitted successfully. We will review it shortly!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true); // Return true indicating success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit proof. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Upload Payment Proof',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.text),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Due Premium Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.shadowMd,
              ),
              child: Column(
                children: [
                  Text(
                    'Amount Due',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LKR ${widget.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Method Selector
            _buildLabel('Payment Method'),
            DropdownButtonFormField<String>(
              initialValue: _proofType,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(TablerIcons.building_bank, size: 18, color: AppColors.textMuted),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
                ),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(TablerIcons.chevron_down, size: 18, color: AppColors.textMuted),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              items: [
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                ),
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('Cash Deposit', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                ),
                DropdownMenuItem(
                  value: 'cheque',
                  child: Text('Cheque', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _proofType = val);
              },
            ),
            const SizedBox(height: 24),

            // Reference Number Field
            _buildLabel('Reference Number (Optional)'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowBase.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _referenceController,
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'E.g. Transaction ID or Cheque No.',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(TablerIcons.hash, size: 18, color: AppColors.textMuted),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 1.6)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Receipt File/Image
            _buildLabel('Upload Receipt File / Image'),
            GestureDetector(
              onTap: _showAttachmentPicker,
              child: _selectedFile != null
                  ? (_isPdf ? _buildPdfPreview() : _buildImagePreview())
                  : _buildPlaceholder(),
            ),
            
            const SizedBox(height: 40),
            CustomButton(
              text: 'SUBMIT PAYMENT PROOF',
              onPressed: _submitProof,
              isLoading: _isLoading,
              backgroundColor: AppColors.accent,
              textColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1.5),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.cloud_upload, size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to select receipt photo or PDF',
            style: GoogleFonts.dmSans(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Supports JPG, PNG, PDF (Max 5MB)',
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1.5),
        boxShadow: AppColors.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(_selectedFile!, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.photo_edit, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Change Attachment',
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1.5),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              TablerIcons.file_type_pdf,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Payment Receipt PDF',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fileName ?? 'receipt.pdf',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Change',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
