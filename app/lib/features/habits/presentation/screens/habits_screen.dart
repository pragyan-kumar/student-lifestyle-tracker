import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/habits_repository.dart';
import '../providers/habits_provider.dart';

// ── Slider config ─────────────────────────────────────────────────────────────

class _HabitSliderConfig {
  final double min;
  final double max;
  final int divisions;
  final String Function(double) label;

  const _HabitSliderConfig({
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
  });
}

_HabitSliderConfig _configFor(String habitKey) {
  switch (habitKey) {
    case 'Sleep (6–9h)':
      return _HabitSliderConfig(
        min: 0, max: 12, divisions: 24,
        label: (v) => '${v.toStringAsFixed(1)} hrs',
      );
    case 'Healthy Meal':
      return _HabitSliderConfig(
        min: 0, max: 5, divisions: 5,
        label: (v) => '${v.round()} meal${v.round() == 1 ? '' : 's'}',
      );
    case 'Exercise (30 min)':
      return _HabitSliderConfig(
        min: 0, max: 120, divisions: 24,
        label: (v) => '${v.round()} min',
      );
    case 'Screen Time < 4h':
      return _HabitSliderConfig(
        min: 0, max: 12, divisions: 24,
        label: (v) => '${v.toStringAsFixed(1)} hrs',
      );
    case 'Water (8 glasses)':
      return _HabitSliderConfig(
        min: 0, max: 16, divisions: 16,
        label: (v) => '${v.round()} glass${v.round() == 1 ? '' : 'es'}',
      );
    default:
      return _HabitSliderConfig(
        min: 0, max: 10, divisions: 10,
        label: (v) => v.round().toString(),
      );
  }
}

double _defaultFor(String habitKey) {
  switch (habitKey) {
    case 'Sleep (6–9h)': return 7.0;
    case 'Healthy Meal': return 3.0;
    case 'Exercise (30 min)': return 30.0;
    case 'Screen Time < 4h': return 2.0;
    case 'Water (8 glasses)': return 8.0;
    default: return 5.0;
  }
}

/// Habit tracker screen showing streak calendar and today's habit checklist.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const List<String> _habitKeys = [
    'Sleep (6–9h)',
    'Healthy Meal',
    'Exercise (30 min)',
    'Screen Time < 4h',
    'Water (8 glasses)',
  ];

  static const Map<String, IconData> _habitIcons = {
    'Sleep (6–9h)': Icons.bedtime_rounded,
    'Healthy Meal': Icons.restaurant_rounded,
    'Exercise (30 min)': Icons.directions_run_rounded,
    'Screen Time < 4h': Icons.phone_android_rounded,
    'Water (8 glasses)': Icons.water_drop_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);
    final habitsData = habitsAsync.value ?? HabitChecklistData.empty();
    final checklist = habitsData.checklist;
    final completed = habitsData.completedCount;
    final total = habitsData.totalCount > 0 ? habitsData.totalCount : 5;
    final percent = habitsData.percent;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Habit Tracker',
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.darkText)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppTheme.primaryGreen, size: 28),
            onPressed: () => context.go(AppRoutes.logHabit),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: AppTheme.darkCard,
        onRefresh: () => ref.read(habitsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ── Progress header ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.primaryGreen.withOpacity(0.15),
                          Colors.transparent,
                        ]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today\'s Progress',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: AppTheme.darkText)),
                                const SizedBox(height: 4),
                                Text('$completed / $total habits completed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.darkTextMuted)),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? completed / total : 0.0,
                                    backgroundColor: AppTheme.darkBorder,
                                    color: AppTheme.primaryGreen,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$percent%',
                            style: theme.textTheme.headlineLarge?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    // ── Streak Calendar ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2026, 1, 1),
                        lastDay: DateTime.utc(2027, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: theme.textTheme.bodyMedium!
                              .copyWith(color: AppTheme.darkText),
                          weekendTextStyle: theme.textTheme.bodyMedium!
                              .copyWith(color: AppTheme.darkTextMuted),
                          todayDecoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle),
                          selectedDecoration: const BoxDecoration(
                              color: AppTheme.secondaryTeal,
                              shape: BoxShape.circle),
                          outsideDaysVisible: false,
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: theme.textTheme.titleMedium!
                              .copyWith(color: AppTheme.darkText),
                          leftChevronIcon: const Icon(Icons.chevron_left,
                              color: AppTheme.darkTextMuted),
                          rightChevronIcon: const Icon(Icons.chevron_right,
                              color: AppTheme.darkTextMuted),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: theme.textTheme.bodySmall!
                              .copyWith(color: AppTheme.darkTextMuted),
                          weekendStyle: theme.textTheme.bodySmall!
                              .copyWith(color: AppTheme.darkTextMuted),
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // ── Today's Habit Checklist ─────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Today\'s Checklist',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: AppTheme.darkText)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Habit list ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habitKey = _habitKeys[index];
                    final isDone = checklist[habitKey] ?? false;
                    final icon =
                        _habitIcons[habitKey] ?? Icons.check_circle_outline;

                    return _HabitCheckTile(
                      label: habitKey,
                      icon: icon,
                      done: isDone,
                      delay: index * 50,
                      onToggle: (val) {
                        ref.read(habitsProvider.notifier).toggle(habitKey, val);
                      },
                      onLogValue: (value) async {
                        await ref
                            .read(habitsProvider.notifier)
                            .logValue(habitKey, value);
                      },
                    );
                  },
                  childCount: _habitKeys.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ── Expandable habit tile ─────────────────────────────────────────────────────

class _HabitCheckTile extends StatefulWidget {
  const _HabitCheckTile({
    required this.label,
    required this.icon,
    required this.done,
    required this.onToggle,
    required this.onLogValue,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final bool done;
  final ValueChanged<bool> onToggle;
  final Future<void> Function(double) onLogValue;
  final int delay;

  @override
  State<_HabitCheckTile> createState() => _HabitCheckTileState();
}

class _HabitCheckTileState extends State<_HabitCheckTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _saving = false;
  late double _sliderValue;
  late final _HabitSliderConfig _cfg;
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _cfg = _configFor(widget.label);
    _sliderValue = _defaultFor(widget.label);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onLogValue(_sliderValue);
      if (!widget.done) widget.onToggle(true);
      setState(() => _expanded = false);
      _animCtrl.reverse();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = widget.done;
    final accent =
        isDone ? AppTheme.primaryGreen : AppTheme.secondaryTeal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDone
              ? AppTheme.primaryGreen.withOpacity(0.07)
              : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? accent.withOpacity(0.55)
                : isDone
                    ? AppTheme.primaryGreen.withOpacity(0.4)
                    : AppTheme.darkBorder,
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            // ── Header row ────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggleExpand,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.primaryGreen.withOpacity(0.18)
                            : AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isDone
                            ? AppTheme.primaryGreen
                            : AppTheme.darkTextMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDone
                              ? AppTheme.darkText
                              : AppTheme.darkTextMuted,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: _expanded ? accent : AppTheme.darkTextMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onToggle(!isDone),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone
                                ? AppTheme.primaryGreen
                                : AppTheme.darkBorder,
                            width: 2,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.black, size: 16)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable slider panel ────────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: _expandAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: AppTheme.darkBorder, height: 1),
                      const SizedBox(height: 14),

                      // Label + live value pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Log your value',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkTextMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: accent.withOpacity(0.4)),
                            ),
                            child: Text(
                              _cfg.label(_sliderValue),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accent,
                          inactiveTrackColor: AppTheme.darkBorder,
                          thumbColor: accent,
                          overlayColor: accent.withOpacity(0.15),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          min: _cfg.min,
                          max: _cfg.max,
                          divisions: _cfg.divisions,
                          onChanged: (v) =>
                              setState(() => _sliderValue = v),
                        ),
                      ),

                      // Min / Max labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_cfg.label(_cfg.min),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: AppTheme.darkTextMuted)),
                            Text(_cfg.label(_cfg.max),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: AppTheme.darkTextMuted)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _saving
                                  ? [AppTheme.darkBorder, AppTheme.darkBorder]
                                  : [accent, accent.withOpacity(0.75)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _saving ? null : _save,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: _saving
                                    ? const Center(
                                        child: SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.save_rounded,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Save Log',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.delay)).fadeIn().slideX(begin: 0.1);
  }
}
