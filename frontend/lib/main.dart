import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/triage_provider.dart';
import 'services/database_service.dart';
import 'services/embedding_service.dart';
import 'services/triage_engine.dart';
import 'services/tts_service.dart';
import 'services/onboarding_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/session_start_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/transcription_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/result_screen.dart';
import 'screens/referral_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services sequentially
  await DatabaseService.instance.initDatabase();
  await EmbeddingService.instance.initialize();
  await TriageEngine.instance.initialize();
  await TtsService.instance.initialize();

  // Determine initial route
  final onboarding = OnboardingService();
  final onboardingComplete = await onboarding.isOnboardingComplete();
  final initialRoute = onboardingComplete ? '/session-start' : '/onboarding';

  runApp(AshaTriageApp(initialRoute: initialRoute));
}

class AshaTriageApp extends StatelessWidget {
  final String initialRoute;

  const AshaTriageApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TriageProvider()),
      ],
      child: MaterialApp(
        title: 'ASHA ट्राइएज',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        initialRoute: initialRoute,
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/session-start': (_) => const SessionStartScreen(),
          '/voice': (_) => const VoiceScreen(),
          '/transcription': (_) => const TranscriptionScreen(),
          '/confirmation': (_) => const ConfirmationScreen(),
          '/result': (_) => const ResultScreen(),
          '/referral': (_) => const ReferralScreen(),
        },
      ),
    );
  }
}
