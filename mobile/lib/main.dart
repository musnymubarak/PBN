import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/theme/app_theme.dart';
import 'package:pbn/core/providers/auth_provider.dart';
import 'package:pbn/core/providers/notification_provider.dart';
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

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const PBNApp(),
    ),
  );
}

class PBNApp extends StatelessWidget {
  const PBNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prime Business Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        '/my-referrals': (context) => const MyReferralsPage(),
        '/events': (context) => const EventsPage(),
        '/rewards': (context) => const RewardsPage(),
        '/payments': (context) => const PaymentsPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/chapters': (context) => const ChaptersPage(),
        '/apply': (context) => const ApplyPage(),
        '/my-applications': (context) => const MyApplicationsPage(),
        '/partner_dashboard': (context) => const PartnerDashboardPage(),
      },
    );
  }
}
