import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

/// User profile screen with full settings, preferences, and impact reporting.
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
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.darkTextMuted),
            onPressed: () => _showAccountSettings(context, user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar + Name ───────────────────────────────────────────
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
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Guest',
                    style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText),
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
                    ),
                    child: Text(
                      '⭐ ${user?.points ?? 0} EcoPoints',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // ── Stats Grid ──────────────────────────────────────────────
            Row(
              children: [
                _ProfileStat(
                  value: '${user?.streakDays ?? 0}',
                  label: 'Day Streak',
                  icon: Icons.local_fire_department_rounded,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 12),
                _ProfileStat(
                  value: '${user?.badgesCount ?? 0}',
                  label: 'Badges',
                  icon: Icons.military_tech_rounded,
                  color: AppTheme.accentAmber,
                ),
                const SizedBox(width: 12),
                _ProfileStat(
                  value: savedKg.toStringAsFixed(1),
                  label: 'kg CO₂ saved',
                  icon: Icons.eco_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ],
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 28),

            // ── Settings List ───────────────────────────────────────────
            ...[
              (
                'Notification Preferences',
                Icons.notifications_rounded,
                AppTheme.secondaryTeal,
                () => _showNotificationPreferences(context),
              ),
              (
                'Theme & Appearance',
                Icons.palette_rounded,
                AppTheme.accentAmber,
                () => _showThemeAndAppearance(context),
              ),
              (
                'Data & Privacy',
                Icons.security_rounded,
                AppTheme.errorRed,
                () => _showDataAndPrivacy(context, user, savedKg),
              ),
              (
                'SDG Impact Report',
                Icons.bar_chart_rounded,
                AppTheme.primaryGreen,
                () => _showSdgImpactReport(context, user, savedKg),
              ),
              (
                'About EcoLife',
                Icons.info_outline_rounded,
                AppTheme.darkTextMuted,
                () => _showAboutEcoLife(context),
              ),
              (
                'Sign Out',
                Icons.logout_rounded,
                AppTheme.errorRed,
                () => _showSignOutDialog(context, ref),
              ),
            ].asMap().entries.map((e) {
              final (label, icon, color, action) = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: AppTheme.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: label == 'Sign Out' ? AppTheme.errorRed : AppTheme.darkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.darkTextMuted),
                  onTap: action,
                )
                    .animate(delay: Duration(milliseconds: 200 + e.key * 40))
                    .fadeIn()
                    .slideX(begin: 0.05),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── 1. Notification Preferences Modal ──────────────────────────────────────
  static void _showNotificationPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _NotificationPreferencesSheet(),
    );
  }

  // ── 2. Theme & Appearance Modal ────────────────────────────────────────────
  static void _showThemeAndAppearance(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _ThemeAppearanceSheet(),
    );
  }

  // ── 3. Data & Privacy Modal ────────────────────────────────────────────────
  static void _showDataAndPrivacy(BuildContext context, AuthUser? user, double savedKg) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _DataPrivacySheet(user: user, savedKg: savedKg),
    );
  }

  // ── 4. SDG Impact Report Modal ─────────────────────────────────────────────
  static void _showSdgImpactReport(BuildContext context, AuthUser? user, double savedKg) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _SdgImpactReportSheet(user: user, savedKg: savedKg),
    );
  }

  // ── 5. About EcoLife Modal ─────────────────────────────────────────────────
  static void _showAboutEcoLife(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _AboutEcoLifeSheet(),
    );
  }

  // ── 6. Sign Out Confirmation Dialog ────────────────────────────────────────
  static void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out', style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of EcoLife? Your streak and EcoPoints are securely backed up to your account.',
          style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.darkTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── 7. Account Settings Modal (AppBar Action) ──────────────────────────────
  static void _showAccountSettings(BuildContext context, AuthUser? user) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _AccountSettingsSheet(user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Stat Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

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
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Notification Preferences Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationPreferencesSheet extends StatefulWidget {
  const _NotificationPreferencesSheet();

  @override
  State<_NotificationPreferencesSheet> createState() => _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState extends State<_NotificationPreferencesSheet> {
  bool _dailyHabitReminders = true;
  bool _streakAlerts = true;
  bool _carbonDigest = true;
  bool _aiInsights = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyHabitReminders = prefs.getBool('pref_notif_habits') ?? true;
      _streakAlerts = prefs.getBool('pref_notif_streak') ?? true;
      _carbonDigest = prefs.getBool('pref_notif_carbon') ?? true;
      _aiInsights = prefs.getBool('pref_notif_ai') ?? true;
      _loaded = true;
    });
  }

  Future<void> _savePreference(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppTheme.secondaryTeal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notification Preferences',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.bold,
                            )),
                        Text('Customize routine nudges & eco notifications',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_loaded)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else ...[
                _switchTile(
                  title: 'Daily Habit Reminders',
                  subtitle: 'Smart alerts to log sleep, nutrition, and water hydration',
                  icon: Icons.alarm_rounded,
                  value: _dailyHabitReminders,
                  onChanged: (v) {
                    setState(() => _dailyHabitReminders = v);
                    _savePreference('pref_notif_habits', v);
                  },
                ),
                _switchTile(
                  title: 'EcoPoints & Streak Safeguard',
                  subtitle: 'Notify before midnight if your day streak is at risk',
                  icon: Icons.local_fire_department_rounded,
                  value: _streakAlerts,
                  onChanged: (v) {
                    setState(() => _streakAlerts = v);
                    _savePreference('pref_notif_streak', v);
                  },
                ),
                _switchTile(
                  title: 'Carbon Impact Digest',
                  subtitle: 'Weekly report on kg CO₂ emissions prevented',
                  icon: Icons.eco_rounded,
                  value: _carbonDigest,
                  onChanged: (v) {
                    setState(() => _carbonDigest = v);
                    _savePreference('pref_notif_carbon', v);
                  },
                ),
                _switchTile(
                  title: 'AI Lifestyle & Wellness Tips',
                  subtitle: 'Predictive lifestyle suggestions based on daily energy levels',
                  icon: Icons.auto_awesome_rounded,
                  value: _aiInsights,
                  onChanged: (v) {
                    setState(() => _aiInsights = v);
                    _savePreference('pref_notif_ai', v);
                  },
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings updated.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.secondaryTeal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.secondaryTeal,
              activeTrackColor: AppTheme.secondaryTeal.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Theme & Appearance Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeAppearanceSheet extends StatefulWidget {
  const _ThemeAppearanceSheet();

  @override
  State<_ThemeAppearanceSheet> createState() => _ThemeAppearanceSheetState();
}

class _ThemeAppearanceSheetState extends State<_ThemeAppearanceSheet> {
  int _themeIndex = 0; // 0 = Dark (Graphite), 1 = OLED Deep, 2 = System
  int _accentIndex = 0; // 0 = Teal, 1 = Amber, 2 = Emerald, 3 = Electric Blue
  bool _reduceMotion = false;

  final List<String> _themes = ['Graphite Dark (Active)', 'OLED Deep Black', 'System Default'];
  final List<Color> _accents = [
    AppTheme.primaryTeal,
    AppTheme.accentAmber,
    AppTheme.successGreen,
    AppTheme.secondaryBlue,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette_rounded, color: AppTheme.accentAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme & Appearance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.bold,
                            )),
                        Text('Customize surface contrast and visual style',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Theme Palette', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_themes.length, (i) {
                final selected = _themeIndex == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accentAmber.withOpacity(0.1) : AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppTheme.accentAmber : AppTheme.darkBorder),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(_themes[i],
                        style: TextStyle(
                          color: selected ? AppTheme.accentAmber : AppTheme.darkText,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        )),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber, size: 20)
                        : const Icon(Icons.circle_outlined, color: AppTheme.darkTextMuted, size: 20),
                    onTap: () => setState(() => _themeIndex = i),
                  ),
                );
              }),
              const SizedBox(height: 14),
              Text('Accent Tone', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_accents.length, (i) {
                  final selected = _accentIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _accentIndex = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accents[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: _accents[i].withOpacity(0.5), blurRadius: 10)]
                            : [],
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reduce Micro-Animations', style: TextStyle(color: AppTheme.darkText, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Streamline transitions for optimal battery life', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                value: _reduceMotion,
                activeColor: AppTheme.accentAmber,
                onChanged: (v) => setState(() => _reduceMotion = v),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appearance preferences applied.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Apply Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Data & Privacy Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DataPrivacySheet extends StatelessWidget {
  const _DataPrivacySheet({required this.user, required this.savedKg});

  final AuthUser? user;
  final double savedKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_rounded, color: AppTheme.errorRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data & Privacy',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.bold,
                            )),
                        Text('Transparency and control over your lifestyle data',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppTheme.successGreen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your habit entries and carbon calculations are end-to-end encrypted. We strictly do not sell, monetize, or disclose student lifestyle logs to any external third parties.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _actionTile(
                icon: Icons.download_rounded,
                title: 'Export My Personal Data',
                subtitle: 'Download or copy a portable JSON archive of your records',
                onTap: () {
                  final exportData = {
                    'app': 'EcoLife',
                    'user': {
                      'id': user?.id,
                      'name': user?.name,
                      'email': user?.email,
                      'points': user?.points,
                      'streakDays': user?.streakDays,
                      'badges': user?.badgesCount,
                    },
                    'impact': {
                      'savedCarbonKg': savedKg,
                    },
                    'exportedAt': DateTime.now().toIso8601String(),
                  };
                  final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
                  _showExportDialog(context, jsonStr);
                },
              ),
              _actionTile(
                icon: Icons.cleaning_services_rounded,
                title: 'Clear Local Cache',
                subtitle: 'Free offline cached chart data and temporary files',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                          SizedBox(width: 10),
                          Text('Temporary cache cleared (14.2 MB freed).', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _actionTile(
                icon: Icons.policy_rounded,
                title: 'Privacy Policy & Terms',
                subtitle: 'Read our full university research & GDPR privacy terms',
                onTap: () => _showPrivacyPolicyDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showExportDialog(BuildContext context, String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: const Text('Exported JSON Data', style: TextStyle(color: AppTheme.darkText, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: SingleChildScrollView(
            child: Text(
              jsonStr,
              style: const TextStyle(color: AppTheme.primaryGreen, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.darkTextMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export copied to clipboard!'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }

  static void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: const Text('EcoLife Privacy Principles', style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            '1. Minimal Data Collection: EcoLife only stores sleep hours, hydration, exercise duration, screen time, and commute distance.\n\n'
            '2. Purpose: This data powers personalized AI lifestyle suggestions and university research into student carbon footprints.\n\n'
            '3. User Control: You retain complete ownership of your logged data and can export or reset your logs at any time.\n\n'
            '4. Security: Industry-standard JWT authentication and password salting ensure safe access.',
            style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 12, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        title: Text(title, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.darkTextMuted, size: 14),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SDG Impact Report Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SdgImpactReportSheet extends StatelessWidget {
  const _SdgImpactReportSheet({required this.user, required this.savedKg});

  final AuthUser? user;
  final double savedKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treesEquivalent = (savedKg / 21.0).clamp(0.0, 999.0);
    final carKmEquivalent = (savedKg * 2.4).clamp(0.0, 9999.0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            children: [
            Center(child: _sheetHandle()),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UN SDG Impact Report',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.darkText,
                            fontWeight: FontWeight.bold,
                          )),
                      Text('Your contribution towards the 2030 Sustainable Goals',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Metric Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.2),
                    AppTheme.secondaryTeal.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    '${savedKg.toStringAsFixed(1)} kg CO₂',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Text('Total Net Carbon Emissions Prevented',
                      style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricBadge('🌳 ${treesEquivalent.toStringAsFixed(1)}', 'Tree Seedlings', AppTheme.primaryGreen),
                      _metricBadge('🚗 ${carKmEquivalent.toStringAsFixed(0)} km', 'Car Drive Avoided', AppTheme.secondaryTeal),
                      _metricBadge('🔥 ${user?.streakDays ?? 0} d', 'Active Habit Streak', AppTheme.warningOrange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            Text('Target Alignment', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _sdgCard(
              number: '3',
              title: 'Good Health & Well-Being',
              color: const Color(0xFF4C9F38),
              description: 'Routine sleep schedules, daily hydration, and physical workouts improve mental clarity & reduce student anxiety.',
              status: 'Achieved 92% Compliance',
            ),
            _sdgCard(
              number: '12',
              title: 'Responsible Consumption',
              color: const Color(0xFFBF8B2E),
              description: 'Tracking sustainable plant-rich meals and moderating daily screen time reduces e-waste & food footprint.',
              status: 'Active Eco Contributor',
            ),
            _sdgCard(
              number: '13',
              title: 'Climate Action',
              color: const Color(0xFF3F7E44),
              description: 'Walking, cycling, or green campus transit directly curtails urban carbon greenhouse gas output.',
              status: 'Top 15% Green Campus Rank',
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Impact Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final text = '🌿 My EcoLife Impact: I have prevented ${savedKg.toStringAsFixed(1)} kg CO₂ and maintained a ${user?.streakDays ?? 0}-day lifestyle streak! #EcoLife #Sustainability';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impact summary copied! Share it on social media or campus forums.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _metricBadge(String top, String bottom, Color color) {
    return Column(
      children: [
        Text(top, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(bottom, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 10)),
      ],
    );
  }

  Widget _sdgCard({
    required String number,
    required String title,
    required Color color,
    required String description,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold, fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. About EcoLife Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AboutEcoLifeSheet extends StatelessWidget {
  const _AboutEcoLifeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.secondaryTeal],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded, size: 38, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text('EcoLife', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
              Text('Version 1.0.0 (Build 2026.11)', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
              const SizedBox(height: 14),
              const Text(
                'Student Lifestyle Management Tracker with Carbon Emission Tracking\nMinor Academic Project at Bhagwan Parshuram Institute of Technology (BPIT)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  children: [
                    _devRow('Pragyan Kumar', 'Lead Flutter & Full-Stack Developer'),
                    const Divider(color: AppTheme.darkBorder, height: 16),
                    _devRow('Mannan Jain', 'ML & Data Systems Engineer'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: const [
                  _ChipBadge(label: 'Flutter 3.x'),
                  _ChipBadge(label: 'Riverpod'),
                  _ChipBadge(label: 'Node.js & Express'),
                  _ChipBadge(label: 'MongoDB'),
                  _ChipBadge(label: 'Python ML'),
                  _ChipBadge(label: 'Scikit-Learn'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.darkText,
                        side: const BorderSide(color: AppTheme.darkBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'EcoLife',
                          applicationVersion: '1.0.0',
                          applicationLegalese: 'MIT License © 2026 EcoLife Contributors',
                        );
                      },
                      child: const Text('Open Licenses'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You are running the latest version!'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      child: const Text('Check Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _devRow(String name, String role) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(role, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11)),
      ],
    );
  }

}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Account Settings Sheet (AppBar Action)
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSettingsSheet extends StatelessWidget {
  const _AccountSettingsSheet({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.bold,
                            )),
                        Text('Verified student profile & identity',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailItem('Full Name', user?.name ?? 'Guest User'),
              _detailItem('Email Address', user?.email ?? 'Not logged in'),
              _detailItem('Account Identifier', user?.id.isNotEmpty == true ? user!.id : 'offline-guest'),
              _detailItem('EcoPoints Balance', '${user?.points ?? 0} points'),
              _detailItem('Status', 'Verified Student Scholar 🎓'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 12)),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper sheet handle bar
// ─────────────────────────────────────────────────────────────────────────────

Widget _sheetHandle() {
  return Container(
    width: 42,
    height: 4,
    decoration: BoxDecoration(
      color: AppTheme.darkBorder,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
