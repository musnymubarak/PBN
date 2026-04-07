import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/reward_service.dart';
import 'package:pbn/models/reward.dart';

/// Full-screen modal that displays the QR code and polls for confirmation.
class QrRedeemScreen extends StatefulWidget {
  final String offerId;
  final String offerTitle;
  final String partnerName;

  const QrRedeemScreen({
    super.key,
    required this.offerId,
    required this.offerTitle,
    required this.partnerName,
  });

  @override
  State<QrRedeemScreen> createState() => _QrRedeemScreenState();
}

class _QrRedeemScreenState extends State<QrRedeemScreen>
    with SingleTickerProviderStateMixin {
  final _service = RewardService();

  RedeemTokenResult? _tokenResult;
  bool _loading = true;
  String? _error;

  // Polling
  Timer? _pollTimer;
  bool _confirmed = false;
  String? _signerName;

  // Countdown
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _expired = false;

  // Animation
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    _initiateRedeem();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _initiateRedeem() async {
    try {
      final result = await _service.initiateRedeem(widget.offerId);
      if (!mounted) return;
      setState(() {
        _tokenResult = result;
        _loading = false;
        _remaining = result.expiresAt.difference(DateTime.now());
      });
      _startCountdown();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _tokenResult!.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        setState(() {
          _expired = true;
          _remaining = Duration.zero;
        });
        _countdownTimer?.cancel();
        _pollTimer?.cancel();
        return;
      }
      setState(() => _remaining = remaining);
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _confirmed || _expired) return;
      try {
        final status =
            await _service.checkRedemptionStatus(_tokenResult!.token);
        if (!mounted) return;

        if (status.isConfirmed) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          setState(() {
            _confirmed = true;
            _signerName = status.signerName;
          });
          _celebrationController.forward();
        } else if (status.isExpired || status.isCancelled) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          setState(() => _expired = true);
        }
      } catch (_) {
        // Silently retry
      }
    });
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Redeem Offer',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, _confirmed),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _confirmed
                  ? _buildSuccess()
                  : _expired
                      ? _buildExpired()
                      : _buildQrView(),
    );
  }

  Widget _buildQrView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Partner & Offer Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0A2540), Color(0xFF1E3A8A)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tokenResult!.partnerName.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  _tokenResult!.offerTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Show this QR to the store',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  'The partner will scan this to verify your offer',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: _tokenResult!.qrUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A2540),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A2540),
                  ),
                ),
                const SizedBox(height: 20),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: Color(0xFF92400E)),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${_formatDuration(_remaining)}',
                        style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instruction
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'After scanning, you\'ll need to sign on the partner\'s device to claim this offer.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Polling indicator
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for partner to confirm...',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        blurRadius: 30),
                  ],
                ),
                child:
                    const Icon(Icons.check, size: 56, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Offer Claimed! 🎉',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '${_tokenResult!.offerTitle} has been successfully redeemed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              if (_signerName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Signed by: $_signerName',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off, size: 56, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Code Expired',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'This QR code has expired. Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
