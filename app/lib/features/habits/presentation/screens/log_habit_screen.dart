import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/habits_provider.dart';

/// Full interactive form to log all daily habits in one place.
class LogHabitScreen extends ConsumerStatefulWidget {
  const LogHabitScreen({super.key});

  @override
  ConsumerState<LogHabitScreen> createState() => _LogHabitScreenState();
}

class _LogHabitScreenState extends ConsumerState<LogHabitScreen> {
  late double _sleepHours;
  String _sleepQuality = 'good';
  late double _meals;
  String _mealType = 'mixed';
  late double _waterGlasses;
  late double _exerciseMins;
  String _exerciseType = 'walk';
  late double _screenHours;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(habitsProvider).value?.values ?? {};
    _sleepHours = existing['Sleep (6–9h)'] ?? 7.5;
    _meals = existing['Healthy Meal'] ?? 3.0;
    _waterGlasses = existing['Water (8 glasses)'] ?? 8.0;
    _exerciseMins = existing['Exercise (30 min)'] ?? 30.0;
    _screenHours = existing['Screen Time < 4h'] ?? 3.0;
  }

  Future<void> _submitForm() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(habitsProvider.notifier).logFullHabits(
            sleepHours: _sleepHours,
            sleepQuality: _sleepQuality,
            meals: _meals.round(),
            mealType: _mealType,
            waterGlasses: _waterGlasses.round(),
            exerciseMins: _exerciseMins.round(),
            exerciseType: _exerciseType,
            screenHours: _screenHours,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily habits logged successfully! Points added.',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: Text('Failed to save habits: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkText, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Log Daily Habits',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.18),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track & Level Up',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.darkText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Record today\'s activities to keep your streak & earn rewards.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 20),

            // ── Sleep Card ──
            _buildSectionCard(
              theme: theme,
              title: 'Sleep Duration',
              icon: Icons.bedtime_rounded,
              color: const Color(0xFF6366F1),
              valueLabel: '${_sleepHours.toStringAsFixed(1)} hrs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: _sliderTheme(context, const Color(0xFF6366F1)),
                    child: Slider(
                      value: _sleepHours,
                      min: 0.0,
                      max: 14.0,
                      divisions: 28,
                      onChanged: (v) => setState(() => _sleepHours = v),
                    ),
                  ),
                  _buildMinMaxLabels('0 hrs', '14 hrs'),
                  const SizedBox(height: 12),
                  Text('Sleep Quality', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['poor', 'fair', 'good', 'excellent'].map((q) {
                      final selected = _sleepQuality == q;
                      return ChoiceChip(
                        label: Text(q[0].toUpperCase() + q.substring(1)),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _sleepQuality = q);
                        },
                        selectedColor: const Color(0xFF6366F1).withOpacity(0.25),
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.darkTextMuted,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? const Color(0xFF6366F1) : AppTheme.darkBorder,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate(delay: 50.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Meals Card ──
            _buildSectionCard(
              theme: theme,
              title: 'Healthy Meals',
              icon: Icons.restaurant_rounded,
              color: AppTheme.primaryGreen,
              valueLabel: '${_meals.round()} meal${_meals.round() == 1 ? '' : 's'}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: _sliderTheme(context, AppTheme.primaryGreen),
                    child: Slider(
                      value: _meals,
                      min: 0.0,
                      max: 5.0,
                      divisions: 5,
                      onChanged: (v) => setState(() => _meals = v),
                    ),
                  ),
                  _buildMinMaxLabels('0 meals', '5 meals'),
                  const SizedBox(height: 12),
                  Text('Diet Type', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'vegan', 'label': 'Vegan 🥬'},
                      {'key': 'vegetarian', 'label': 'Vegetarian 🥦'},
                      {'key': 'mixed', 'label': 'Mixed 🥗'},
                      {'key': 'meat_heavy', 'label': 'Meat-heavy 🥩'},
                    ].map((item) {
                      final key = item['key']!;
                      final label = item['label']!;
                      final selected = _mealType == key;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _mealType = key);
                        },
                        selectedColor: AppTheme.primaryGreen.withOpacity(0.25),
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.primaryGreen : AppTheme.darkTextMuted,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? AppTheme.primaryGreen : AppTheme.darkBorder,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Hydration Card ──
            _buildSectionCard(
              theme: theme,
              title: 'Water Hydration',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF38BDF8),
              valueLabel: '${_waterGlasses.round()} glasses (~${(_waterGlasses * 0.25).toStringAsFixed(1)}L)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: _sliderTheme(context, const Color(0xFF38BDF8)),
                    child: Slider(
                      value: _waterGlasses,
                      min: 0.0,
                      max: 16.0,
                      divisions: 16,
                      onChanged: (v) => setState(() => _waterGlasses = v),
                    ),
                  ),
                  _buildMinMaxLabels('0 glasses', '16 glasses'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickAddButton('+1 Glass', 1, const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _buildQuickAddButton('+2 Glasses', 2, const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _buildQuickAddButton('Reset (0)', -16, AppTheme.darkTextMuted),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Exercise Card ──
            _buildSectionCard(
              theme: theme,
              title: 'Physical Activity',
              icon: Icons.directions_run_rounded,
              color: const Color(0xFFF59E0B),
              valueLabel: '${_exerciseMins.round()} mins',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: _sliderTheme(context, const Color(0xFFF59E0B)),
                    child: Slider(
                      value: _exerciseMins,
                      min: 0.0,
                      max: 120.0,
                      divisions: 24,
                      onChanged: (v) => setState(() => _exerciseMins = v),
                    ),
                  ),
                  _buildMinMaxLabels('0 mins', '120 mins'),
                  const SizedBox(height: 12),
                  Text('Workout Type', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'walk', 'label': 'Walk 🚶'},
                      {'key': 'run', 'label': 'Run 🏃'},
                      {'key': 'gym', 'label': 'Gym 🏋️'},
                      {'key': 'yoga', 'label': 'Yoga 🧘'},
                      {'key': 'sport', 'label': 'Sport ⚽'},
                      {'key': 'other', 'label': 'Other ✨'},
                    ].map((item) {
                      final key = item['key']!;
                      final label = item['label']!;
                      final selected = _exerciseType == key;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _exerciseType = key);
                        },
                        selectedColor: const Color(0xFFF59E0B).withOpacity(0.25),
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFFF59E0B) : AppTheme.darkTextMuted,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? const Color(0xFFF59E0B) : AppTheme.darkBorder,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 16),

            // ── Screen Time Card ──
            _buildSectionCard(
              theme: theme,
              title: 'Screen Time',
              icon: Icons.phone_android_rounded,
              color: const Color(0xFFA855F7),
              valueLabel: '${_screenHours.toStringAsFixed(1)} hrs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: _sliderTheme(context, const Color(0xFFA855F7)),
                    child: Slider(
                      value: _screenHours,
                      min: 0.0,
                      max: 12.0,
                      divisions: 24,
                      onChanged: (v) => setState(() => _screenHours = v),
                    ),
                  ),
                  _buildMinMaxLabels('0 hrs', '12 hrs'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _screenHours <= 4 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                        color: _screenHours <= 4 ? AppTheme.primaryGreen : AppTheme.accentAmber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _screenHours <= 4
                            ? 'Optimal screen time for focus & eye rest (< 4h)'
                            : 'High screen time — consider scheduled study breaks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _screenHours <= 4 ? AppTheme.primaryGreen : AppTheme.accentAmber,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 250.ms).fadeIn(),

            const SizedBox(height: 28),

            // ── Save Button ──
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.secondaryTeal],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isSaving ? null : _submitForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.save_rounded, color: Colors.black, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Save Daily Habits',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color color,
    required String valueLabel,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMinMaxLabels(String min, String max) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(min, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
          Text(max, style: const TextStyle(color: AppTheme.darkTextMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String text, int amount, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          final newVal = (_waterGlasses + amount).clamp(0.0, 16.0);
          _waterGlasses = newVal;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context, Color accent) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: accent,
      inactiveTrackColor: AppTheme.darkBorder,
      thumbColor: accent,
      overlayColor: accent.withOpacity(0.15),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
    );
  }
}
