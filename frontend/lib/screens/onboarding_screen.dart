import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/onboarding_service.dart';
import 'session_start_screen.dart';

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
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _proceed() async {
    await OnboardingService.instance.completeOnboarding('ASHA कार्यकर्ता');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SessionStartScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
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
                    Text('ASHA ट्राइएज',
                        style: GoogleFonts.poppins(
                            fontSize: 32, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    Text('ऑफलाइन स्वास्थ्य सहायक',
                        style: GoogleFonts.poppins(
                            fontSize: 15, color: AppTheme.textMedium,
                            fontWeight: FontWeight.w500)),

                    const SizedBox(height: 40),

                    // ── Illustration ──
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEDE9FF), Color(0xFFD5CDFF)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background pattern circles
                          Positioned(
                            top: -20, right: -20,
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30, left: -20,
                            child: Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // ASHA Worker Icon
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 90, height: 90,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_rounded,
                                    size: 56, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('ASHA कार्यकर्ता',
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Feature Chips ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _featureChip(Icons.wifi_off_rounded, 'पूर्ण ऑफलाइन'),
                        _featureChip(Icons.mic_rounded, 'आवाज में दर्ज करें'),
                        _featureChip(Icons.translate_rounded, 'हिंदी'),
                      ],
                    ),

                    const Spacer(),

                    // ── CTA Button ──
                    AppTheme.gradientButton(
                      label: 'हिंदी भाषा सेटअप करें',
                      onTap: _proceed,
                      icon: Icons.language_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, size: 14,
                            color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Text('डेटा गुप्त और अनामांकित',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textLight, fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 10, color: AppTheme.textMedium,
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
