import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/gamification_repository.dart';
import '../providers/gamification_provider.dart';

/// Gamification / Rewards screen — points wallet, badges, and redemption.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Rewards',
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.darkText)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accentAmber,
          labelColor: AppTheme.accentAmber,
          unselectedLabelColor: AppTheme.darkTextMuted,
          tabs: const [
            Tab(text: 'Wallet'),
            Tab(text: 'Badges'),
            Tab(text: 'Redeem'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _WalletTab(),
          _BadgesTab(),
          _RedeemTab(),
        ],
      ),
    );
  }
}

// ── Wallet Tab ───────────────────────────────────────────────────────────────

class _WalletTab extends ConsumerWidget {
  const _WalletTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(walletProvider);

    return walletAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentAmber),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load wallet',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.darkTextMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(walletProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (wallet) => RefreshIndicator(
        color: AppTheme.accentAmber,
        onRefresh: () => ref.read(walletProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Points balance hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentAmber.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '${wallet.points}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'EcoPoints',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    if (wallet.streakDays > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 ${wallet.streakDays} day streak',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Point History',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: AppTheme.darkText)),
              ),
              const SizedBox(height: 12),

              if (wallet.history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded,
                          color: AppTheme.darkTextMuted, size: 40),
                      const SizedBox(height: 12),
                      Text('No activity yet',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.darkTextMuted)),
                      const SizedBox(height: 4),
                      Text('Start logging habits to earn EcoPoints!',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.darkTextMuted)),
                    ],
                  ),
                )
              else
                ...wallet.history.asMap().entries.map((e) {
                  final entry = e.value;
                  final isPositive = entry.amount >= 0;
                  final sign = isPositive ? '+' : '';
                  final dateStr = DateFormat('dd MMM, HH:mm').format(entry.date.toLocal());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          // Type icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isPositive
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconForType(entry.type, isPositive),
                              color: isPositive
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.label,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.darkText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(dateStr,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: AppTheme.darkTextMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sign${entry.amount}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isPositive
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Bal: ${entry.balance}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.darkTextMuted,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: e.key * 60))
                      .fadeIn()
                      .slideX(begin: 0.05);
                }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type, bool isPositive) {
    if (!isPositive) return Icons.redeem_rounded;
    switch (type) {
      case 'habit':
        return Icons.check_circle_outline_rounded;
      case 'carbon':
        return Icons.eco_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'badge':
        return Icons.military_tech_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

// ── Badges Tab ───────────────────────────────────────────────────────────────

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final badgesAsync = ref.watch(badgesProvider);

    return badgesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentAmber),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load badges',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.darkTextMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(badgesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (result) {
        final badges = result.badges;

        if (badges.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.military_tech_rounded,
                    color: AppTheme.darkTextMuted, size: 56),
                const SizedBox(height: 12),
                Text('No badges available',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.darkTextMuted)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.accentAmber,
          onRefresh: () => ref.read(badgesProvider.notifier).refresh(),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: badges.length,
            itemBuilder: (context, i) {
              final badge = badges[i];
              return GestureDetector(
                onTap: () => _showBadgeDetail(context, badge),
                child: AnimatedOpacity(
                  opacity: badge.earned ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badge.earned
                          ? AppTheme.accentAmber.withOpacity(0.1)
                          : AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: badge.earned
                            ? AppTheme.accentAmber.withOpacity(0.5)
                            : AppTheme.darkBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(badge.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(
                          badge.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (badge.earned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Earned',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.successGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.lock_outline_rounded,
                              color: AppTheme.darkTextMuted, size: 14),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 50))
                      .scale(begin: const Offset(0.8, 0.8)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeData badge) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(badge.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: AppTheme.darkText),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badge.earned
                    ? AppTheme.successGreen.withOpacity(0.1)
                    : AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge.earned
                      ? AppTheme.successGreen.withOpacity(0.3)
                      : AppTheme.errorRed.withOpacity(0.3),
                ),
              ),
              child: Text(
                badge.earned ? '✅ Earned' : '🔒 Locked',
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      badge.earned ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Redeem Tab ───────────────────────────────────────────────────────────────

class _RedeemTab extends ConsumerWidget {
  const _RedeemTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rewardsAsync = ref.watch(rewardsProvider);

    return rewardsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentAmber),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load rewards',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.darkTextMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(rewardsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (result) {
        return RefreshIndicator(
          color: AppTheme.accentAmber,
          onRefresh: () => ref.read(rewardsProvider.notifier).refresh(),
          child: Column(
            children: [
              // User's current points bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppTheme.accentAmber, size: 24),
                    const SizedBox(width: 10),
                    Text('Your Balance:',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.darkTextMuted)),
                    const SizedBox(width: 8),
                    Text(
                      '${result.userPoints} pts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentAmber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Rewards list
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: result.rewards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final reward = result.rewards[i];
                    return _RewardCard(reward: reward);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardCard extends ConsumerStatefulWidget {
  const _RewardCard({required this.reward});
  final RewardItem reward;

  @override
  ConsumerState<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends ConsumerState<_RewardCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reward = widget.reward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppTheme.darkText)),
                Text(reward.description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.darkTextMuted)),
                const SizedBox(height: 4),
                Text('⭐ ${reward.cost} pts',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.accentAmber)),
                if (reward.alreadyRedeemed)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Already owned',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.successGreen, fontSize: 10)),
                  ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentAmber,
                  ),
                )
              : ElevatedButton(
                  onPressed: reward.available ? () => _handleRedeem() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: reward.available
                        ? AppTheme.accentAmber
                        : AppTheme.darkBorder,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle:
                        theme.textTheme.labelLarge?.copyWith(fontSize: 12),
                  ),
                  child: Text(
                    reward.alreadyRedeemed
                        ? 'Owned'
                        : reward.canAfford
                            ? 'Redeem'
                            : 'Locked',
                  ),
                ),
        ],
      ),
    ).animate(delay: const Duration(milliseconds: 70)).fadeIn().slideX(begin: 0.1);
  }

  Future<void> _handleRedeem() async {
    if (_loading) return;
    setState(() => _loading = true);

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Redeem ${widget.reward.name}?',
          style: Theme.of(ctx)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppTheme.darkText),
        ),
        content: Text(
          'This will cost ${widget.reward.cost} EcoPoints.\n${widget.reward.description}',
          style: Theme.of(ctx)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.darkTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.darkTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _loading = false);
      return;
    }

    final result =
        await ref.read(rewardsProvider.notifier).redeem(widget.reward.id);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Redeemed ${result.rewardName}! -${result.pointsSpent} pts',
          ),
          backgroundColor: AppTheme.successGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result.error ?? "Redemption failed"}'),
          backgroundColor: AppTheme.errorRed.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
