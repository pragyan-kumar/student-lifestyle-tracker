import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';

/// User profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).value;
    final summary = ref.watch(dashboardSummaryProvider).value;
    final savedKg = summary?.todayCarbon.savedVsAverage ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Profile',
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.darkText)),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: AppTheme.darkTextMuted),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Guest',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppTheme.darkText)),
                  Text(user?.email ?? '',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.darkTextMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.accentAmber.withOpacity(0.4)),
                    ),
                    child: Text('⭐ ${user?.points ?? 0} EcoPoints',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // Stats grid
            Row(
              children: [
                _ProfileStat(
                    value: '${user?.streakDays ?? 0}',
                    label: 'Day Streak',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.warningOrange),
                const SizedBox(width: 12),
                _ProfileStat(
                    value: '${user?.badgesCount ?? 0}',
                    label: 'Badges',
                    icon: Icons.military_tech_rounded,
                    color: AppTheme.accentAmber),
                const SizedBox(width: 12),
                _ProfileStat(
                    value: savedKg.toStringAsFixed(1),
                    label: 'kg CO₂ saved',
                    icon: Icons.eco_rounded,
                    color: AppTheme.primaryGreen),
              ],
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 28),

            // Settings list
            ...[
              (
                'Notification Preferences',
                Icons.notifications_rounded,
                AppTheme.secondaryTeal
              ),
              (
                'Theme & Appearance',
                Icons.palette_rounded,
                AppTheme.accentAmber
              ),
              ('Data & Privacy', Icons.security_rounded, AppTheme.errorRed),
              (
                'SDG Impact Report',
                Icons.bar_chart_rounded,
                AppTheme.primaryGreen
              ),
              (
                'About EcoLife',
                Icons.info_outline_rounded,
                AppTheme.darkTextMuted
              ),
              ('Sign Out', Icons.logout_rounded, AppTheme.errorRed),
            ].asMap().entries.map((e) {
              final (label, icon, color) = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: AppTheme.darkCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.darkBorder)),
                  leading: Icon(icon, color: color, size: 22),
                  title: Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.darkText)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.darkTextMuted),
                  onTap: label == 'Sign Out'
                      ? () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go(AppRoutes.login);
                        }
                      : () {},
                )
                    .animate(delay: Duration(milliseconds: 200 + e.key * 40))
                    .fadeIn()
                    .slideX(begin: 0.05),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.darkText, fontWeight: FontWeight.w700)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.darkTextMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
