import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pbn/core/theme/app_theme.dart';
import 'package:pbn/features/partner/services/partner_service.dart';

class PartnerScanPage extends StatefulWidget {
  const PartnerScanPage({super.key});

  @override
  State<PartnerScanPage> createState() => _PartnerScanPageState();
}

class _PartnerScanPageState extends State<PartnerScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final PartnerService _partnerService = PartnerService();
  bool _isProcessing = false;

  final TextEditingController _manualController = TextEditingController();

  Future<void> _processScan(String qrData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // QR Data might be the full URL (e.g. http://localhost:8000/verify/XYZ)
    // We just need the UUID token from the end.
    String token = qrData;
    if (qrData.contains('/verify/')) {
      token = qrData.split('/verify/').last;
    }

    try {
      final result = await _partnerService.scanToken(token);
      if (!mounted) return;
      
      _scannerController.stop();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✅ Offer Claimed!'),
          content: Text('${result['user_name']} has successfully redeemed ${result['offer_title']}!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // go back to dashboard
              },
              child: const Text('OK'),
            )
          ],
        )
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan User QR')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      _processScan(barcodes.first.rawValue!);
                    }
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                // Overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Align QR code within the frame to scan automatically.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          decoration: const InputDecoration(
                            hintText: 'Or enter token UUID manually (Dev)',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_manualController.text.isNotEmpty) {
                            _processScan(_manualController.text);
                          }
                        },
                        child: const Text('Submit'),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
