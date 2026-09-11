import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class DashboardHabitProgressItem {
  final String status;
  final double value;

  const DashboardHabitProgressItem({required this.status, required this.value});

  factory DashboardHabitProgressItem.fromJson(Map<String, dynamic>? json) {
    return DashboardHabitProgressItem(
      status: json?['status']?.toString() ?? 'Not logged',
      value: (json?['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardHabitStats {
  final bool hasLogged;
  final int completedCount;
  final int totalCount;
  final int percent;
  final Map<String, bool> checklist;
  final Map<String, DashboardHabitProgressItem> progress;

  const DashboardHabitStats({
    required this.hasLogged,
    required this.completedCount,
    required this.totalCount,
    required this.percent,
    required this.checklist,
    required this.progress,
  });

  factory DashboardHabitStats.empty() => const DashboardHabitStats(
        hasLogged: false,
        completedCount: 0,
        totalCount: 5,
        percent: 0,
        checklist: {},
        progress: {},
      );

  factory DashboardHabitStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardHabitStats.empty();
    final rawChecklist = json['checklist'] as Map<String, dynamic>? ?? {};
    final Map<String, bool> checklist = {
      'Sleep (6–9h)': rawChecklist['Sleep (6–9h)'] == true ||
          rawChecklist['Sleep (6-9h)'] == true,
      'Healthy Meal': rawChecklist['Healthy Meal'] == true,
      'Exercise (30 min)': rawChecklist['Exercise (30 min)'] == true,
      'Screen Time < 4h': rawChecklist['Screen Time < 4h'] == true,
      'Water (8 glasses)': rawChecklist['Water (8 glasses)'] == true,
    };

    final rawProg = json['progress'] as Map<String, dynamic>? ?? {};
    final Map<String, DashboardHabitProgressItem> progress = {
      'sleep': DashboardHabitProgressItem.fromJson(
          rawProg['sleep'] as Map<String, dynamic>?),
      'diet': DashboardHabitProgressItem.fromJson(
          rawProg['diet'] as Map<String, dynamic>?),
      'exercise': DashboardHabitProgressItem.fromJson(
          rawProg['exercise'] as Map<String, dynamic>?),
      'screen': DashboardHabitProgressItem.fromJson(
          rawProg['screen'] as Map<String, dynamic>?),
      'water': DashboardHabitProgressItem.fromJson(
          rawProg['water'] as Map<String, dynamic>?),
    };

    return DashboardHabitStats(
      hasLogged: json['hasLogged'] == true,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 5,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      checklist: checklist,
      progress: progress,
    );
  }
}

class DashboardUserStats {
  final String name;
  final String email;
  final int points;
  final int streakDays;
  final int badgesCount;

  const DashboardUserStats({
    required this.name,
    required this.email,
    required this.points,
    required this.streakDays,
    required this.badgesCount,
  });

  factory DashboardUserStats.empty() => const DashboardUserStats(
        name: 'Student',
        email: '',
        points: 0,
        streakDays: 0,
        badgesCount: 0,
      );

  factory DashboardUserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardUserStats.empty();
    return DashboardUserStats(
      name: json['name'] as String? ?? 'Student',
      email: json['email'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      badgesCount: (json['badgesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardCarbonStats {
  final bool hasLogged;
  final double totalEmissionKg;
  final double savedVsAverage;

  const DashboardCarbonStats({
    required this.hasLogged,
    required this.totalEmissionKg,
    required this.savedVsAverage,
  });

  factory DashboardCarbonStats.empty() => const DashboardCarbonStats(
        hasLogged: false,
        totalEmissionKg: 0.0,
        savedVsAverage: 0.0,
      );

  factory DashboardCarbonStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardCarbonStats.empty();
    return DashboardCarbonStats(
      hasLogged: json['hasLogged'] == true,
      totalEmissionKg: (json['totalEmissionKg'] as num?)?.toDouble() ?? 0.0,
      savedVsAverage: (json['savedVsAverage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardSummaryData {
  final DashboardUserStats user;
  final DashboardCarbonStats todayCarbon;
  final DashboardHabitStats todayHabits;
  final List<double> weeklyCarbonDaily;

  const DashboardSummaryData({
    required this.user,
    required this.todayCarbon,
    required this.todayHabits,
    required this.weeklyCarbonDaily,
  });

  factory DashboardSummaryData.empty() => DashboardSummaryData(
        user: DashboardUserStats.empty(),
        todayCarbon: DashboardCarbonStats.empty(),
        todayHabits: DashboardHabitStats.empty(),
        weeklyCarbonDaily: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      );

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) {
    final weekly = json['weeklyCarbon'] as Map<String, dynamic>?;
    final rawDaily = weekly?['dailyEmissions'] as List<dynamic>? ?? [];
    final dailyList = rawDaily.map((e) => (e as num).toDouble()).toList();

    return DashboardSummaryData(
      user: DashboardUserStats.fromJson(json['user'] as Map<String, dynamic>?),
      todayCarbon: DashboardCarbonStats.fromJson(
          json['todayCarbon'] as Map<String, dynamic>?),
      todayHabits: DashboardHabitStats.fromJson(
          json['todayHabits'] as Map<String, dynamic>?),
      weeklyCarbonDaily: dailyList.length == 7
          ? dailyList
          : const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
  }
}

final dashboardSummaryProvider =
    FutureProvider<DashboardSummaryData>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/dashboard/summary');
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return DashboardSummaryData.fromJson(res.data as Map<String, dynamic>);
    }
  } catch (_) {
    // If not logged in or offline, return empty clean state
  }
  return DashboardSummaryData.empty();
});
