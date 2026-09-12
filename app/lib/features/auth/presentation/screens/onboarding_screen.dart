import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// 3-page onboarding carousel explaining the app's core value propositions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.self_improvement_rounded,
      color: AppTheme.primaryGreen,
      title: 'Track Your Lifestyle',
      subtitle:
          'Log sleep, meals, exercise and screen time in seconds. Spot unhealthy streaks before they harm you.',
    ),
    _OnboardingPage(
      icon: Icons.eco_rounded,
      color: AppTheme.secondaryTeal,
      title: 'Know Your Carbon Footprint',
      subtitle:
          'See how your daily commute, food and device use contribute to CO₂ — with real emission data.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_rounded,
      color: AppTheme.accentAmber,
      title: 'Earn Rewards, Go Greener',
      subtitle:
          'Complete healthy & eco-friendly tasks to earn points. Redeem them for in-app themes, badges & streak passes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Page content ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _buildPage(_pages[index], theme),
              ),
            ),

            // ── Dot indicators ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? AppTheme.primaryGreen
                              : AppTheme.darkBorder,
                        ),
                      )),
            ),

            const SizedBox(height: 32),

            // ── Action button ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                          duration: 400.ms, curve: Curves.easeInOut);
                    } else {
                      context.go(AppRoutes.dashboard);
                    }
                  },
                  child: Text(_currentPage < _pages.length - 1
                      ? 'Next'
                      : 'Get Started'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: Text('Skip',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.darkTextMuted)),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: page.color.withOpacity(0.4), width: 2),
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          )
              .animate(key: ValueKey(page.title))
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(page.title,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(color: AppTheme.darkText),
                  textAlign: TextAlign.center)
              .animate(key: ValueKey('t${page.title}'))
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Text(page.subtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.darkTextMuted),
                  textAlign: TextAlign.center)
              .animate(key: ValueKey('s${page.title}'))
              .fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}
