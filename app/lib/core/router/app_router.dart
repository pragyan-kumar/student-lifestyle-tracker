import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/habits/presentation/screens/log_habit_screen.dart';
import '../../features/carbon/presentation/screens/carbon_screen.dart';
import '../../features/carbon/presentation/screens/log_carbon_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/gamification/presentation/screens/rewards_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/app_shell.dart';

// ── Route name constants ─────────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const habits = '/habits';
  static const logHabit = '/habits/log';
  static const carbon = '/carbon';
  static const logCarbon = '/carbon/log';
  static const insights = '/insights';
  static const rewards = '/rewards';
  static const profile = '/profile';
}

// ── Riverpod provider for the router ────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so the router refreshes on login/logout.
  final authNotifier = ref.watch(authProvider.notifier);

  // A Listenable that GoRouter can subscribe to for redirects.
  final routerRefreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    refreshListenable: routerRefreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.onboarding ||
          loc == AppRoutes.splash;

      // If user is not logged in and tries to access a protected screen
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If user is logged in and is on auth/splash/onboarding screens
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main shell with bottom navigation ───────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.habits,
            builder: (context, state) => const HabitsScreen(),
            routes: [
              GoRoute(
                path: 'log',
                builder: (context, state) => const LogHabitScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.carbon,
            builder: (context, state) => const CarbonScreen(),
            routes: [
              GoRoute(
                path: 'log',
                builder: (context, state) => const LogCarbonScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.insights,
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: AppRoutes.rewards,
            builder: (context, state) => const RewardsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

/// A [ChangeNotifier] that fires whenever the auth state changes,
/// so GoRouter re-evaluates its redirect logic.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
