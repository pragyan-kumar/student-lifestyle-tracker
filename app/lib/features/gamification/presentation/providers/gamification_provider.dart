import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gamification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Wallet (points + history) ────────────────────────────────────────────────

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletData>(WalletNotifier.new);

class WalletNotifier extends AsyncNotifier<WalletData> {
  @override
  Future<WalletData> build() async {
    ref.watch(authProvider); // Re-run when user logs in/out
    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getWallet();
  }

  Future<void> refresh() async {
    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getWallet());
  }
}

// ── Badges ───────────────────────────────────────────────────────────────────

final badgesProvider =
    AsyncNotifierProvider<BadgesNotifier, BadgesResult>(BadgesNotifier.new);

class BadgesNotifier extends AsyncNotifier<BadgesResult> {
  @override
  Future<BadgesResult> build() async {
    ref.watch(authProvider); // Re-run when user logs in/out
    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getBadges();
  }

  Future<void> refresh() async {
    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getBadges());
  }
}

// ── Rewards Catalogue ────────────────────────────────────────────────────────

final rewardsProvider =
    AsyncNotifierProvider<RewardsNotifier, RewardsResult>(RewardsNotifier.new);

class RewardsNotifier extends AsyncNotifier<RewardsResult> {
  @override
  Future<RewardsResult> build() async {
    ref.watch(authProvider); // Re-run when user logs in/out
    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getRewards();
  }

  Future<void> refresh() async {
    final repo = ref.read(gamificationRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getRewards());
  }

  /// Redeem a reward; returns the result and refreshes wallet + rewards.
  Future<RedeemResult> redeem(String rewardId) async {
    final repo = ref.read(gamificationRepositoryProvider);
    final result = await repo.redeemReward(rewardId);

    if (result.success) {
      // Refresh both wallet and rewards list
      ref.invalidate(walletProvider);
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
