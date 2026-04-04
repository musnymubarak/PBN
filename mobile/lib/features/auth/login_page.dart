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
            // ── Login Form ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign In',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text('Enter your credentials to access the network',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, fontSize: 15),
                  ),
                  const SizedBox(height: 40),

                  // Identifier Field
                  Text('EMAIL OR PHONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      hintText: 'admin@pbn.lk or +94...', 
                      prefixIcon: Icon(TablerIcons.user, size: 20), 
                      filled: true, 
                      fillColor: Color(0xFFF9FAFB)
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••', 
                      prefixIcon: const Icon(TablerIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? TablerIcons.eye : TablerIcons.eye_off, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true, 
                      fillColor: Color(0xFFF9FAFB)
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'SIGN IN',
                    onPressed: _handleLogin,
                    isLoading: auth.loading,
                  ),

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
