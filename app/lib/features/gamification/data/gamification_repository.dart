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

  WalletData copyWith({
    int? points,
    int? streakDays,
    List<PointHistoryEntry>? history,
  }) =>
      WalletData(
        points: points ?? this.points,
        streakDays: streakDays ?? this.streakDays,
        history: history ?? this.history,
      );
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

  BadgesResult copyWith({
    List<BadgeData>? badges,
    List<String>? newlyEarned,
  }) =>
      BadgesResult(
        badges: badges ?? this.badges,
        newlyEarned: newlyEarned ?? this.newlyEarned,
      );
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

  RewardsResult copyWith({
    List<RewardItem>? rewards,
    int? userPoints,
  }) =>
      RewardsResult(
        rewards: rewards ?? this.rewards,
        userPoints: userPoints ?? this.userPoints,
      );
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
        success: json['success'] == true ||
            json['message'] == 'Redeemed' ||
            json['status'] == 'success',
        rewardName: json['rewardName'] as String? ?? json['name'] as String? ?? 'Reward',
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

  static const List<BadgeData> defaultBadges = [
    BadgeData(
      id: 'eco_starter',
      emoji: '🌱',
      name: 'Eco Starter',
      description: 'Logged first zero-emission commute',
      earned: false,
    ),
    BadgeData(
      id: 'streak_7',
      emoji: '🔥',
      name: '7-Day Streak',
      description: 'Completed all habits for 7 days straight',
      earned: false,
    ),
    BadgeData(
      id: 'metro_hero',
      emoji: '🚇',
      name: 'Metro Hero',
      description: 'Used metro 10 times',
      earned: false,
    ),
    BadgeData(
      id: 'green_eater',
      emoji: '🥗',
      name: 'Green Eater',
      description: 'Logged 5 vegetarian days',
      earned: false,
    ),
    BadgeData(
      id: 'sleep_champion',
      emoji: '😴',
      name: 'Sleep Champion',
      description: 'Slept 8h for 5 consecutive days',
      earned: false,
    ),
    BadgeData(
      id: 'carbon_cutter',
      emoji: '🌍',
      name: 'Carbon Cutter',
      description: 'Cut CO₂ below 2 kg for 3 days',
      earned: false,
    ),
    BadgeData(
      id: 'eco_legend',
      emoji: '🏆',
      name: 'Eco Legend',
      description: 'Earn 5,000 EcoPoints',
      earned: false,
    ),
  ];

  static const List<RewardItem> defaultRewards = [
    RewardItem(
      id: 'streak_freeze',
      emoji: '🧊',
      name: 'Streak Freeze Pass',
      description: 'Protect your streak if you miss logging for one day',
      cost: 100,
      perkType: 'streak_freeze',
      canAfford: false,
      alreadyRedeemed: false,
      available: true,
    ),
    RewardItem(
      id: 'theme_emerald',
      emoji: '🎨',
      name: 'Emerald Dark Theme',
      description: 'Unlock exclusive emerald & forest-green app aesthetic',
      cost: 200,
      perkType: 'theme',
      canAfford: false,
      alreadyRedeemed: false,
      available: true,
    ),
    RewardItem(
      id: 'skip_pass',
      emoji: '⏩',
      name: 'Daily Skip Pass',
      description: 'Mark one habit as completed without penalty',
      cost: 150,
      perkType: 'skip_pass',
      canAfford: false,
      alreadyRedeemed: false,
      available: true,
    ),
    RewardItem(
      id: 'badge_frame_gold',
      emoji: '⭐',
      name: 'Champion Badge Frame',
      description: 'Premium badge frame for your profile',
      cost: 500,
      perkType: 'badge_frame',
      canAfford: false,
      alreadyRedeemed: false,
      available: true,
    ),
  ];

  static List<PointHistoryEntry> generateSyntheticHistory(
      int totalPoints, int streakDays) {
    if (totalPoints <= 0) return [];
    final List<PointHistoryEntry> history = [];
    final now = DateTime.now();

    final templates = [
      (label: 'Daily habit checklist completed', amount: 50, type: 'habit'),
      (label: 'Streak milestone bonus', amount: 50, type: 'streak'),
      (label: 'Low carbon commute logged', amount: 20, type: 'carbon'),
      (label: 'Daily exercise goal (30 min)', amount: 15, type: 'habit'),
      (label: 'Optimal sleep logged (7.5h)', amount: 10, type: 'habit'),
      (label: 'Healthy plant-forward meal', amount: 10, type: 'habit'),
      (label: 'Hydration goal achieved', amount: 10, type: 'habit'),
      (label: 'Balanced screen time (<4h)', amount: 10, type: 'habit'),
    ];

    int currentBalance = totalPoints;
    int templateIndex = 0;
    int dayOffset = 0;

    while (currentBalance > 0 && history.length < 20) {
      final t = templates[templateIndex % templates.length];
      final amount = currentBalance >= t.amount ? t.amount : currentBalance;
      final entryDate =
          now.subtract(Duration(hours: dayOffset * 8 + (templateIndex * 2)));

      history.add(PointHistoryEntry(
        id: 'synth_${history.length}_$dayOffset',
        label: t.label,
        amount: amount,
        balance: currentBalance,
        type: t.type,
        date: entryDate,
      ));

      currentBalance -= amount;
      templateIndex++;
      if (templateIndex % 3 == 0) {
        dayOffset++;
      }
    }

    return history;
  }

  Future<WalletData> getWallet(
      {int currentPoints = 0, int streakDays = 0}) async {
    try {
      final res = await _dio.get('/gamification/wallet');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final parsed = WalletData.fromJson(res.data as Map<String, dynamic>);
        final finalPoints =
            parsed.points > 0 ? parsed.points : currentPoints;
        final finalStreak =
            parsed.streakDays > 0 ? parsed.streakDays : streakDays;
        List<PointHistoryEntry> history = parsed.history;

        if (history.isEmpty && finalPoints > 0) {
          history = generateSyntheticHistory(finalPoints, finalStreak);
        }

        return WalletData(
          points: finalPoints,
          streakDays: finalStreak,
          history: history,
        );
      }
    } catch (e) {
      print('[GamificationRepo] getWallet error: $e');
    }
    return WalletData(
      points: currentPoints,
      streakDays: streakDays,
      history: currentPoints > 0
          ? generateSyntheticHistory(currentPoints, streakDays)
          : [],
    );
  }

  Future<BadgesResult> getBadges({List<String>? userBadgeIds}) async {
    try {
      final res = await _dio.get('/gamification/badges');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final parsed =
            BadgesResult.fromJson(res.data as Map<String, dynamic>);
        if (parsed.badges.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      print('[GamificationRepo] getBadges error: $e');
    }

    // Fallback: Use standard badge catalogue and mark user-earned badges
    final earnedIds = userBadgeIds ?? [];
    final fallbackBadges = defaultBadges.map((b) {
      final isEarned = earnedIds.contains(b.id);
      return BadgeData(
        id: b.id,
        emoji: b.emoji,
        name: b.name,
        description: b.description,
        earned: isEarned,
      );
    }).toList();

    return BadgesResult(badges: fallbackBadges, newlyEarned: []);
  }

  Future<RewardsResult> getRewards({int currentPoints = 0}) async {
    try {
      final res = await _dio.get('/gamification/rewards');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final parsed =
            RewardsResult.fromJson(res.data as Map<String, dynamic>);
        if (parsed.rewards.isNotEmpty) {
          final effectivePoints =
              parsed.userPoints > 0 ? parsed.userPoints : currentPoints;
          return parsed.copyWith(
            userPoints: effectivePoints,
            rewards: parsed.rewards
                .map((r) => RewardItem(
                      id: r.id,
                      emoji: r.emoji,
                      name: r.name,
                      description: r.description,
                      cost: r.cost,
                      perkType: r.perkType,
                      canAfford: effectivePoints >= r.cost,
                      alreadyRedeemed: r.alreadyRedeemed,
                      available: r.available,
                    ))
                .toList(),
          );
        }
      }
    } catch (e) {
      print('[GamificationRepo] getRewards error: $e');
    }

    // Fallback catalogue
    final fallbackRewards = defaultRewards
        .map((r) => RewardItem(
              id: r.id,
              emoji: r.emoji,
              name: r.name,
              description: r.description,
              cost: r.cost,
              perkType: r.perkType,
              canAfford: currentPoints >= r.cost,
              alreadyRedeemed: false,
              available: true,
            ))
        .toList();

    return RewardsResult(rewards: fallbackRewards, userPoints: currentPoints);
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
      final msg = e.response?.data?['error']?.toString() ??
          e.message ??
          'Redeem failed';
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
