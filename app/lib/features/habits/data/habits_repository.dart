import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Represents today's habit checklist state and stats.
class HabitChecklistData {
  final Map<String, bool> checklist;
  final int completedCount;
  final int totalCount;
  final int percent;
  final int pointsEarned;
  final int? userPoints;
  final int? userStreakDays;

  const HabitChecklistData({
    required this.checklist,
    this.completedCount = 0,
    this.totalCount = 5,
    this.percent = 0,
    this.pointsEarned = 0,
    this.userPoints,
    this.userStreakDays,
  });

  factory HabitChecklistData.empty() => const HabitChecklistData(
        checklist: {
          'Sleep (6–9h)': false,
          'Healthy Meal': false,
          'Exercise (30 min)': false,
          'Screen Time < 4h': false,
          'Water (8 glasses)': false,
        },
        completedCount: 0,
        totalCount: 5,
        percent: 0,
      );

  factory HabitChecklistData.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist'] as Map<String, dynamic>? ?? {};
    final Map<String, bool> checklist = {
      'Sleep (6–9h)': rawChecklist['Sleep (6–9h)'] == true ||
          rawChecklist['Sleep (6-9h)'] == true,
      'Healthy Meal': rawChecklist['Healthy Meal'] == true,
      'Exercise (30 min)': rawChecklist['Exercise (30 min)'] == true,
      'Screen Time < 4h': rawChecklist['Screen Time < 4h'] == true,
      'Water (8 glasses)': rawChecklist['Water (8 glasses)'] == true,
    };
    final completed = checklist.values.where((v) => v).length;
    const total = 5;
    final percent = (json['percent'] as num?)?.toInt() ??
        ((completed / total) * 100).round();

    final userObj = json['user'] as Map<String, dynamic>?;

    return HabitChecklistData(
      checklist: checklist,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? completed,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? total,
      percent: percent,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      userPoints: (userObj?['points'] as num?)?.toInt(),
      userStreakDays: (userObj?['streakDays'] as num?)?.toInt(),
    );
  }

  HabitChecklistData copyWith({
    Map<String, bool>? checklist,
    int? completedCount,
    int? totalCount,
    int? percent,
    int? pointsEarned,
    int? userPoints,
    int? userStreakDays,
  }) {
    return HabitChecklistData(
      checklist: checklist ?? this.checklist,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      percent: percent ?? this.percent,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      userPoints: userPoints ?? this.userPoints,
      userStreakDays: userStreakDays ?? this.userStreakDays,
    );
  }
}

/// Habits API repository communicating with backend.
class HabitsRepository {
  final Dio _dio;

  HabitsRepository(this._dio);

  Future<HabitChecklistData> getTodayHabits() async {
    try {
      final res = await _dio.get('/habits/today');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return HabitChecklistData.fromJson(res.data as Map<String, dynamic>);
      }
      return HabitChecklistData.empty();
    } catch (_) {
      return HabitChecklistData.empty();
    }
  }

  Future<HabitChecklistData> toggleHabit(String habit, bool done) async {
    final res = await _dio.post('/habits/checklist/toggle', data: {
      'habit': habit,
      'done': done,
    });
    return HabitChecklistData.fromJson(res.data as Map<String, dynamic>);
  }

  /// Logs a numeric value for a habit (e.g. 7.5 hours of sleep, 8 glasses).
  /// Maps the slider double to the correct field in the backend payload.
  Future<HabitChecklistData> logHabitValue(String habit, double value) async {
    final Map<String, dynamic> payload = _buildPayload(habit, value);
    try {
      final res = await _dio.post('/habits/log', data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          // Some backends return the full checklist, others return the log entry.
          // Try to parse as checklist data; fall back to toggling done.
          final data = res.data as Map<String, dynamic>;
          if (data.containsKey('checklist')) {
            return HabitChecklistData.fromJson(data);
          }
        }
      }
    } catch (_) {
      // Ignore — caller handles fallback
    }
    // Fallback: toggle the habit done via the checklist endpoint
    return toggleHabit(habit, true);
  }

  static Map<String, dynamic> _buildPayload(String habit, double value) {
    switch (habit) {
      case 'Sleep (6–9h)':
        return {'sleep': {'hours': value}};
      case 'Healthy Meal':
        return {'diet': {'meals': value.round()}};
      case 'Exercise (30 min)':
        return {'exercise': {'durationMins': value.round()}};
      case 'Screen Time < 4h':
        return {'screenTime': {'hours': value}};
      case 'Water (8 glasses)':
        return {'water': {'glasses': value.round()}};
      default:
        return {'habit': habit, 'value': value};
    }
  }
}

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HabitsRepository(dio);
});
