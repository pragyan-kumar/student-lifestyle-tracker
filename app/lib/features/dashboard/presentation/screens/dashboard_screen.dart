import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';

/// Home Dashboard — shows daily summary of habits, carbon footprint, and points.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.darkBackground,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning 🌿', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText)),
                  Text('Monday, 18 Aug 2026', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                ],
              ),
              actions: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 16),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Today's Carbon Card ──────────────────────────────
                  _CarbonSummaryCard(),
                  const SizedBox(height: 16),

                  // ── Points Wallet Row ────────────────────────────────
                  _PointsWalletCard(),
                  const SizedBox(height: 24),

                  // ── Today's Habits ───────────────────────────────────
                  Text('Today\'s Habits', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
                  const SizedBox(height: 12),
                  _HabitProgressRow(),
                  const SizedBox(height: 24),

                  // ── Weekly Carbon Chart ──────────────────────────────
                  Text('Weekly Carbon Trend', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
                  const SizedBox(height: 12),
                  _WeeklyChart(),
                  const SizedBox(height: 24),

                  // ── AI Insight Tip ───────────────────────────────────
                  _InsightTipCard(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carbon Summary Hero Card ─────────────────────────────────────────────────
class _CarbonSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen.withOpacity(0.2), AppTheme.secondaryTeal.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's CO₂", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('3.2', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text('kg CO₂', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted)),
                    ),
                  ],
                ),
                Text('↓ 12% less than yesterday', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.successGreen)),
              ],
            ),
          ),
          const Icon(Icons.eco_rounded, size: 64, color: AppTheme.primaryGreen),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Points Wallet Card ───────────────────────────────────────────────────────
class _PointsWalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Points',
            value: '1,240',
            icon: Icons.stars_rounded,
            color: AppTheme.accentAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'Streak',
            value: '7 days',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.warningOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'Badges',
            value: '5',
            icon: Icons.military_tech_rounded,
            color: AppTheme.secondaryTeal,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.darkText, fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Habit Progress Row ───────────────────────────────────────────────────────
class _HabitProgressRow extends StatelessWidget {
  final _habits = const [
    {'label': 'Sleep', 'icon': Icons.bedtime_rounded, 'value': 0.75, 'detail': '6h / 8h'},
    {'label': 'Diet',  'icon': Icons.restaurant_rounded, 'value': 1.0, 'detail': 'Logged ✓'},
    {'label': 'Exercise', 'icon': Icons.directions_run_rounded, 'value': 0.5, 'detail': '15 / 30 min'},
    {'label': 'Screen', 'icon': Icons.phone_android_rounded, 'value': 0.6, 'detail': '2.4h / 4h'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _habits.map((h) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _HabitTile(
            label: h['label'] as String,
            icon: h['icon'] as IconData,
            value: h['value'] as double,
            detail: h['detail'] as String,
          ),
        ),
      )).toList(),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.label, required this.icon, required this.value, required this.detail});
  final String label;
  final IconData icon;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = value >= 1.0 ? AppTheme.successGreen : value >= 0.5 ? AppTheme.accentAmber : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value, backgroundColor: AppTheme.darkBorder, color: color, minHeight: 6),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
          Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Weekly Carbon Bar Chart ──────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [4.2, 3.8, 5.1, 3.2, 4.7, 2.9, 3.2];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: 8,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(days[v.toInt()], style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(
              toY: e.value,
              color: e.key == 6 ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.4),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )],
          )).toList(),
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2);
  }
}

// ── AI Insight Tip Card ──────────────────────────────────────────────────────
class _InsightTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.secondaryTeal.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Insight', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryTeal)),
                const SizedBox(height: 4),
                Text(
                  'Switch 2 auto rides this week to metro to save ~1.2 kg CO₂ and earn 40 bonus points!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }
}
