import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

/// AI-powered personalised insights screen.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _insights = [
    _Insight(
      category: 'Carbon',
      icon: Icons.eco_rounded,
      color: AppTheme.primaryGreen,
      title: 'Switch to Metro Twice a Week',
      body: 'You\'ve taken an auto 5 days straight. Switching 2 rides to metro saves ~1.2 kg CO₂ and earns you 40 points.',
      action: 'Plan commute',
    ),
    _Insight(
      category: 'Sleep',
      icon: Icons.bedtime_rounded,
      color: AppTheme.secondaryTeal,
      title: 'You Sleep Less During Exams',
      body: 'Your average sleep drops to 5.2h in exam weeks. Set a 10 PM reminder this Sunday to protect your sleep.',
      action: 'Set reminder',
    ),
    _Insight(
      category: 'Diet',
      icon: Icons.restaurant_rounded,
      color: AppTheme.accentAmber,
      title: 'Try 2 Vegetarian Days',
      body: 'Your current mixed diet emits ~4.5 kg CO₂/day from food. Going vegetarian 2 days saves ~4 kg CO₂ weekly.',
      action: 'Explore meals',
    ),
    _Insight(
      category: 'Exercise',
      icon: Icons.directions_run_rounded,
      color: AppTheme.warningOrange,
      title: '3-Day Exercise Gap Detected',
      body: 'You haven\'t exercised in 3 days. A 20-min walk today earns 15 points and breaks the streak.',
      action: 'Log walk',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('AI Insights', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.secondaryTeal),
              label: Text('ML-powered', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTeal)),
              backgroundColor: AppTheme.secondaryTeal.withOpacity(0.1),
              side: const BorderSide(color: AppTheme.secondaryTeal, width: 1),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _insights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _InsightCard(insight: _insights[i])
          .animate(delay: Duration(milliseconds: i * 80))
          .fadeIn()
          .slideY(begin: 0.1),
      ),
    );
  }
}

class _Insight {
  const _Insight({required this.category, required this.icon, required this.color, required this.title, required this.body, required this.action});
  final String category;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String action;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insight.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: insight.color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(insight.icon, color: insight.color, size: 20),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text(insight.category, style: theme.textTheme.bodySmall?.copyWith(color: insight.color)),
                backgroundColor: insight.color.withOpacity(0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.title, style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText)),
          const SizedBox(height: 6),
          Text(insight.body, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: insight.color,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: insight.color.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(insight.action, style: theme.textTheme.labelLarge?.copyWith(color: insight.color)),
            ),
          ),
        ],
      ),
    );
  }
}
