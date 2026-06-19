import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/onboarding_service.dart';
import 'session_start_screen.dart';
import 'package:provider/provider.dart';
import '../providers/triage_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _proceed(String langCode, String langName) async {
    await OnboardingService.instance.completeOnboarding('ASHA Worker', language: langCode);
    if (!mounted) return;
    context.read<TriageProvider>().setLanguage(langCode);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SessionStartScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _langButton(String title, String subtitle, String code, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _proceed(code, title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ── App Badge ──
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: const Icon(Icons.health_and_safety_rounded,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 20),

                    // ── Title ──
                    Text('Welcome Asha Worker',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 30, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    Text('choose language',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: AppTheme.textMedium,
                            fontWeight: FontWeight.w500)),

                    const SizedBox(height: 40),

                    Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _langButton('English', '', 'en', Icons.language),
                              _langButton('Hindi', '', 'hi', Icons.translate),
                              _langButton('Marathi', '', 'mr', Icons.translate),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
