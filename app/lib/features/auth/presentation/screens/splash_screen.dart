import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Splash screen shown on cold launch.
/// Waits for auth state to resolve then redirects via GoRouter's redirect logic.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Minimum splash display time for branding.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Wait for auth to finish loading (restoring stored session).
    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      // Auth still loading — listen for the first resolved state.
      ref.listenManual(authProvider, (_, next) {
        if (!next.isLoading && mounted) {
          _redirect(next.value != null);
        }
      });
      return;
    }

    _redirect(authState.value != null);
  }

  void _redirect(bool isLoggedIn) {
    if (!mounted) return;
    if (isLoggedIn) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
                boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 24)],
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 52,
                color: AppTheme.primaryGreen,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text(
              'EcoLife',
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

            const SizedBox(height: 8),

            Text(
              'Track habits. Cut carbon. Earn rewards.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkTextMuted,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 48),

            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryGreen,
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
