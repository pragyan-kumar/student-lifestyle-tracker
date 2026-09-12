import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);

    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.hasError) {
      setState(() {
        final err = authState.error.toString();
        if (err.contains('401') || err.contains('credentials') || err.contains('password')) {
          _errorMsg = 'Invalid email or password.';
        } else if (err.contains('network') || err.contains('SocketException')) {
          _errorMsg = 'No internet connection.';
        } else {
          _errorMsg = 'Login failed. Please try again.';
        }
      });
    }
    // On success, the router redirect handles navigation automatically.
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final loading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Icon(Icons.eco_rounded, size: 48, color: AppTheme.primaryGreen)
                    .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text('Welcome back 👋', style: theme.textTheme.headlineLarge?.copyWith(color: AppTheme.darkText))
                    .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Text('Sign in to continue your eco journey', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted))
                    .animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),

                  // Error banner
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMsg!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.errorRed))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.darkText),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.darkTextMuted),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ).animate().slideX(begin: -0.2, delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppTheme.darkText),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.darkTextMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.darkTextMuted),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                  ).animate().slideX(begin: -0.2, delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _login,
                      child: loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Sign In'),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                    ),
                    const Expanded(child: Divider()),
                  ]),

                  const SizedBox(height: 32),

                  // Register link
                  Center(
                    child: GestureDetector(
                      onTap: loading ? null : () => context.go(AppRoutes.register),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted),
                          children: [
                            TextSpan(text: 'Sign Up', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
