import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Redemption',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.text,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(TablerIcons.x, color: AppColors.text),
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
          // Partner & Offer Info — navy gradient with ambient gold glow
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.28),
                                    AppColors.accent.withValues(alpha: 0.10),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.55),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _tokenResult!.partnerName.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _tokenResult!.offerTitle,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // QR Code Card — premium surface gradient
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.surfaceGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              boxShadow: AppColors.shadowMd,
            ),
            child: Column(
              children: [
                Text(
                  'Store Redemption QR',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Present this to the partner for scanning',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Gold-ringed QR
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.goldSoftGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: QrImageView(
                      data: _tokenResult!.qrUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Countdown — gold-tinted
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.18),
                        AppColors.accent.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(TablerIcons.clock,
                          size: 15, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${_formatDuration(_remaining)}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Polling indicator
          Align(
            alignment: Alignment.center,
            child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Awaiting partner verification…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ),
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
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withValues(alpha: 0.1),
                        blurRadius: 40),
                  ],
                ),
                child:
                    Icon(TablerIcons.circle_check, size: 56, color: Colors.green.shade600),
              ),
              const SizedBox(height: 32),
              const Text(
                'Redeemed! 🎉',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              Text(
                'Your exclusive offer has been successfully claimed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.5),
              ),
              if (_signerName != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                  child: Text(
                    'Partner: $_signerName',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade100, width: 2),
              ),
              child: Icon(TablerIcons.clock_off, size: 56, color: Colors.red.shade600),
            ),
            const SizedBox(height: 32),
            const Text(
              'Session Expired',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Text(
              'The security token has expired. Please initiate redemption again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.grey, width: 1.5)),
                  elevation: 0,
                ),
                child: const Text('GO BACK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade100, width: 2),
              ),
              child:
                  Icon(TablerIcons.alert_triangle, size: 56, color: Colors.orange.shade600),
            ),
            const SizedBox(height: 32),
            const Text(
              'System Error',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
