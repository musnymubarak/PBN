import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/core/widgets/pbn_logo.dart';

class TfaVerifyPage extends StatefulWidget {
  const TfaVerifyPage({super.key});

  @override
  State<TfaVerifyPage> createState() => _TfaVerifyPageState();
}

class _TfaVerifyPageState extends State<TfaVerifyPage> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Please enter the 6-digit verification code');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verify2FA(otp);

    if (success && mounted) {
      TextInput.finishAutofillContext();
      if (auth.user?.role == 'PARTNER_ADMIN') {
        Navigator.pushNamedAndRemoveUntil(context, '/partner_dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } else if (mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _handleResend() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.resend2FA();
    if (success && mounted) {
      _showSuccess('A new verification code has been sent.');
      _startTimer();
    } else if (mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const PbnLogo(size: 80),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Two-Factor Verification',
                      style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit verification code sent to your registered email to continue.',
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('6-DIGIT OTP CODE'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _otpController,
                      hint: '••••••',
                      icon: TablerIcons.hash,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _canResend 
                              ? 'Didn\'t receive the code?' 
                              : 'Resend code in ${_secondsRemaining}s',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: auth.loading ? null : _handleResend,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Resend Code', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'VERIFY & CONTINUE',
                        onPressed: _handleVerify,
                        isLoading: auth.loading,
                        backgroundColor: AppColors.accent,
                        textColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary.withValues(alpha: 0.4), letterSpacing: 1.5));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 8, color: AppColors.text),
        maxLength: 6,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          counterText: '',
        ),
      ),
    );
  }
}
