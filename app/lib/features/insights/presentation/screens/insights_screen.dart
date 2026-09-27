import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class AiInsight {
  final String category;
  final String title;
  final String description;
  final String action;
  final int priority;

  const AiInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });

  factory AiInsight.fromJson(Map<String, dynamic> j) => AiInsight(
        category: j['category'] ?? 'General',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        action: j['action'] ?? '',
        priority: j['priority'] ?? 5,
      );
}

class InsightsResponse {
  final List<AiInsight> insights;
  final String source; // 'ml' | 'rules'
  final String generatedAt;
  final int daysOfData;

  const InsightsResponse({
    required this.insights,
    required this.source,
    required this.generatedAt,
    required this.daysOfData,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> j) => InsightsResponse(
        insights: (j['insights'] as List? ?? [])
            .map((e) => AiInsight.fromJson(e as Map<String, dynamic>))
            .toList(),
        source: j['source'] ?? 'rules',
        generatedAt: j['generatedAt'] ?? '',
        daysOfData: (j['features']?['days_of_data'] as num?)?.toInt() ?? 0,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────
final insightsProvider = FutureProvider.autoDispose<InsightsResponse>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/insights');
  return InsightsResponse.fromJson(res.data as Map<String, dynamic>);
});

// ── Screen ────────────────────────────────────────────────────────────────────
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'AI Insights',
          style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText),
        ),
        actions: [
          insightsAsync.whenOrNull(
            data: (data) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(
                  data.source == 'ml'
                      ? Icons.psychology_rounded
                      : Icons.rule_rounded,
                  size: 14,
                  color: AppTheme.secondaryTeal,
                ),
                label: Text(
                  data.source == 'ml' ? 'ML-powered' : 'Rule-based',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTeal),
                ),
                backgroundColor: AppTheme.secondaryTeal.withOpacity(0.1),
                side: const BorderSide(color: AppTheme.secondaryTeal, width: 1),
              ),
            ),
          ) ?? const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkTextMuted),
            tooltip: 'Refresh insights',
            onPressed: () => ref.invalidate(insightsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: insightsAsync.when(
        loading: () => _LoadingState(),
        error: (err, _) => _ErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(insightsProvider),
        ),
        data: (data) => _InsightsList(data: data),
      ),
    );
  }
}

// ── Insights list ─────────────────────────────────────────────────────────────
class _InsightsList extends StatelessWidget {
  final InsightsResponse data;
  const _InsightsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = data.insights;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header banner
        if (data.daysOfData > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Based on your last ${data.daysOfData} day${data.daysOfData == 1 ? '' : 's'} of data',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(height: 16),
        ],

        if (insights.isEmpty)
          _EmptyState()
        else
          ...insights.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InsightCard(insight: e.value)
                    .animate(delay: Duration(milliseconds: e.key * 90))
                    .fadeIn()
                    .slideY(begin: 0.12),
              )),
      ],
    );
  }
}

// ── Insight card ──────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  static const _categoryMeta = <String, _CategoryMeta>{
    'Sleep':       _CategoryMeta(Icons.bedtime_rounded,         AppTheme.secondaryTeal),
    'Exercise':    _CategoryMeta(Icons.directions_run_rounded,  AppTheme.warningOrange),
    'Carbon':      _CategoryMeta(Icons.eco_rounded,             AppTheme.primaryGreen),
    'Diet':        _CategoryMeta(Icons.restaurant_rounded,      AppTheme.accentAmber),
    'Screen Time': _CategoryMeta(Icons.phone_android_rounded,   Color(0xFF9C27B0)),
    'Rewards':     _CategoryMeta(Icons.emoji_events_rounded,    AppTheme.accentAmber),
    'General':     _CategoryMeta(Icons.tips_and_updates_rounded, AppTheme.secondaryTeal),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _categoryMeta[insight.category] ??
        const _CategoryMeta(Icons.lightbulb_rounded, AppTheme.secondaryTeal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  insight.category,
                  style: theme.textTheme.bodySmall?.copyWith(color: meta.color),
                ),
                backgroundColor: meta.color.withOpacity(0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              // Priority indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priorityColor(insight.priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _priorityLabel(insight.priority),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _priorityColor(insight.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText),
          ),
          const SizedBox(height: 6),
          Text(
            insight.description,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: meta.color,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: meta.color.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                '→ ${insight.action}',
                style: theme.textTheme.labelLarge?.copyWith(color: meta.color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _priorityColor(int p) {
    if (p <= 1) return Colors.redAccent;
    if (p <= 2) return AppTheme.warningOrange;
    return AppTheme.secondaryTeal;
  }

  static String _priorityLabel(int p) {
    if (p <= 1) return 'High';
    if (p <= 2) return 'Medium';
    return 'Low';
  }
}

class _CategoryMeta {
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.icon, this.color);
}

// ── Loading state ─────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.04)),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.darkTextMuted),
            const SizedBox(height: 16),
            Text(
              'Could not load insights',
              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the backend is running and you have habit data logged.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.auto_awesome_rounded, size: 56, color: AppTheme.secondaryTeal),
          const SizedBox(height: 16),
          Text(
            'All habits look great!',
            style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging daily habits to unlock personalised AI insights.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
