import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);

    await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.hasError) {
      setState(() {
        final err = authState.error.toString();
        if (err.contains('409') || err.contains('already')) {
          _errorMsg = 'An account with this email already exists.';
        } else if (err.contains('network') || err.contains('SocketException')) {
          _errorMsg = 'No internet connection.';
        } else {
          _errorMsg = 'Registration failed. Please try again.';
        }
      });
    }
    // On success, the router redirect handles navigation automatically.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.darkText),
          onPressed: loading ? null : () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account 🌱',
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(color: AppTheme.darkText))
                    .animate()
                    .fadeIn(),
                const SizedBox(height: 8),
                Text('Join thousands of eco-conscious students',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.darkTextMuted))
                    .animate()
                    .fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // Error banner
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_errorMsg!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.errorRed))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppTheme.darkText),
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline,
                          color: AppTheme.darkTextMuted)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your name' : null,
                )
                    .animate()
                    .slideX(begin: -0.2, delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.darkText),
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.darkTextMuted)),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                )
                    .animate()
                    .slideX(begin: -0.2, delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppTheme.darkText),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.darkTextMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.darkTextMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimum 6 characters'
                      : null,
                )
                    .animate()
                    .slideX(begin: -0.2, delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _register,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Create Account'),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: loading ? null : () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.darkTextMuted),
                        children: [
                          TextSpan(
                              text: 'Sign In',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600)),
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
    );
  }
}
