import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habits_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HabitsNotifier extends AsyncNotifier<HabitChecklistData> {
  @override
  Future<HabitChecklistData> build() async {
    final repo = ref.watch(habitsRepositoryProvider);
    return repo.getTodayHabits();
  }

  Future<void> toggle(String habit, bool done) async {
    final previousState = state.value ?? HabitChecklistData.empty();

    // 1. Optimistic UI update
    final newChecklist = Map<String, bool>.from(previousState.checklist);
    newChecklist[habit] = done;
    final completed = newChecklist.values.where((v) => v).length;
    final percent = ((completed / 5) * 100).round();

    final optimisticState = previousState.copyWith(
      checklist: newChecklist,
      completedCount: completed,
      percent: percent,
    );

    state = AsyncData(optimisticState);

    // 2. Persist to backend — if it fails, keep optimistic state (offline/no-auth mode)
    try {
      final repo = ref.read(habitsRepositoryProvider);
      final updated = await repo.toggleHabit(habit, done);
      state = AsyncData(updated);

      // 3. Trigger Home / Dashboard refresh
      ref.invalidate(dashboardSummaryProvider);
      if (updated.userPoints != null) {
        ref.invalidate(authProvider);
      }
    } catch (e) {
      // API failed (e.g. no auth) — keep the optimistic state so the UI stays responsive.
      print(
          '[HabitsProvider] toggle API failed (offline/no-auth), keeping local state: $e');
      state = AsyncData(optimisticState);
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(habitsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getTodayHabits());
  }
}

final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, HabitChecklistData>(
  () => HabitsNotifier(),
);
