import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/triage_provider.dart';
import 'services/onboarding_service.dart';
import 'services/database_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/session_start_screen.dart';
import 'screens/language_selection_screen.dart';

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
    if (!svc.isOnboardingDone) return const LanguageSelectionScreen();
    return const SessionStartScreen();
  }
}
