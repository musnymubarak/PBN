import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (success && mounted) {
      setState(() => _otpSent = true);
    } else if (mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('OTP must be 6 digits');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_phoneController.text.trim(), otp);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Premium Header ──────────────────────────
            Container(
              height: MediaQuery.of(context).size.height * 0.38,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF030D16),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(55), bottomRight: Radius.circular(55)),
              ),
              child: Stack(
                children: [
                  Positioned(right: -50, top: -50,
                    child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.5))),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Hero(tag: 'logo',
                              child: Image.asset('assets/logo.png', height: 110, fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(TablerIcons.briefcase, size: 80, color: AppColors.accent),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('PRIME BUSINESS NETWORK', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Form ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_otpSent ? 'Verify OTP' : 'Welcome',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(_otpSent ? 'Enter the 6-digit code sent to your phone' : 'Sign in with your phone number',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, fontSize: 15),
                  ),
                  const SizedBox(height: 40),

                  if (!_otpSent) ...[
                    Text('PHONE NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '+94XXXXXXXXX', prefixIcon: Icon(TablerIcons.phone, size: 20), filled: true, fillColor: Color(0xFFF9FAFB)),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'SEND OTP',
                      onPressed: _handleSendOtp,
                      isLoading: auth.loading,
                    ),
                  ],

                  if (_otpSent) ...[
                    Text('VERIFICATION CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(hintText: '------', counterText: '', filled: true, fillColor: Color(0xFFF9FAFB)),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'VERIFY & LOGIN',
                      onPressed: _handleVerifyOtp,
                      isLoading: auth.loading,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() { _otpSent = false; _otpController.clear(); }),
                        child: const Text('Change phone number', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("New to Prime Network?", style: TextStyle(color: Colors.grey.shade500)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/apply'),
                          child: const Text('Apply Now', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
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
    );
  }
}
