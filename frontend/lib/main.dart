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
import 'services/embedding_service.dart';
import 'services/triage_engine.dart';

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

  final triageProvider = TriageProvider();

  Future.microtask(() async {
    try {
      await EmbeddingService.instance.initialize();
      await TriageEngine.instance.initialize();
      triageProvider.servicesReady = true;
    } catch (e) {
      triageProvider.setInitError(e.toString());
      print('INIT ERROR: $e');
    }
  });

  runApp(AshaTriageApp(triageProvider: triageProvider));
}

class AshaTriageApp extends StatelessWidget {
  final TriageProvider triageProvider;
  const AshaTriageApp({super.key, required this.triageProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: triageProvider),
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
    // Always start with Language Selection for testing
    return const LanguageSelectionScreen();
  }
}
