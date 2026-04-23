import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/theme/app_theme.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/providers/member_provider.dart';
import 'package:pbn/core/providers/sync_provider.dart';
import 'package:pbn/features/auth/login_page.dart';
import 'package:pbn/features/auth/splash_page.dart';
import 'package:pbn/features/dashboard/dashboard_page.dart';
import 'package:pbn/features/profile/profile_page.dart';
import 'package:pbn/features/referrals/my_referrals_page.dart';
import 'package:pbn/features/events/events_page.dart';
import 'package:pbn/features/rewards/rewards_page.dart';
import 'package:pbn/features/payments/payments_page.dart';
import 'package:pbn/features/notifications/notifications_page.dart';
import 'package:pbn/features/leaderboard/leaderboard_page.dart';
import 'package:pbn/features/chapters/chapters_page.dart';
import 'package:pbn/features/applications/apply_page.dart';
import 'package:pbn/features/applications/my_applications_page.dart';
import 'package:pbn/features/partner/partner_dashboard_page.dart';
import 'package:pbn/features/auth/onboarding_page.dart';
import 'package:pbn/features/auth/force_change_password_page.dart';
import 'package:pbn/features/auth/forgot_password_page.dart';
import 'package:pbn/features/notifications/notification_settings_page.dart';
import 'package:pbn/core/services/push_notification_service.dart';
import 'package:pbn/core/services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Push Notifications
  try {
    await PushNotificationService.initialize(navigatorKey: PBNApp.navigatorKey)
        .timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint("Firebase/Push initialization timed out - continuing without push");
    });
  } catch (e) {
    debugPrint("Firebase/Push initialization failed: $e");
  }
  
  try {
    await PrefsService.init();
  } catch (e) {
    debugPrint("PrefsService initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const PBNApp(),
    ),
  );
}

class PBNApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const PBNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Prime Business Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const AuthGuard(child: DashboardPage()),
        '/profile': (context) => const AuthGuard(child: ProfilePage()),
        '/events': (context) => const AuthGuard(child: EventsPage()),
        '/rewards': (context) => const AuthGuard(child: RewardsPage()),
        '/payments': (context) => const AuthGuard(child: PaymentsPage()),
        '/notifications': (context) => const AuthGuard(child: NotificationsPage()),
        '/leaderboard': (context) => const AuthGuard(child: LeaderboardPage()),
        '/chapters': (context) => const AuthGuard(child: ChaptersPage()),
        '/apply': (context) => const ApplyPage(),
        '/my-referrals': (context) => const AuthGuard(child: MyReferralsPage(isReceived: true)),
        '/my-applications': (context) => const AuthGuard(child: MyApplicationsPage()),
        '/partner_dashboard': (context) => const AuthGuard(child: PartnerDashboardPage()),
        '/force-change-password': (context) => const ForceChangePasswordPage(),
        '/notification-settings': (context) => const AuthGuard(child: NotificationSettingsPage()),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.status == AuthStatus.unknown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/splash');
      });
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }
    
    if (auth.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    if (auth.user?.mustChangePassword == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/force-change-password');
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    return child;
  }
}
