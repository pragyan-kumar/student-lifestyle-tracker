import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../carbon/presentation/providers/carbon_provider.dart';

/// Home Dashboard — shows daily summary of habits, carbon footprint, and points.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authProvider).value;
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final summary = summaryAsync.value ?? DashboardSummaryData.empty();
    final habitsAsync = ref.watch(habitsProvider);
    final habitsData = habitsAsync.value;
    final calcState = ref.watch(carbonCalculatorProvider);

    final emissionKg = summary.todayCarbon.totalEmissionKg > 0
        ? summary.todayCarbon.totalEmissionKg
        : calcState.totalKg;
    final hasLoggedCarbon =
        summary.todayCarbon.hasLogged || calcState.totalKg > 0;

    // Use habitsData if loaded (for instant optimistic toggle feedback), else fallback to summary
    final checklist = habitsData != null && habitsData.checklist.isNotEmpty
        ? habitsData.checklist
        : summary.todayHabits.checklist;
    final completedCount = habitsData != null
        ? habitsData.completedCount
        : summary.todayHabits.completedCount;
    final habitProgress = summary.todayHabits.progress;

    final points = habitsData?.userPoints ??
        (authUser?.points != null && authUser!.points > 0
            ? authUser.points
            : summary.user.points);
    final streakDays = habitsData?.userStreakDays ??
        (authUser?.streakDays != null && authUser!.streakDays > 0
            ? authUser.streakDays
            : summary.user.streakDays);
    final badgesCount = authUser?.badgesCount ?? summary.user.badgesCount;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          backgroundColor: AppTheme.darkCard,
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(habitsProvider);
            await Future.wait([
              ref.read(dashboardSummaryProvider.future),
              ref.read(habitsProvider.notifier).refresh(),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              // ── Gradient App Bar ─────────────────────────────────────────
              SliverAppBar(
                floating: true,
                expandedHeight: 90,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1117), Color(0xFF0D1B2A)],
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Glowing logo pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.primaryGreen.withOpacity(0.25),
                              AppTheme.secondaryTeal.withOpacity(0.15),
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.3),
                                  blurRadius: 12)
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_rounded,
                                  color: AppTheme.primaryGreen, size: 14),
                              const SizedBox(width: 4),
                              Text('EcoLife',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  )),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // User avatar / profile button
                        if (authUser != null)
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.profile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppTheme.primaryGreen.withOpacity(0.25),
                                  AppTheme.secondaryTeal.withOpacity(0.15),
                                ]),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.6)),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.2),
                                      blurRadius: 8)
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor:
                                        AppTheme.primaryGreen.withOpacity(0.3),
                                    child: Text(
                                      authUser.name.isNotEmpty
                                          ? authUser.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    authUser.name.split(' ').first,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Welcome Hero Banner ──────────────────────────────────
                    _WelcomeBanner(
                      name: authUser?.name.split(' ').first ?? 'Student',
                    ),
                    const SizedBox(height: 16),

                    // ── Today's Carbon Card ──────────────────────────────
                    _CarbonSummaryCard(
                      emissionKg: emissionKg,
                      hasLogged: hasLoggedCarbon,
                    ),
                    const SizedBox(height: 16),

                    // ── Points Wallet Row ────────────────────────────────
                    _PointsWalletCard(
                      points: points,
                      streak: streakDays,
                      badges: badgesCount,
                    ),
                    const SizedBox(height: 24),

                    // ── Today's Habits Section ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(
                          title: "Today's Habits",
                          icon: Icons.self_improvement_rounded,
                          color: AppTheme.warningOrange,
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.habits),
                          child: Row(
                            children: [
                              Text('Tracker',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.primaryGreen, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _HabitProgressRow(
                      checklist: checklist,
                      progress: habitProgress,
                    ),
                    const SizedBox(height: 14),

                    // ── Today's Checklist Quick Card ─────────────────────
                    _DashboardChecklistCard(
                      checklist: checklist,
                      completedCount: completedCount,
                    ),
                    const SizedBox(height: 24),

                    // ── Weekly Carbon Chart ──────────────────────────────
                    _SectionTitle(
                      title: 'Weekly Carbon Trend',
                      icon: Icons.bar_chart_rounded,
                      color: AppTheme.secondaryTeal,
                    ),
                    const SizedBox(height: 12),
                    _WeeklyChart(data: summary.weeklyCarbonDaily),
                    const SizedBox(height: 24),

                    // ── Tip Card ─────────────────────────────────────────
                    _InsightTipCard(),
                    const SizedBox(height: 80), // nav bar clearance
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)
            ],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }
}

// ── Welcome Hero Banner ──────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.18),
            AppTheme.secondaryTeal.withOpacity(0.12),
            AppTheme.warningOrange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👋', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $name!',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.darkText,
                                  fontWeight: FontWeight.w800,
                                )),
                    const SizedBox(height: 2),
                    Text('Track habits & cut your carbon footprint',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryGreen,
                            )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _PillBadge('🌿 Track habits', AppTheme.primaryGreen),
              SizedBox(width: 8),
              _PillBadge('⚡ Cut carbon', AppTheme.secondaryTeal),
              SizedBox(width: 8),
              _PillBadge('🏆 Earn points', AppTheme.accentAmber),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Carbon Summary Hero Card ─────────────────────────────────────────────────
class _CarbonSummaryCard extends StatelessWidget {
  const _CarbonSummaryCard({
    required this.emissionKg,
    required this.hasLogged,
  });

  final double emissionKg;
  final bool hasLogged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.18),
            AppTheme.secondaryTeal.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's CO₂",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.darkTextMuted)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.secondaryTeal],
                      ).createShader(bounds),
                      child: Text(
                        emissionKg.toStringAsFixed(1),
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 6),
                      child: Text('kg CO₂',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.darkTextMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                        hasLogged
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 13,
                        color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      hasLogged
                          ? 'Carbon footprint logged today'
                          : 'Log your first activity',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 20)
              ],
            ),
            child: const Icon(Icons.eco_rounded,
                size: 44, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Points Wallet Card ───────────────────────────────────────────────────────
class _PointsWalletCard extends StatelessWidget {
  const _PointsWalletCard({
    required this.points,
    required this.streak,
    required this.badges,
  });

  final int points;
  final int streak;
  final int badges;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatChip(
                label: 'Points',
                value: '$points',
                icon: Icons.stars_rounded,
                color: AppTheme.accentAmber)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatChip(
                label: 'Streak',
                value: '$streak ${streak == 1 ? "day" : "days"}',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.warningOrange)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatChip(
                label: 'Badges',
                value: '$badges',
                icon: Icons.military_tech_rounded,
                color: AppTheme.secondaryTeal)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25), blurRadius: 14, spreadRadius: 1)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w800,
                  )),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color.withOpacity(0.8))),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Habit Progress Row ───────────────────────────────────────────────────────
class _HabitProgressRow extends StatelessWidget {
  const _HabitProgressRow({
    required this.checklist,
    required this.progress,
  });

  final Map<String, bool> checklist;
  final Map<String, DashboardHabitProgressItem> progress;

  @override
  Widget build(BuildContext context) {
    final isSleepDone = checklist['Sleep (6–9h)'] == true;
    final isDietDone = checklist['Healthy Meal'] == true;
    final isExerciseDone = checklist['Exercise (30 min)'] == true;
    final isScreenDone = checklist['Screen Time < 4h'] == true;
    final isWaterDone = checklist['Water (8 glasses)'] == true;

    final habits = [
      {
        'label': 'Sleep',
        'icon': Icons.bedtime_rounded,
        'value': isSleepDone ? 1.0 : (progress['sleep']?.value ?? 0.0),
        'detail': isSleepDone
            ? (progress['sleep']?.status != null &&
                    progress['sleep']!.status != 'Not logged'
                ? progress['sleep']!.status
                : '8h')
            : 'Not logged',
        'color': const Color(0xFF9D4EDD),
      },
      {
        'label': 'Diet',
        'icon': Icons.restaurant_rounded,
        'value': isDietDone ? 1.0 : (progress['diet']?.value ?? 0.0),
        'detail': isDietDone
            ? (progress['diet']?.status != null &&
                    progress['diet']!.status != 'Not logged'
                ? progress['diet']!.status
                : 'Healthy')
            : 'Not logged',
        'color': const Color(0xFF00F5D4),
      },
      {
        'label': 'Exercise',
        'icon': Icons.directions_run_rounded,
        'value': isExerciseDone ? 1.0 : (progress['exercise']?.value ?? 0.0),
        'detail': isExerciseDone
            ? (progress['exercise']?.status != null &&
                    progress['exercise']!.status != 'Not logged'
                ? progress['exercise']!.status
                : '30m')
            : 'Not logged',
        'color': const Color(0xFF2E6EE1),
      },
      {
        'label': 'Screen',
        'icon': Icons.phone_android_rounded,
        'value': isScreenDone ? 1.0 : (progress['screen']?.value ?? 0.0),
        'detail': isScreenDone
            ? (progress['screen']?.status != null &&
                    progress['screen']!.status != 'Not logged'
                ? progress['screen']!.status
                : '< 4h')
            : 'Not logged',
        'color': const Color(0xFFDAA520),
      },
      {
        'label': 'Water',
        'icon': Icons.water_drop_rounded,
        'value': isWaterDone ? 1.0 : (progress['water']?.value ?? 0.0),
        'detail': isWaterDone
            ? (progress['water']?.status != null &&
                    progress['water']!.status != 'Not logged'
                ? progress['water']!.status
                : '8 gl')
            : 'Not logged',
        'color': const Color(0xFF00B4D8),
      },
    ];

    return Row(
      children: habits
          .map((h) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _HabitTile(
                    label: h['label'] as String,
                    icon: h['icon'] as IconData,
                    value: h['value'] as double,
                    detail: h['detail'] as String,
                    color: h['color'] as Color,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile(
      {required this.label,
      required this.icon,
      required this.value,
      required this.detail,
      required this.color});
  final String label;
  final IconData icon;
  final double value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.12), AppTheme.darkCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.darkBorder,
                color: color,
                minHeight: 5),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.darkTextMuted, fontSize: 10)),
          Text(detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color, fontWeight: FontWeight.w600, fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Today's Checklist Card on Dashboard ──────────────────────────────────────
class _DashboardChecklistCard extends ConsumerWidget {
  const _DashboardChecklistCard({
    required this.checklist,
    required this.completedCount,
  });

  final Map<String, bool> checklist;
  final int completedCount;

  static const List<String> _items = [
    'Sleep (6–9h)',
    'Healthy Meal',
    'Exercise (30 min)',
    'Screen Time < 4h',
    'Water (8 glasses)',
  ];

  static const Map<String, IconData> _icons = {
    'Sleep (6–9h)': Icons.bedtime_rounded,
    'Healthy Meal': Icons.restaurant_rounded,
    'Exercise (30 min)': Icons.directions_run_rounded,
    'Screen Time < 4h': Icons.phone_android_rounded,
    'Water (8 glasses)': Icons.water_drop_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text('Today\'s Checklist',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Text('$completedCount / 5 done',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.map((key) {
            final isDone = checklist[key] == true;
            final icon = _icons[key] ?? Icons.check_circle_outline;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(habitsProvider.notifier).toggle(key, !isDone);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primaryGreen.withOpacity(0.08)
                        : AppTheme.darkBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDone
                            ? AppTheme.primaryGreen.withOpacity(0.4)
                            : AppTheme.darkBorder.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: isDone
                              ? AppTheme.primaryGreen
                              : AppTheme.darkTextMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDone
                                ? AppTheme.darkText
                                : AppTheme.darkTextMuted,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: isDone
                                  ? AppTheme.primaryGreen
                                  : AppTheme.darkBorder,
                              width: 1.5),
                        ),
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.black, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Weekly Carbon Bar Chart ──────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final chartData =
        data.length == 7 ? data : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxVal = chartData.isEmpty
        ? 8.0
        : (chartData.reduce((a, b) => a > b ? a : b) + 2.0).clamp(6.0, 50.0);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.secondaryTeal.withOpacity(0.08), AppTheme.darkCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.secondaryTeal.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: AppTheme.secondaryTeal.withOpacity(0.1), blurRadius: 16)
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < days.length) {
                    return Text(days[idx],
                        style: TextStyle(
                            color: AppTheme.darkTextMuted.withOpacity(0.6),
                            fontSize: 11));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.darkBorder.withOpacity(0.3), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: chartData.asMap().entries.map((e) {
            final isZero = e.value == 0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: isZero ? 0.3 : e.value,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isZero
                        ? [
                            AppTheme.primaryGreen.withOpacity(0.15),
                            AppTheme.primaryGreen.withOpacity(0.05)
                          ]
                        : [
                            AppTheme.secondaryTeal,
                            AppTheme.primaryGreen,
                          ],
                  ),
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2);
  }
}

// ── Welcome Tip Card ─────────────────────────────────────────────────────────
class _InsightTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentAmber.withOpacity(0.12),
            AppTheme.darkCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.accentAmber.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: AppTheme.accentAmber.withOpacity(0.1), blurRadius: 16)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.accentAmber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Eco Tip',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 4),
                Text(
                  'Switching to a vegetarian lunch saves up to 1.5 kg CO₂ compared to red meat. Every meal counts!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkTextMuted,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}
