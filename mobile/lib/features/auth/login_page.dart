import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/widgets/custom_button.dart';
import 'package:pbn/core/widgets/pbn_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    
    if (identifier.isEmpty || password.isEmpty) {
      _showError('Please enter both your email/phone and password');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(identifier, password);
    
    if (success && mounted) {
      if (auth.user?.role == 'PARTNER_ADMIN') {
        Navigator.pushReplacementNamed(context, '/partner_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── DECORATIVE SOFT ACCENTS ──────────────────────────
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.03),
              ),
            ),
          ),

          // ── MAIN CONTENT ─────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Premium Static Logo
                  const PbnLogo(size: 110),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 5),
                      children: [
                        TextSpan(text: 'PRIME ', style: TextStyle(color: Color(0xFF0F172A))),
                        TextSpan(text: 'BUSINESS ', style: TextStyle(color: AppColors.accent)),
                        TextSpan(text: 'NETWORK', style: TextStyle(color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('EXECUTIVE PORTAL', 
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3)
                  ),
                  const SizedBox(height: 30),

                  // Premium Form Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        const Text('Log In', style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Secure Executive Access', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),

                        _buildLabel('EMAIL OR PHONE'),
                        const SizedBox(height: 8),
                        _buildPremiumTextField(
                          controller: _identifierController,
                          hint: 'Enter credentials',
                          icon: TablerIcons.mail,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('PASSWORD'),
                        const SizedBox(height: 8),
                        _buildPremiumTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: TablerIcons.lock,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text('Forgot Password?', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'LOG IN TO DASHBOARD',
                            onPressed: _handleLogin,
                            isLoading: auth.loading,
                            backgroundColor: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Text("Join our elite partner network?", 
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, '/apply'),
                                child: const Text('Apply for Membership', 
                                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 13, decoration: TextDecoration.underline)
                                ),
                              ),
                            ],
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
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary.withOpacity(0.4), letterSpacing: 1.5));
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.01)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(obscure ? TablerIcons.eye : TablerIcons.eye_off, size: 18, color: const Color(0xFF94A3B8)),
            onPressed: onToggleObscure,
          ) : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
        ),
      ),
    );
  }
}

