import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/triage_provider.dart';
import 'services/onboarding_service.dart';
import 'services/database_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/session_start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Fast blocking inits only (lightweight — no model loading)
  await OnboardingService.instance.init();
  await DatabaseService.instance.database;

  // EmbeddingService + TriageEngine are initialised lazily in TriageProvider
  // after runApp so the first frame is not blocked by model loading.
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
        home: const _AppBootstrap(),
      ),
    );
  }
}

/// Drives model initialisation after the first frame and shows a full-screen
/// Hindi loading splash until [TriageProvider.servicesReady] flips to true.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Pulsing animation for the loading dots
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Kick off background model loading after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TriageProvider>().initializeServices();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _resolveHome() {
    final svc = OnboardingService.instance;
    if (!svc.isOnboardingDone) return const OnboardingScreen();
    return const SessionStartScreen();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<TriageProvider, bool>((p) => p.servicesReady);

    if (ready) return _resolveHome();

    // ── Full-screen loading splash ───────────────────────────────────────────
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo / icon placeholder
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                ),
                child: const Icon(Icons.health_and_safety_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                'ASHA ट्राइएज',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'आशा कार्यकर्ता सहायक प्रणाली',
                style: GoogleFonts.poppins(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 56),
              // Pulsing dots loader
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final delay = i / 3;
                      final opacity = (((_pulse.value + delay) % 1.0));
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((opacity * 255).round()),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'लोड हो रहा है…',
                style: GoogleFonts.poppins(
                  color: Colors.white.withAlpha(220),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI मॉडल तैयार किया जा रहा है',
                style: GoogleFonts.poppins(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
