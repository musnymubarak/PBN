import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      TextInput.finishAutofillContext();
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── DECORATIVE SOFT ACCENTS ──────────────────────────
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── MAIN CONTENT ─────────────────────────────
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
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
                        TextSpan(text: 'PRIME ', style: TextStyle(color: AppColors.primary)),
                        TextSpan(text: 'BUSINESS ', style: TextStyle(color: AppColors.accent)),
                        TextSpan(text: 'NETWORK', style: TextStyle(color: AppColors.primary)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.surfaceGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowBase.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Log In', style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Secure Executive Access', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),

                        _buildLabel('EMAIL OR PHONE'),
                        const SizedBox(height: 8),
                        _buildPremiumTextField(
                          controller: _identifierController,
                          hint: 'Enter credentials',
                          icon: TablerIcons.mail,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          textInputAction: TextInputAction.next,
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
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text('Forgot Password?', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'LOGIN',
                            onPressed: _handleLogin,
                            isLoading: auth.loading,
                            backgroundColor: AppColors.accent,
                            textColor: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Text('Join our elite partner network?', 
                                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)
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
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.8));
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBase.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(obscure ? TablerIcons.eye : TablerIcons.eye_off, size: 18, color: AppColors.textMuted),
            onPressed: onToggleObscure,
          ) : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent, width: 1.6)),
        ),
      ),
    );
  }
}

