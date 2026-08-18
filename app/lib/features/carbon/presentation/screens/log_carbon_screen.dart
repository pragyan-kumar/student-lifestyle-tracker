import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Log Carbon entry — commute mode + distance, meal type, device hours.
class LogCarbonScreen extends StatelessWidget {
  const LogCarbonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.darkText), onPressed: () => context.pop()),
        title: Text('Log Carbon Footprint', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.darkText)),
      ),
      body: const Center(child: Text('Carbon logging form — coming next sprint', style: TextStyle(color: AppTheme.darkTextMuted))),
    );
  }
}
