import 'dart:ui';
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background Image with Scrim ──────────────────────────
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1200',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF0F172A)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.9), const Color(0xFF0F172A).withOpacity(0.7), Colors.black.withOpacity(0.95)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Login Center Hub ──────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // ── Hero Logo ──
                  Hero(
                    tag: 'logo',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.15), blurRadius: 30, spreadRadius: 2)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/logo.png', height: 100, fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(TablerIcons.briefcase, size: 80, color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('PRIME BUSINESS NETWORK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const SizedBox(height: 48),

                  // ── Frosted Login Card ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            const SizedBox(height: 8),
                            Text('Access your elite business dashboard', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 32),

                            // Fields
                            _modernField(
                              controller: _identifierController,
                              label: 'EMAIL OR PHONE',
                              hint: 'admin@pbn.lk',
                              icon: TablerIcons.user,
                            ),
                            const SizedBox(height: 24),
                            _modernField(
                              controller: _passwordController,
                              label: 'PASSWORD',
                              hint: '••••••••',
                              icon: TablerIcons.lock,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword ? TablerIcons.eye : TablerIcons.eye_off, color: Colors.white38, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 32),

                            CustomButton(
                              text: 'SIGN IN NOW',
                              onPressed: _handleLogin,
                              isLoading: auth.loading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New to the network?", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/apply'),
                        child: const Text('Apply Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool obscure = false, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
          ),
        ),
      ],
    );
  }
}
