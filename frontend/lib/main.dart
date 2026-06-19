import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'providers/triage_provider.dart';
import 'services/onboarding_service.dart';
import 'services/database_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/session_start_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/epidemic_alert_screen.dart';
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
        home: _resolveHome(),
      ),
    );
  }

  Widget _resolveHome() {
    final svc = OnboardingService.instance;
    if (!svc.isOnboardingDone) return const OnboardingScreen();
    return const HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Default to Triage Home

  final List<Widget> _screens = const [
    SessionStartScreen(),
    DashboardScreen(),
    PregnancyTrackerScreen(),
    FollowupTrackerScreen(),
    QrSyncScreen(),
  ];

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TriageProvider>(context);
    final lang = provider.selectedLanguage;

    return Drawer(
      backgroundColor: AppTheme.bgPage,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Text(
                lang == 'hi' ? 'ASHA ट्राइएज' : 'ASHA Triage',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.local_hospital_rounded,
                  title: lang == 'hi' ? '🏥 ट्राइएज' : '🏥 Triage',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: lang == 'hi' ? '📊 डैशबोर्ड' : '📊 Dashboard',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.pregnant_woman_rounded,
                  title: lang == 'hi' ? '🤰 गर्भावस्था' : '🤰 Pregnancy',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.follow_the_signs_rounded,
                  title: lang == 'hi' ? '📋 फॉलो-अप' : '📋 Follow-up',
                  index: 3,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.sync_rounded,
                  title: lang == 'hi' ? '📱 QR सिंक' : '📱 QR Sync',
                  index: 4,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'hi' ? 'भाषा चुनें / Select Language' : 'Select Language / भाषा चुनें',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setLanguage('hi'),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: lang == 'hi' ? AppTheme.primaryGradient : null,
                            color: lang == 'hi' ? null : AppTheme.bgPage,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: lang == 'hi' ? Colors.transparent : AppTheme.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'हिंदी (Hindi)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: lang == 'hi' ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setLanguage('en'),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: lang == 'en' ? AppTheme.primaryGradient : null,
                            color: lang == 'en' ? null : AppTheme.bgPage,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: lang == 'en' ? Colors.transparent : AppTheme.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'English',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: lang == 'en' ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final isSelected = homeState?._currentIndex == index;

    return Container(
      height: 72,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primary : AppTheme.textDark,
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppTheme.primary : AppTheme.textDark,
            fontSize: 15,
          ),
        ),
        onTap: () {
          if (homeState != null) {
            homeState.setIndex(index);
          }
          Navigator.pop(context); // Close drawer
        },
      ),
    );
  }
}
