import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/habits_repository.dart';
import '../providers/habits_provider.dart';

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
                      onToggle: (val) {
                        ref.read(habitsProvider.notifier).toggle(habitKey, val);
                      },
                      delay: index * 50,
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

class _HabitCheckTile extends StatelessWidget {
  const _HabitCheckTile({
    required this.label,
    required this.icon,
    required this.done,
    required this.onToggle,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final bool done;
  final ValueChanged<bool> onToggle;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onToggle(!done),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: done
                ? AppTheme.primaryGreen.withOpacity(0.08)
                : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: done
                    ? AppTheme.primaryGreen.withOpacity(0.4)
                    : AppTheme.darkBorder),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: done ? AppTheme.primaryGreen : AppTheme.darkTextMuted,
                  size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            done ? AppTheme.darkText : AppTheme.darkTextMuted,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: done ? AppTheme.primaryGreen : AppTheme.darkBorder,
                      width: 2),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.black, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.1);
  }
}
