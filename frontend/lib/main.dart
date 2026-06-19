import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/triage_provider.dart';
import 'services/onboarding_service.dart';
import 'services/database_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/session_start_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pregnancy_tracker_screen.dart';
import 'screens/followup_tracker_screen.dart';
import 'screens/qr_sync_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init services
  await OnboardingService.instance.init();
  await DatabaseService.instance.database;

  runApp(const AshaTriageApp());
}

class AshaTriageApp extends StatelessWidget {
  const AshaTriageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TriageProvider()),
      ],
      child: MaterialApp(
        title: 'ASHA ट्राइएज',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: OnboardingService.instance.isOnboardingDone
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SessionStartScreen(),
    DashboardScreen(),
    PregnancyTrackerScreen(),
    FollowupTrackerScreen(),
    QrSyncScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Triage'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pregnant_woman), label: 'Pregnancy'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Follow-up'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Sync'),
        ],
      ),
    );
  }
}
