import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

// ── Data models ──────────────────────────────────────────────────────────────

class PointHistoryEntry {
  final String id;
  final String label;
  final int amount;
  final int balance;
  final String type;
  final DateTime date;

  const PointHistoryEntry({
    required this.id,
    required this.label,
    required this.amount,
    required this.balance,
    required this.type,
    required this.date,
  });

  factory PointHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PointHistoryEntry(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        type: json['type'] as String? ?? 'habit',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      );
}

class WalletData {
  final int points;
  final int streakDays;
  final List<PointHistoryEntry> history;

  const WalletData({
    required this.points,
    required this.streakDays,
    required this.history,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
        points: (json['points'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        history: (json['history'] as List<dynamic>?)
                ?.map((e) =>
                    PointHistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static WalletData empty() =>
      const WalletData(points: 0, streakDays: 0, history: []);
}

class BadgeData {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final bool earned;

  const BadgeData({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.earned,
  });

  factory BadgeData.fromJson(Map<String, dynamic> json) => BadgeData(
        id: json['id'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🏅',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        earned: json['earned'] as bool? ?? false,
      );
}

class BadgesResult {
  final List<BadgeData> badges;
  final List<String> newlyEarned;

  const BadgesResult({required this.badges, required this.newlyEarned});

  factory BadgesResult.fromJson(Map<String, dynamic> json) => BadgesResult(
        badges: (json['badges'] as List<dynamic>?)
                ?.map((e) => BadgeData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        newlyEarned: (json['newlyEarned'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
      );

  static BadgesResult empty() =>
      const BadgesResult(badges: [], newlyEarned: []);
}

class RewardItem {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final int cost;
  final String perkType;
  final bool canAfford;
  final bool alreadyRedeemed;
  final bool available;

  const RewardItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.cost,
    required this.perkType,
    required this.canAfford,
    required this.alreadyRedeemed,
    required this.available,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
        id: json['id'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🎁',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        cost: (json['cost'] as num?)?.toInt() ?? 0,
        perkType: json['perkType'] as String? ?? '',
        canAfford: json['canAfford'] as bool? ?? false,
        alreadyRedeemed: json['alreadyRedeemed'] as bool? ?? false,
        available: json['available'] as bool? ?? false,
      );
}

class RewardsResult {
  final List<RewardItem> rewards;
  final int userPoints;

  const RewardsResult({required this.rewards, required this.userPoints});

  factory RewardsResult.fromJson(Map<String, dynamic> json) => RewardsResult(
        rewards: (json['rewards'] as List<dynamic>?)
                ?.map((e) => RewardItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        userPoints: (json['userPoints'] as num?)?.toInt() ?? 0,
      );

  static RewardsResult empty() =>
      const RewardsResult(rewards: [], userPoints: 0);
}

class RedeemResult {
  final bool success;
  final String rewardName;
  final int pointsSpent;
  final int remainingPoints;
  final String perkType;
  final String? error;

  const RedeemResult({
    required this.success,
    this.rewardName = '',
    this.pointsSpent = 0,
    this.remainingPoints = 0,
    this.perkType = '',
    this.error,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> json) => RedeemResult(
        success: json['success'] as bool? ?? false,
        rewardName: json['rewardName'] as String? ?? '',
        pointsSpent: (json['pointsSpent'] as num?)?.toInt() ?? 0,
        remainingPoints: (json['remainingPoints'] as num?)?.toInt() ?? 0,
        perkType: json['perkType'] as String? ?? '',
      );

  factory RedeemResult.error(String msg) => RedeemResult(
        success: false,
        error: msg,
      );
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final int streakDays;
  final int badgesCount;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.streakDays,
    required this.badgesCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        badgesCount: (json['badgesCount'] as num?)?.toInt() ?? 0,
      );
}

// ── Repository ───────────────────────────────────────────────────────────────

class GamificationRepository {
  final Dio _dio;

  GamificationRepository(this._dio);

  Future<WalletData> getWallet() async {
    try {
      final res = await _dio.get('/gamification/wallet');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return WalletData.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      print('[GamificationRepo] getWallet error: $e');
    }
    return WalletData.empty();
  }

  Future<BadgesResult> getBadges() async {
    try {
      final res = await _dio.get('/gamification/badges');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return BadgesResult.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      print('[GamificationRepo] getBadges error: $e');
    }
    return BadgesResult.empty();
  }

  Future<RewardsResult> getRewards() async {
    try {
      final res = await _dio.get('/gamification/rewards');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return RewardsResult.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      print('[GamificationRepo] getRewards error: $e');
    }
    return RewardsResult.empty();
  }

  Future<RedeemResult> redeemReward(String rewardId) async {
    try {
      final res = await _dio.post('/gamification/redeem', data: {
        'rewardId': rewardId,
      });
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return RedeemResult.fromJson(res.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?.toString() ?? e.message ?? 'Redeem failed';
      print('[GamificationRepo] redeemReward error: $msg');
      return RedeemResult.error(msg);
    } catch (e) {
      print('[GamificationRepo] redeemReward error: $e');
    }
    return RedeemResult.error('Unknown error');
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final res = await _dio.get('/gamification/leaderboard');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final list = res.data['leaderboard'] as List<dynamic>? ?? [];
        return list
            .map((e) =>
                LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[GamificationRepo] getLeaderboard error: $e');
    }
    return [];
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GamificationRepository(dio);
});
