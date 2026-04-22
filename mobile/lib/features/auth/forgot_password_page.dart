import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/core/widgets/pbn_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _api = ApiClient();

  Future<void> _sendOtp() async {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      _showError('Please enter your email or phone number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.post('/auth/forgot-password', data: {'identifier': id});
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _showSuccess('OTP sent to your registered email');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to send OTP. Please ensure your identifier is correct.');
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter the 6-digit OTP code');
      return;
    }
    if (pass.isEmpty || pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.post('/auth/reset-password', data: {
        'identifier': _identifierController.text.trim(),
        'otp': otp,
        'new_password': pass,
        'confirm_password': confirm,
      });
      if (mounted) {
        _showSuccess('Password reset successfully! Please login.');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to reset password. Please check the OTP code.');
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otpSent ? 'Reset Password' : 'Forgot Password',
                      style: const TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent 
                        ? 'Enter the 6-digit code sent to your email and choose a new password.'
                        : 'Enter your registered email or phone number to receive a reset code.',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),

                    if (!_otpSent) ...[
                      _buildLabel('EMAIL OR PHONE'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _identifierController,
                        hint: 'Enter your credentials',
                        icon: TablerIcons.mail,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'SEND RESET CODE',
                          onPressed: _sendOtp,
                          isLoading: _isLoading,
                          backgroundColor: AppColors.accent,
                          textColor: Colors.black,
                        ),
                      ),
                    ] else ...[
                      _buildLabel('6-DIGIT OTP CODE'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _otpController,
                        hint: '••••••',
                        icon: TablerIcons.hash,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('NEW PASSWORD'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordController,
                        hint: 'Enter new password',
                        icon: TablerIcons.lock,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('CONFIRM NEW PASSWORD'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _confirmPasswordController,
                        hint: 'Repeat new password',
                        icon: TablerIcons.lock_check,
                        isPassword: true,
                        obscure: _obscurePassword,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'RESET PASSWORD',
                          onPressed: _resetPassword,
                          isLoading: _isLoading,
                          backgroundColor: AppColors.accent,
                          textColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _otpSent = false),
                          child: const Text('Change email/phone', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ],
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
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary.withOpacity(0.4), letterSpacing: 1.5));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(obscure ? TablerIcons.eye : TablerIcons.eye_off, size: 18, color: const Color(0xFF94A3B8)),
            onPressed: onToggleObscure,
          ) : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
