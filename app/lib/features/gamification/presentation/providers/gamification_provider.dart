import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gamification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../habits/presentation/providers/habits_provider.dart';

// ── Wallet (points + history) ────────────────────────────────────────────────

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);

class WalletNotifier extends AsyncNotifier<WalletData> {
  @override
  Future<WalletData> build() async {
    ref.watch(authProvider);
    final summary = ref.watch(dashboardSummaryProvider).value;
    final authUser = ref.watch(authProvider).value;
    final habits = ref.watch(habitsProvider).value;

    final currentPoints = habits?.userPoints ??
        (authUser?.points != null && authUser!.points > 0
            ? authUser.points
            : summary?.user.points ?? 0);
    final currentStreak = habits?.userStreakDays ??
        (authUser?.streakDays != null && authUser!.streakDays > 0
            ? authUser.streakDays
            : summary?.user.streakDays ?? 0);

    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getWallet(
      currentPoints: currentPoints,
      streakDays: currentStreak,
    );
  }

  Future<void> refresh() async {
    final summary = ref.read(dashboardSummaryProvider).value;
    final authUser = ref.read(authProvider).value;
    final habits = ref.read(habitsProvider).value;

    final currentPoints = habits?.userPoints ??
        (authUser?.points != null && authUser!.points > 0
            ? authUser.points
            : summary?.user.points ?? 0);
    final currentStreak = habits?.userStreakDays ??
        (authUser?.streakDays != null && authUser!.streakDays > 0
            ? authUser.streakDays
            : summary?.user.streakDays ?? 0);

    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getWallet(
          currentPoints: currentPoints,
          streakDays: currentStreak,
        ));
  }
}

// ── Badges ───────────────────────────────────────────────────────────────────

final badgesProvider =
    AsyncNotifierProvider<BadgesNotifier, BadgesResult>(BadgesNotifier.new);

class BadgesNotifier extends AsyncNotifier<BadgesResult> {
  @override
  Future<BadgesResult> build() async {
    ref.watch(authProvider);
    final summary = ref.watch(dashboardSummaryProvider).value;
    final authUser = ref.watch(authProvider).value;
    final badgesCount = authUser?.badgesCount ?? summary?.user.badgesCount ?? 0;
    final streak = authUser?.streakDays ?? summary?.user.streakDays ?? 0;

    final List<String> earnedIds = [];
    if (badgesCount > 0) {
      earnedIds.add('sleep_champion');
    }
    if (streak >= 7) {
      earnedIds.add('streak_7');
    }

    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getBadges(userBadgeIds: earnedIds);
  }

  Future<void> refresh() async {
    final summary = ref.read(dashboardSummaryProvider).value;
    final authUser = ref.read(authProvider).value;
    final badgesCount = authUser?.badgesCount ?? summary?.user.badgesCount ?? 0;
    final streak = authUser?.streakDays ?? summary?.user.streakDays ?? 0;

    final List<String> earnedIds = [];
    if (badgesCount > 0) {
      earnedIds.add('sleep_champion');
    }
    if (streak >= 7) {
      earnedIds.add('streak_7');
    }

    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(
        () => repo.getBadges(userBadgeIds: earnedIds));
  }
}

// ── Rewards Catalogue ────────────────────────────────────────────────────────

final rewardsProvider =
    AsyncNotifierProvider<RewardsNotifier, RewardsResult>(RewardsNotifier.new);

class RewardsNotifier extends AsyncNotifier<RewardsResult> {
  @override
  Future<RewardsResult> build() async {
    ref.watch(authProvider);
    final summary = ref.watch(dashboardSummaryProvider).value;
    final authUser = ref.watch(authProvider).value;
    final habits = ref.watch(habitsProvider).value;

    final currentPoints = habits?.userPoints ??
        (authUser?.points != null && authUser!.points > 0
            ? authUser.points
            : summary?.user.points ?? 0);

    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getRewards(currentPoints: currentPoints);
  }

  Future<void> refresh() async {
    final summary = ref.read(dashboardSummaryProvider).value;
    final authUser = ref.read(authProvider).value;
    final habits = ref.read(habitsProvider).value;

    final currentPoints = habits?.userPoints ??
        (authUser?.points != null && authUser!.points > 0
            ? authUser.points
            : summary?.user.points ?? 0);

    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(
        () => repo.getRewards(currentPoints: currentPoints));
  }

  /// Redeem a reward; returns the result and refreshes wallet + rewards.
  Future<RedeemResult> redeem(String rewardId) async {
    final repo = ref.read(gamificationRepositoryProvider);
    final result = await repo.redeemReward(rewardId);

    if (result.success) {
      // Refresh wallet, summary, auth, and rewards list
      ref.invalidate(walletProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(authProvider);
      await refresh();
    }

    return result;
  }
}

// ── Leaderboard ──────────────────────────────────────────────────────────────

final leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getLeaderboard();
});
