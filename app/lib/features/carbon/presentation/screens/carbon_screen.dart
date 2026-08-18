import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Carbon Emission Tracker screen.
class CarbonScreen extends StatelessWidget {
  const CarbonScreen({super.key});

  // Mock data — will come from Riverpod + backend
  static const _breakdown = [
    _CarbonItem('Commute', 1.8, Icons.directions_bus_rounded, AppTheme.primaryGreen),
    _CarbonItem('Food',    1.0, Icons.restaurant_rounded,     AppTheme.secondaryTeal),
    _CarbonItem('Devices', 0.4, Icons.devices_rounded,        AppTheme.accentAmber),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _breakdown.fold(0.0, (s, i) => s + i.kg);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Carbon Tracker', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryGreen, size: 28),
            onPressed: () => context.go(AppRoutes.logCarbon),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total Footprint Card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen.withOpacity(0.15), AppTheme.secondaryTeal.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Footprint", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted)),
                        const SizedBox(height: 4),
                        Text('${total.toStringAsFixed(1)} kg CO₂', style: theme.textTheme.displayMedium?.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('🌍 Global avg student: 5.8 kg/day', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                        const SizedBox(height: 4),
                        Text('You\'re ${((5.8 - total) / 5.8 * 100).round()}% below average!', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.successGreen)),
                      ],
                    ),
                  ),
                  // Donut chart
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections: _breakdown.map((item) => PieChartSectionData(
                        value: item.kg,
                        color: item.color,
                        radius: 20,
                        title: '',
                      )).toList(),
                    )),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Breakdown ────────────────────────────────────────────────
            Text('Emission Breakdown', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
            const SizedBox(height: 12),

            ..._breakdown.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CarbonBreakdownTile(item: e.value, total: total),
            ).animate(delay: Duration(milliseconds: 100 + e.key * 80)).fadeIn().slideX(begin: 0.1)),

            const SizedBox(height: 24),

            // ── Commute Mode Selection ───────────────────────────────────
            Text('Log Today\'s Commute', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
            const SizedBox(height: 12),
            _CommuteModeGrid(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CarbonItem {
  const _CarbonItem(this.label, this.kg, this.icon, this.color);
  final String label;
  final double kg;
  final IconData icon;
  final Color color;
}

class _CarbonBreakdownTile extends StatelessWidget {
  const _CarbonBreakdownTile({required this.item, required this.total});
  final _CarbonItem item;
  final double total;

  @override
  Widget build(BuildContext context) {
    final frac = item.kg / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: item.color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.darkText)),
                    Text('${item.kg} kg', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: item.color, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: frac, backgroundColor: AppTheme.darkBorder, color: item.color, minHeight: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommuteModeGrid extends StatefulWidget {
  @override
  State<_CommuteModeGrid> createState() => _CommuteModeGridState();
}

class _CommuteModeGridState extends State<_CommuteModeGrid> {
  String? _selected;

  static const _modes = [
    {'label': 'Walk',    'icon': Icons.directions_walk_rounded,  'factor': 0.0},
    {'label': 'Bicycle', 'icon': Icons.pedal_bike_rounded,       'factor': 0.0},
    {'label': 'Metro',   'icon': Icons.subway_rounded,           'factor': 0.041},
    {'label': 'Bus',     'icon': Icons.directions_bus_rounded,   'factor': 0.089},
    {'label': 'Auto',    'icon': Icons.local_taxi_rounded,       'factor': 0.143},
    {'label': 'Car',     'icon': Icons.directions_car_rounded,   'factor': 0.192},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
      itemCount: _modes.length,
      itemBuilder: (context, i) {
        final mode = _modes[i];
        final selected = _selected == mode['label'];
        final factor = mode['factor'] as double;
        final isGreen = factor == 0.0;

        return GestureDetector(
          onTap: () => setState(() => _selected = mode['label'] as String),
          child: AnimatedContainer(
            duration: 250.ms,
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppTheme.primaryGreen : AppTheme.darkBorder, width: selected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mode['icon'] as IconData, color: selected ? AppTheme.primaryGreen : AppTheme.darkTextMuted, size: 26),
                const SizedBox(height: 6),
                Text(mode['label'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: selected ? AppTheme.primaryGreen : AppTheme.darkText)),
                if (isGreen) Text('Zero CO₂ 🌿', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.successGreen, fontSize: 9)),
              ],
            ),
          ),
        );
      },
    );
  }
}
