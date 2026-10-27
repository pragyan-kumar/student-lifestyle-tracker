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

/// Home Dashboard — shows daily summary of carbon footprint, habits, checklist, weekly trend, eco tip, and rewards.
/// Redesigned with Apple Health / Linear / Material 3 inspired dark aesthetic:
/// - 80% reduced neon glow with soft diffused shadows and subtle 1px borders
/// - Strict 20–24px radius flatter cards
/// - Strict visual hierarchy: Today's CO₂ -> Habits -> Checklist -> Weekly Trend -> Eco Tip -> Rewards
/// - Smooth LineChart for Weekly Trend with subtle gradient fill and highlighted current day
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
          color: AppTheme.primaryTeal,
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
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header App Bar ─────────────────────────────────────────
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.darkBackground,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 18,
                title: Row(
                  children: [
                    // Sleek Brand Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryTeal.withOpacity(0.25),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco_rounded,
                              color: AppTheme.primaryTeal, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'EcoLife',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // User avatar / profile button — or Login pill when guest
                    if (authUser != null)
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.darkBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor:
                                    AppTheme.primaryTeal.withOpacity(0.18),
                                child: Text(
                                  authUser.name.isNotEmpty
                                      ? authUser.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryTeal),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                authUser.name.split(' ').first,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryTeal.withOpacity(0.35),
                                width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded,
                                  color: AppTheme.primaryTeal, size: 14),
                              SizedBox(width: 6),
                              Text('Login',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryTeal)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Welcome Banner ───────────────────────────────────
                    _WelcomeBanner(
                      name: authUser?.name.split(' ').first ?? 'Wellness Advocate',
                    ),
                    const SizedBox(height: 16),

                    // ── Login Prompt (guest only) ─────────────────────────
                    if (authUser == null) ...[
                      _LoginPromptCard(),
                      const SizedBox(height: 20),
                    ],

                    // ═══════════════════════════════════════════════════════
                    // 1. PRIMARY FOCUS: Today's CO₂
                    // ═══════════════════════════════════════════════════════
                    _CarbonSummaryCard(
                      emissionKg: emissionKg,
                      hasLogged: hasLoggedCarbon,
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // 2. HABITS: Today's Habits
                    // ═══════════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(
                          title: "Today's Habits",
                          icon: Icons.self_improvement_rounded,
                          color: AppTheme.primaryTeal,
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.habits),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.darkBorder, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tracker',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    )),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppTheme.primaryTeal, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _HabitProgressRow(
                      checklist: checklist,
                      progress: habitProgress,
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // 3. CHECKLIST: Today's Checklist Quick Card
                    // ═══════════════════════════════════════════════════════
                    _DashboardChecklistCard(
                      checklist: checklist,
                      completedCount: completedCount,
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // 4. WEEKLY TREND: Smooth Line Chart
                    // ═══════════════════════════════════════════════════════
                    _SectionTitle(
                      title: 'Weekly Carbon Trend',
                      icon: Icons.show_chart_rounded,
                      color: AppTheme.secondaryBlue,
                    ),
                    const SizedBox(height: 14),
                    _WeeklyChart(data: summary.weeklyCarbonDaily),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // 5. ECO TIP: Daily Eco Tip
                    // ═══════════════════════════════════════════════════════
                    _InsightTipCard(),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // 6. REWARDS: Points, Streak & Badges
                    // ═══════════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(
                          title: 'Rewards & Streaks',
                          icon: Icons.emoji_events_rounded,
                          color: AppTheme.accentAmber,
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.rewards),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.darkBorder, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Wallet',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentAmber,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    )),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppTheme.accentAmber, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PointsWalletCard(
                      points: points,
                      streak: streakDays,
                      badges: badgesCount,
                    ),
                    const SizedBox(height: 80), // Nav bar clearance
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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.darkText,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                letterSpacing: -0.3,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track daily habits and reduce your carbon footprint.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkTextMuted,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryTeal.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.spa_rounded,
                    color: AppTheme.primaryTeal, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _PillBadge('Habits', AppTheme.primaryTeal),
              _PillBadge('Carbon', AppTheme.secondaryBlue),
              _PillBadge('Rewards', AppTheme.accentAmber),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.03);
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Login / Sign Up Prompt Card (guest mode) ─────────────────────────────────
class _LoginPromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: AppTheme.primaryTeal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save your progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                ),
                Text(
                  'Sign in to sync habits & earn rewards',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkTextMuted,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go(AppRoutes.login),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }
}

// ── Carbon Summary Hero Card (PRIMARY FOCUS) ─────────────────────────────────
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasLogged
              ? AppTheme.primaryTeal.withOpacity(0.3)
              : AppTheme.darkBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasLogged
                          ? AppTheme.primaryTeal
                          : AppTheme.accentAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TODAY'S CO₂ FOOTPRINT",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasLogged
                      ? AppTheme.primaryTeal.withOpacity(0.12)
                      : AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasLogged
                        ? AppTheme.primaryTeal.withOpacity(0.3)
                        : AppTheme.darkBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasLogged
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 13,
                      color: hasLogged
                          ? AppTheme.primaryTeal
                          : AppTheme.darkTextMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasLogged ? 'Logged' : 'Pending',
                      style: TextStyle(
                        color: hasLogged
                            ? AppTheme.primaryTeal
                            : AppTheme.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                emissionKg.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryTeal,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -1.0,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg CO₂e',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkTextMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go(AppRoutes.carbon),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryTeal.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLogged ? Icons.calculate_rounded : Icons.add_rounded,
                        color: AppTheme.primaryTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLogged ? 'Calculator' : 'Log Entry',
                        style: const TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  emissionKg <= 2.5
                      ? Icons.energy_savings_leaf_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: emissionKg <= 2.5
                      ? AppTheme.successGreen
                      : AppTheme.secondaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emissionKg == 0
                        ? 'Calculate your daily footprint from commute, food, and energy'
                        : emissionKg <= 2.5
                            ? 'Great job! Your carbon output is below student average today'
                            : 'Logged across transport, diet, and device energy usage',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkTextMuted,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
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

    // Simplified palette: Primary Teal, Secondary Blue, Success Green, Accent Amber, Cyan
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
            : 'Pending',
        'color': AppTheme.secondaryBlue,
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
            : 'Pending',
        'color': AppTheme.primaryTeal,
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
            : 'Pending',
        'color': AppTheme.successGreen,
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
            : 'Pending',
        'color': AppTheme.accentAmber,
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
            : 'Pending',
        'color': const Color(0xFF38BDF8),
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
  const _HabitTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final IconData icon;
  final double value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppTheme.darkBorder,
              color: color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: value >= 1.0 ? color : AppTheme.darkTextMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Today's Checklist Quick Card ─────────────────────────────────────────────
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: AppTheme.primaryTeal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Checklist",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryTeal.withOpacity(0.25), width: 1),
                ),
                child: Text(
                  '$completedCount / 5 completed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._items.map((key) {
            final isDone = checklist[key] == true;
            final icon = _icons[key] ?? Icons.check_circle_outline;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref.read(habitsProvider.notifier).toggle(key, !isDone);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primaryTeal.withOpacity(0.08)
                        : AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? AppTheme.primaryTeal.withOpacity(0.35)
                          : AppTheme.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isDone
                            ? AppTheme.primaryTeal
                            : AppTheme.darkTextMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isDone ? FontWeight.w600 : FontWeight.w400,
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
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.primaryTeal
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone
                                ? AppTheme.primaryTeal
                                : AppTheme.darkBorder,
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.black, size: 15)
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

// ── Weekly Carbon Trend (SMOOTH LINE CHART) ──────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final chartData =
        data.length == 7 ? data : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Today's index in Monday=0 ... Sunday=6
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    double maxVal = 6.0;
    for (final v in chartData) {
      if (v > maxVal) maxVal = v;
    }
    maxVal = (maxVal + 1.5).ceilToDouble();

    final spots = chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Footprint',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'kg CO₂e / day',
                    style: TextStyle(
                      color: AppTheme.darkTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxVal,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dayName = days[spot.x.toInt()];
                        return LineTooltipItem(
                          '$dayName\n${spot.y.toStringAsFixed(2)} kg',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 10 ? 5 : 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.darkBorder.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxVal > 10 ? 5 : 2,
                      getTitlesWidget: (v, meta) {
                        if (v == 0) return const SizedBox.shrink();
                        return Text(
                          v.toInt().toString(),
                          style: TextStyle(
                            color: AppTheme.darkTextMuted.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 26,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx >= 0 && idx < days.length) {
                          final isToday = idx == todayIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[idx],
                              style: TextStyle(
                                color: isToday
                                    ? AppTheme.primaryTeal
                                    : AppTheme.darkTextMuted,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryTeal,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryTeal.withOpacity(0.20),
                          AppTheme.primaryTeal.withOpacity(0.0),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isToday = index == todayIndex;
                        if (isToday) {
                          return FlDotCirclePainter(
                            radius: 5.5,
                            color: AppTheme.primaryTeal,
                            strokeWidth: 2.5,
                            strokeColor: Colors.black,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 2.5,
                          color: AppTheme.primaryTeal.withOpacity(0.6),
                          strokeWidth: 0,
                          strokeColor: Colors.transparent,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05);
  }
}

// ── Daily Eco Tip Card ───────────────────────────────────────────────────────
class _InsightTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accentAmber.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.accentAmber.withOpacity(0.25), width: 1),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.accentAmber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Eco Tip',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.accentAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Switching to a plant-forward lunch saves up to 1.5 kg CO₂ compared to red meat. Every meal counts toward a cleaner planet!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkTextMuted,
                        height: 1.4,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn();
  }
}

// ── Points Wallet Card (Rewards Section) ─────────────────────────────────────
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
            label: 'EcoPoints',
            value: '$points',
            icon: Icons.stars_rounded,
            color: AppTheme.accentAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'Streak',
            value: '$streak ${streak == 1 ? "day" : "days"}',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.warningOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'Badges',
            value: '$badges',
            icon: Icons.military_tech_rounded,
            color: AppTheme.secondaryBlue,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
