import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/carbon_provider.dart';
import '../../data/models/carbon_entry.dart';

// ── Carbon Screen (TabController wrapping 3 modules) ─────────────────────────

class CarbonScreen extends ConsumerStatefulWidget {
  const CarbonScreen({super.key});
  @override
  ConsumerState<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends ConsumerState<CarbonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carbonCalculatorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text('Carbon Calculator',
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.darkText, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkTextMuted),
            tooltip: 'Reset today\'s data',
            onPressed: () {
              ref.read(carbonCalculatorProvider.notifier).reset();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryTeal],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: AppTheme.darkTextMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.directions_car_rounded, size: 18), text: 'Transport'),
                Tab(icon: Icon(Icons.restaurant_rounded, size: 18), text: 'Food'),
                Tab(icon: Icon(Icons.bolt_rounded, size: 18), text: 'Energy'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Summary card ─────────────────────────────────────────────────
          _SummaryCard(state: state),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TransportTab(),
                _FoodTab(),
                _EnergyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final CarbonCalculatorState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalKg;
    final hasData = total > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.15),
              AppTheme.secondaryTeal.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Donut chart
            SizedBox(
              width: 80,
              height: 80,
              child: hasData
                  ? PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 22,
                      sections: [
                        PieChartSectionData(
                          value: state.transportKg,
                          color: AppTheme.primaryGreen,
                          radius: 18,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: state.foodKg,
                          color: AppTheme.secondaryTeal,
                          radius: 18,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: state.energyKg,
                          color: AppTheme.accentAmber,
                          radius: 18,
                          title: '',
                        ),
                      ],
                    ))
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.darkBorder, width: 6),
                      ),
                      child: const Center(
                        child: Text('—',
                            style: TextStyle(
                                color: AppTheme.darkTextMuted, fontSize: 18)),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Total",
                      style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${total.toStringAsFixed(2)} kg CO₂e',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniChip('🚗 ${state.transportKg.toStringAsFixed(1)}', AppTheme.primaryGreen),
                      const SizedBox(width: 6),
                      _MiniChip('🍽 ${state.foodKg.toStringAsFixed(1)}', AppTheme.secondaryTeal),
                      const SizedBox(width: 6),
                      _MiniChip('⚡ ${state.energyKg.toStringAsFixed(1)}', AppTheme.accentAmber),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

// ── Result Card (shared across tabs) ─────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.kg});
  final double kg;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    if (kg == 0.0) {
      color = AppTheme.primaryGreen;
      label = 'Zero Emission 🌿';
      icon = Icons.eco_rounded;
    } else if (kg < 2.0) {
      color = AppTheme.primaryGreen;
      label = 'Low Impact';
      icon = Icons.thumb_up_rounded;
    } else if (kg < 5.0) {
      color = AppTheme.accentAmber;
      label = 'Moderate Impact';
      icon = Icons.warning_amber_rounded;
    } else {
      color = const Color(0xFFDC143C);
      label = 'High Impact';
      icon = Icons.dangerous_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${kg.toStringAsFixed(3)} kg CO₂e',
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95)).fadeIn(duration: 350.ms);
  }
}

// ── History List (shared) ────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.entries, required this.moduleFilter});
  final List<CarbonEntry> entries;
  final String moduleFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = entries.where((e) => e.module == moduleFilter).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Today\'s Logs',
            style: TextStyle(
                color: AppTheme.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...filtered.take(5).toList().asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryTile(entry: e.value),
            ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: 0.1)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final CarbonEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.module == 'transport'
        ? AppTheme.primaryGreen
        : entry.module == 'food'
            ? AppTheme.secondaryTeal
            : AppTheme.accentAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label,
                    style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w500)),
                if (entry.detail != null)
                  Text(entry.detail!,
                      style:
                          const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              ],
            ),
          ),
          Text('${entry.carbonKg.toStringAsFixed(3)} kg',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — TRANSPORT
// ─────────────────────────────────────────────────────────────────────────────

class _TransportTab extends ConsumerStatefulWidget {
  const _TransportTab();
  @override
  ConsumerState<_TransportTab> createState() => _TransportTabState();
}

class _TransportTabState extends ConsumerState<_TransportTab> {
  String _selectedMode = 'Car';
  double _distanceKm = 10.0;
  bool _isFlightMode = false;

  final _departureCtrl = TextEditingController(text: 'DEL');
  final _destinationCtrl = TextEditingController(text: 'BOM');
  int _passengers = 1;

  static const _modes = [
    {'label': 'Walk', 'icon': Icons.directions_walk_rounded, 'flight': false},
    {'label': 'Bicycle', 'icon': Icons.pedal_bike_rounded, 'flight': false},
    {'label': 'Metro', 'icon': Icons.subway_rounded, 'flight': false},
    {'label': 'Bus', 'icon': Icons.directions_bus_rounded, 'flight': false},
    {'label': 'Auto', 'icon': Icons.electric_rickshaw_rounded, 'flight': false},
    {'label': 'Motorcycle', 'icon': Icons.two_wheeler_rounded, 'flight': false},
    {'label': 'Car', 'icon': Icons.directions_car_rounded, 'flight': false},
    {'label': 'Flight', 'icon': Icons.flight_rounded, 'flight': true},
  ];

  @override
  void dispose() {
    _departureCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final notifier = ref.read(carbonCalculatorProvider.notifier);
    if (_isFlightMode) {
      notifier.calculateFlight(
        departure: _departureCtrl.text.trim(),
        destination: _destinationCtrl.text.trim(),
        passengers: _passengers,
      );
    } else {
      notifier.calculateTransport(mode: _selectedMode, distanceKm: _distanceKm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carbonCalculatorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab label
          _TabHeader(
            icon: Icons.directions_car_rounded,
            color: AppTheme.primaryGreen,
            title: 'Transport Emissions',
            subtitle: 'Calculate CO₂ from your daily commute & travel',
          ),
          const SizedBox(height: 16),

          // Mode grid
          const Text('Select Mode',
              style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1),
            itemCount: _modes.length,
            itemBuilder: (context, i) {
              final mode = _modes[i];
              final label = mode['label'] as String;
              final icon = mode['icon'] as IconData;
              final isFlight = mode['flight'] as bool;
              final selected = _selectedMode == label;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMode = label;
                  _isFlightMode = isFlight;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryGreen.withOpacity(0.15)
                        : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? AppTheme.primaryGreen : AppTheme.darkBorder,
                        width: selected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          color: selected ? AppTheme.primaryGreen : AppTheme.darkTextMuted,
                          size: 22),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                              color: selected ? AppTheme.primaryGreen : AppTheme.darkText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Flight inputs ──────────────────────────────────────────────────
          if (_isFlightMode) ...[
            const Text('Flight Details',
                style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    label: 'From (IATA)',
                    hint: 'DEL',
                    controller: _departureCtrl,
                    onChanged: (_) {},
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.darkTextMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    label: 'To (IATA)',
                    hint: 'BOM',
                    controller: _destinationCtrl,
                    onChanged: (_) {},
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Passengers:',
                    style: TextStyle(color: AppTheme.darkText, fontSize: 13)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() => _passengers = (_passengers - 1).clamp(1, 10)),
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppTheme.primaryGreen),
                ),
                Text('$_passengers',
                    style: const TextStyle(
                        color: AppTheme.darkText, fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => setState(() => _passengers = (_passengers + 1).clamp(1, 10)),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ]

          // ── Distance slider ────────────────────────────────────────────────
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Distance',
                    style: TextStyle(
                        color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text('${_distanceKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryGreen,
                inactiveTrackColor: AppTheme.darkBorder,
                thumbColor: AppTheme.primaryGreen,
                overlayColor: AppTheme.primaryGreen.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _distanceKm,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => _distanceKm = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('1 km', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                Text('100 km', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Calculate button
          _CalculateButton(
            isLoading: state.isLoading,
            onPressed: _calculate,
          ),

          // Result
          if (state.lastResultKg != null) ...[
            const SizedBox(height: 16),
            _ResultCard(kg: state.lastResultKg!),
          ],
          if (state.error != null)
            _ErrorBanner(message: state.error!),

          // History
          _HistorySection(entries: state.todayEntries, moduleFilter: 'transport'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — FOOD
// ─────────────────────────────────────────────────────────────────────────────

class _FoodTab extends ConsumerStatefulWidget {
  const _FoodTab();
  @override
  ConsumerState<_FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends ConsumerState<_FoodTab> {
  String _selectedKey = 'chicken';
  String _selectedLabel = 'Chicken';
  double _grams = 200.0;

  static const _foods = [
    {'key': 'beef', 'label': 'Beef', 'icon': '🥩', 'factor': 27.0},
    {'key': 'lamb', 'label': 'Lamb', 'icon': '🍖', 'factor': 39.2},
    {'key': 'pork', 'label': 'Pork', 'icon': '🥓', 'factor': 12.1},
    {'key': 'chicken', 'label': 'Chicken', 'icon': '🍗', 'factor': 6.9},
    {'key': 'fish', 'label': 'Fish', 'icon': '🐟', 'factor': 6.1},
    {'key': 'eggs', 'label': 'Eggs', 'icon': '🥚', 'factor': 4.5},
    {'key': 'dairy', 'label': 'Dairy', 'icon': '🥛', 'factor': 3.2},
    {'key': 'rice', 'label': 'Rice', 'icon': '🍚', 'factor': 2.7},
    {'key': 'wheat', 'label': 'Wheat', 'icon': '🌾', 'factor': 1.5},
    {'key': 'vegetables', 'label': 'Veggies', 'icon': '🥦', 'factor': 2.0},
    {'key': 'fruits', 'label': 'Fruits', 'icon': '🍎', 'factor': 1.4},
    {'key': 'lentils', 'label': 'Lentils', 'icon': '🫘', 'factor': 0.9},
    {'key': 'tofu', 'label': 'Tofu', 'icon': '🧈', 'factor': 2.0},
    {'key': 'nuts', 'label': 'Nuts', 'icon': '🥜', 'factor': 2.6},
  ];

  void _calculate() {
    ref.read(carbonCalculatorProvider.notifier).calculateFood(
          foodKey: _selectedKey,
          foodLabel: _selectedLabel,
          grams: _grams,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carbonCalculatorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabHeader(
            icon: Icons.restaurant_rounded,
            color: AppTheme.secondaryTeal,
            title: 'Food Emissions',
            subtitle: 'Based on IPCC & Poore & Nemecek (2018) life-cycle factors',
          ),
          const SizedBox(height: 16),

          // Food grid
          const Text('Select Food Item',
              style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0),
            itemCount: _foods.length,
            itemBuilder: (context, i) {
              final food = _foods[i];
              final key = food['key'] as String;
              final label = food['label'] as String;
              final icon = food['icon'] as String;
              final factor = food['factor'] as double;
              final selected = _selectedKey == key;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedKey = key;
                  _selectedLabel = label;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.secondaryTeal.withOpacity(0.15)
                        : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? AppTheme.secondaryTeal : AppTheme.darkBorder,
                        width: selected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(label,
                          style: TextStyle(
                              color: selected ? AppTheme.secondaryTeal : AppTheme.darkText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                      Text('${factor.toStringAsFixed(1)} kg/kg',
                          style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 8)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Quantity slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity',
                  style: TextStyle(
                      color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.3)),
                ),
                child: Text('${_grams.toStringAsFixed(0)} g',
                    style: const TextStyle(
                        color: AppTheme.secondaryTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.secondaryTeal,
              inactiveTrackColor: AppTheme.darkBorder,
              thumbColor: AppTheme.secondaryTeal,
              overlayColor: AppTheme.secondaryTeal.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _grams,
              min: 50,
              max: 1000,
              divisions: 19,
              onChanged: (v) => setState(() => _grams = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('50 g', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              Text('1000 g (1 kg)', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),

          _CalculateButton(
            isLoading: false,
            onPressed: _calculate,
            color: AppTheme.secondaryTeal,
          ),

          if (state.lastResultKg != null) ...[
            const SizedBox(height: 16),
            _ResultCard(kg: state.lastResultKg!),
          ],
          if (state.error != null) _ErrorBanner(message: state.error!),

          _HistorySection(entries: state.todayEntries, moduleFilter: 'food'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — ENERGY
// ─────────────────────────────────────────────────────────────────────────────

class _EnergyTab extends ConsumerStatefulWidget {
  const _EnergyTab();
  @override
  ConsumerState<_EnergyTab> createState() => _EnergyTabState();
}

class _EnergyTabState extends ConsumerState<_EnergyTab> {
  bool _isElectricity = true;
  double _kwh = 5.0;
  String _country = 'in';
  String _fuelType = 'lpg';
  String _fuelLabel = 'LPG';
  double _litres = 10.0;

  static const _countries = [
    {'code': 'in', 'label': '🇮🇳 India'},
    {'code': 'us', 'label': '🇺🇸 USA'},
    {'code': 'gb', 'label': '🇬🇧 UK'},
    {'code': 'de', 'label': '🇩🇪 Germany'},
    {'code': 'au', 'label': '🇦🇺 Australia'},
  ];

  static const _fuels = [
    {'type': 'lpg', 'label': 'LPG', 'icon': '🔵'},
    {'type': 'pet', 'label': 'Petrol', 'icon': '⛽'},
    {'type': 'dlo', 'label': 'Diesel', 'icon': '🛢'},
    {'type': 'ng', 'label': 'Natural Gas', 'icon': '💨'},
  ];

  void _calculate() {
    final notifier = ref.read(carbonCalculatorProvider.notifier);
    if (_isElectricity) {
      notifier.calculateElectricity(kwh: _kwh, country: _country);
    } else {
      notifier.calculateFuel(fuelType: _fuelType, fuelLabel: _fuelLabel, litres: _litres);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carbonCalculatorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabHeader(
            icon: Icons.bolt_rounded,
            color: AppTheme.accentAmber,
            title: 'Energy Emissions',
            subtitle: 'Electricity & fuel use calculated via Carbon Interface API',
          ),
          const SizedBox(height: 16),

          // Toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isElectricity = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isElectricity
                            ? AppTheme.accentAmber.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: _isElectricity
                            ? Border.all(color: AppTheme.accentAmber.withOpacity(0.5))
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: _isElectricity
                                  ? AppTheme.accentAmber
                                  : AppTheme.darkTextMuted,
                              size: 18),
                          const SizedBox(width: 6),
                          Text('Electricity',
                              style: TextStyle(
                                color: _isElectricity
                                    ? AppTheme.accentAmber
                                    : AppTheme.darkTextMuted,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isElectricity = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isElectricity
                            ? AppTheme.accentAmber.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: !_isElectricity
                            ? Border.all(color: AppTheme.accentAmber.withOpacity(0.5))
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: !_isElectricity
                                  ? AppTheme.accentAmber
                                  : AppTheme.darkTextMuted,
                              size: 18),
                          const SizedBox(width: 6),
                          Text('Fuel',
                              style: TextStyle(
                                color: !_isElectricity
                                    ? AppTheme.accentAmber
                                    : AppTheme.darkTextMuted,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Electricity inputs ─────────────────────────────────────────────
          if (_isElectricity) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Electricity Used',
                    style: TextStyle(
                        color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                  ),
                  child: Text('${_kwh.toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.accentAmber,
                inactiveTrackColor: AppTheme.darkBorder,
                thumbColor: AppTheme.accentAmber,
                overlayColor: AppTheme.accentAmber.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _kwh,
                min: 0.5,
                max: 100,
                divisions: 199,
                onChanged: (v) => setState(() => _kwh = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0.5 kWh', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                Text('100 kWh', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Country / Grid',
                style: TextStyle(
                    color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _countries.map((c) {
                final code = c['code'] as String;
                final label = c['label'] as String;
                final selected = _country == code;
                return GestureDetector(
                  onTap: () => setState(() => _country = code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accentAmber.withOpacity(0.15) : AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppTheme.accentAmber : AppTheme.darkBorder,
                          width: selected ? 2 : 1),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: selected ? AppTheme.accentAmber : AppTheme.darkText,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ]

          // ── Fuel inputs ────────────────────────────────────────────────────
          else ...[
            const Text('Fuel Type',
                style: TextStyle(
                    color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: _fuels.map((f) {
                final type = f['type'] as String;
                final label = f['label'] as String;
                final icon = f['icon'] as String;
                final selected = _fuelType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _fuelType = type;
                      _fuelLabel = label;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accentAmber.withOpacity(0.15) : AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected ? AppTheme.accentAmber : AppTheme.darkBorder,
                              width: selected ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(label,
                                style: TextStyle(
                                    color: selected ? AppTheme.accentAmber : AppTheme.darkText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity',
                    style: TextStyle(
                        color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                  ),
                  child: Text('${_litres.toStringAsFixed(1)} L',
                      style: const TextStyle(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.accentAmber,
                inactiveTrackColor: AppTheme.darkBorder,
                thumbColor: AppTheme.accentAmber,
                overlayColor: AppTheme.accentAmber.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _litres,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => _litres = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('1 L', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                Text('100 L', style: TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
              ],
            ),
          ],

          const SizedBox(height: 20),

          _CalculateButton(
            isLoading: state.isLoading,
            onPressed: _calculate,
            color: AppTheme.accentAmber,
            labelText: _isElectricity ? 'Calculate Electricity CO₂' : 'Calculate Fuel CO₂',
          ),

          if (state.lastResultKg != null) ...[
            const SizedBox(height: 16),
            _ResultCard(kg: state.lastResultKg!),
          ],
          if (state.error != null) _ErrorBanner(message: state.error!),

          _HistorySection(entries: state.todayEntries, moduleFilter: 'energy'),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton({
    required this.isLoading,
    required this.onPressed,
    this.color = AppTheme.primaryGreen,
    this.labelText = 'Calculate CO₂',
  });
  final bool isLoading;
  final VoidCallback onPressed;
  final Color color;
  final String labelText;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(labelText, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    this.controller,
    required this.onChanged,
    this.inputFormatters,
  });
  final String label;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.darkTextMuted),
          filled: true,
          fillColor: AppTheme.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDC143C).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDC143C).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC143C), size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(message,
                      style: const TextStyle(color: Color(0xFFDC143C), fontSize: 12))),
            ],
          ),
        ),
      );
}
