import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
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
            // ── Gradient App Bar ─────────────────────────────────────────
            SliverAppBar(
              floating: true,
              expandedHeight: 100,
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
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Glowing logo pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppTheme.primaryGreen.withOpacity(0.25),
                            AppTheme.secondaryTeal.withOpacity(0.15),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 12)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 14),
                            const SizedBox(width: 4),
                            Text('EcoLife', style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryGreen, fontWeight: FontWeight.w700, fontSize: 11,
                            )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Login button
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.login),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.primaryGreen.withOpacity(0.25),
                              AppTheme.secondaryTeal.withOpacity(0.15),
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.6)),
                            boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 8)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded, size: 12, color: AppTheme.primaryGreen),
                              const SizedBox(width: 5),
                              Text('Login / Sign Up', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen,
                              )),
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
                  _WelcomeBanner(),
                  const SizedBox(height: 16),

                  // ── Today's Carbon Card ──────────────────────────────
                  _CarbonSummaryCard(),
                  const SizedBox(height: 16),

                  // ── Points Wallet Row ────────────────────────────────
                  _PointsWalletCard(),
                  const SizedBox(height: 24),

                  // ── Today's Habits ───────────────────────────────────
                  _SectionTitle(title: "Today's Habits", icon: Icons.self_improvement_rounded, color: AppTheme.warningOrange),
                  const SizedBox(height: 12),
                  _HabitProgressRow(),
                  const SizedBox(height: 24),

                  // ── Weekly Carbon Chart ──────────────────────────────
                  _SectionTitle(title: 'Weekly Carbon Trend', icon: Icons.bar_chart_rounded, color: AppTheme.secondaryTeal),
                  const SizedBox(height: 12),
                  _WeeklyChart(),
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
    );
  }
}

// ── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, required this.color});
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
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.darkText, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}

// ── Welcome Hero Banner ──────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.15), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('👋', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome to EcoLife', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.darkText, fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 2),
                    Text('Your eco journey starts here', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryGreen,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PillBadge('🌿 Track habits', AppTheme.primaryGreen),
              const SizedBox(width: 8),
              _PillBadge('⚡ Cut carbon', AppTheme.secondaryTeal),
              const SizedBox(width: 8),
              _PillBadge('🏆 Earn rewards', AppTheme.accentAmber),
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
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
          colors: [
            AppTheme.primaryGreen.withOpacity(0.18),
            AppTheme.secondaryTeal.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 20, spreadRadius: 1),
        ],
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
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.secondaryTeal],
                      ).createShader(bounds),
                      child: Text('0.0', style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800,
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 6),
                      child: Text('kg CO₂', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 13, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text('Log your first activity', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primaryGreen)),
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
              boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 20)],
            ),
            child: const Icon(Icons.eco_rounded, size: 44, color: AppTheme.primaryGreen),
          ),
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
        Expanded(child: _StatChip(label: 'Points', value: '0', icon: Icons.stars_rounded, color: AppTheme.accentAmber)),
        const SizedBox(width: 12),
        Expanded(child: _StatChip(label: 'Streak', value: '0 days', icon: Icons.local_fire_department_rounded, color: AppTheme.warningOrange)),
        const SizedBox(width: 12),
        Expanded(child: _StatChip(label: 'Badges', value: '0', icon: Icons.military_tech_rounded, color: AppTheme.secondaryTeal)),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 14, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.darkText, fontWeight: FontWeight.w800,
          )),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8))),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Habit Progress Row ───────────────────────────────────────────────────────
class _HabitProgressRow extends StatelessWidget {
  final _habits = const [
    {'label': 'Sleep',    'icon': Icons.bedtime_rounded,           'value': 0.0, 'detail': 'Not logged', 'color': Color(0xFF9D4EDD)},
    {'label': 'Diet',     'icon': Icons.restaurant_rounded,        'value': 0.0, 'detail': 'Not logged', 'color': Color(0xFF00F5D4)},
    {'label': 'Exercise', 'icon': Icons.directions_run_rounded,    'value': 0.0, 'detail': 'Not logged', 'color': Color(0xFF2E6EE1)},
    {'label': 'Screen',   'icon': Icons.phone_android_rounded,     'value': 0.0, 'detail': 'Not logged', 'color': Color(0xFFDAA520)},
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
            color: h['color'] as Color,
          ),
        ),
      )).toList(),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.label, required this.icon, required this.value, required this.detail, required this.color});
  final String label;
  final IconData icon;
  final double value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value, backgroundColor: AppTheme.darkBorder, color: color, minHeight: 5),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted, fontSize: 10)),
          Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 9), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Weekly Carbon Bar Chart ──────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
        border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: AppTheme.secondaryTeal.withOpacity(0.1), blurRadius: 16)],
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
                getTitlesWidget: (v, meta) => Text(days[v.toInt()],
                  style: TextStyle(color: AppTheme.darkTextMuted.withOpacity(0.6), fontSize: 11)),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.darkBorder.withOpacity(0.3), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(
              toY: e.value == 0 ? 0.3 : e.value, // ghost bar so chart doesn't look empty
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppTheme.primaryGreen.withOpacity(0.15), AppTheme.primaryGreen.withOpacity(0.05)],
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )],
          )).toList(),
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
            AppTheme.secondaryTeal.withOpacity(0.15),
            AppTheme.warningOrange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.secondaryTeal.withOpacity(0.15), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.secondaryTeal.withOpacity(0.3), AppTheme.primaryGreen.withOpacity(0.15)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.secondaryTeal.withOpacity(0.4), blurRadius: 14)],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondaryTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Tip 👋', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.secondaryTeal, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 4),
                Text(
                  'Start by logging your daily habits — sleep, diet, exercise and commute — to earn EcoPoints and track your carbon footprint!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }
}
