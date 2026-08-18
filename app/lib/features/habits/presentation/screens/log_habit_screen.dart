import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Log Habit entry form — sleep, exercise, diet, screen time in one form.
class LogHabitScreen extends StatelessWidget {
  const LogHabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.darkText), onPressed: () => context.pop()),
        title: Text('Log Today\'s Habits', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
      ),
      body: const Center(child: Text('Habit logging form — coming next sprint', style: TextStyle(color: AppTheme.darkTextMuted))),
    );
  }
}
