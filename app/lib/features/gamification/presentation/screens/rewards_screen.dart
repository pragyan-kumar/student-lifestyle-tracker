import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

/// Gamification / Rewards screen — points wallet, badges, and redemption.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Rewards', style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.darkText)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accentAmber,
          labelColor: AppTheme.accentAmber,
          unselectedLabelColor: AppTheme.darkTextMuted,
          tabs: const [Tab(text: 'Wallet'), Tab(text: 'Badges'), Tab(text: 'Redeem')],
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
class _WalletTab extends StatelessWidget {
  const _WalletTab();

  static const List<(String, String, String)> _history = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Points balance hero
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
              boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text('0', style: theme.textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                Text('EcoPoints', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),

          Align(alignment: Alignment.centerLeft, child: Text('Point History', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.darkText))),
          const SizedBox(height: 12),

          if (_history.isEmpty)
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
                  Icon(Icons.history_rounded, color: AppTheme.darkTextMuted, size: 40),
                  const SizedBox(height: 12),
                  Text('No activity yet', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextMuted)),
                  const SizedBox(height: 4),
                  Text('Start logging habits to earn EcoPoints!', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                ],
              ),
            )
          else
            ..._history.asMap().entries.map((e) {
              final (label, pts, date) = e.value;
              final isPositive = pts.startsWith('+');
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkText))),
                      Text(pts, style: theme.textTheme.bodyMedium?.copyWith(color: isPositive ? AppTheme.successGreen : AppTheme.errorRed, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Text(date, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: 0.05);
            }),
        ],
      ),
    );
  }
}

// ── Badges Tab ───────────────────────────────────────────────────────────────
class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  static const _badges = [
    ('🌱', 'Eco Starter',    'Logged first zero-emission commute',       false),
    ('🔥', '7-Day Streak',   'Completed all habits for 7 days straight', false),
    ('🚇', 'Metro Hero',     'Used metro 10 times',                      false),
    ('🥗', 'Green Eater',    'Logged 5 vegetarian days',                 false),
    ('😴', 'Sleep Champion', 'Slept 8h for 5 consecutive days',          false),
    ('🌍', 'Carbon Cutter',  'Cut CO₂ below 2 kg for 3 days',            false),
    ('🏆', 'Eco Legend',     'Earn 5,000 EcoPoints',                     false),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: _badges.length,
      itemBuilder: (context, i) {
        final (emoji, name, desc, earned) = _badges[i];
        return AnimatedOpacity(
          opacity: earned ? 1.0 : 0.35,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: earned ? AppTheme.accentAmber.withOpacity(0.1) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: earned ? AppTheme.accentAmber.withOpacity(0.5) : AppTheme.darkBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkText, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 50)).scale(begin: const Offset(0.8, 0.8)),
        );
      },
    );
  }
}

// ── Redeem Tab ───────────────────────────────────────────────────────────────
class _RedeemTab extends StatelessWidget {
  const _RedeemTab();

  static const _rewards = [
    ('❄️', 'Streak Freeze',   'Skip one day without losing your streak',  30,  false),
    ('🎨', 'Dark Neon Theme', 'Unlock an exclusive neon app theme',        200, false),
    ('⏭️', 'Skip-a-Habit',    'Skip one logged task for the day',          50,  false),
    ('🌟', 'Gold Badge Frame','Premium badge frame for your profile',      500, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const userPoints = 0;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final (emoji, name, desc, cost, canAfford) = _rewards[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.darkText)),
                    Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkTextMuted)),
                    const SizedBox(height: 4),
                    Text('⭐ $cost pts', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.accentAmber)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canAfford ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? AppTheme.accentAmber : AppTheme.darkBorder,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
                ),
                child: Text(canAfford ? 'Redeem' : 'Locked'),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: i * 70)).fadeIn().slideX(begin: 0.1);
      },
    );
  }
}
