import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../app_theme.dart';
import '../models/triage_result.dart';
import '../providers/triage_provider.dart';
import '../services/tts_service.dart';
import '../utils/app_strings.dart';
import 'referral_screen.dart';
import 'session_start_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    _scaleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    // Auto-play TTS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TriageProvider>();
      final result = provider.currentResult;
      final lang = provider.selectedLanguage;
      if (result != null) TtsService.instance.playTriageResult(result.category, lang);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scaleCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(TriageCategory cat) {
    switch (cat) {
      case TriageCategory.red:    return AppTheme.triageRed;
      case TriageCategory.yellow: return AppTheme.triageYellow;
      case TriageCategory.green:  return AppTheme.triageGreen;
    }
  }

  Gradient _categoryGradient(TriageCategory cat) {
    switch (cat) {
      case TriageCategory.red:    return AppTheme.redGradient;
      case TriageCategory.yellow: return const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)]);
      case TriageCategory.green:  return AppTheme.greenGradient;
    }
  }

  IconData _categoryIcon(TriageCategory cat) {
    switch (cat) {
      case TriageCategory.red:    return Icons.emergency_rounded;
      case TriageCategory.yellow: return Icons.warning_amber_rounded;
      case TriageCategory.green:  return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final result = provider.currentResult;
    if (result == null) return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );

    final cat = result.category;
    final color = _categoryColor(cat);
    final gradient = _categoryGradient(cat);
    final lang = provider.selectedLanguage;

    final confirmedConcepts = provider.detectedConcepts.where((c) => c.confirmed).toList();
    bool manuallyConfirmed = confirmedConcepts.any((c) => c.requiresConfirmation) || 
                             result.matchedSymptoms.contains('मरीज की हालत गंभीर (Worker Flagged)');
                             
    String? detectionSubtitle;
    if (cat == TriageCategory.red) {
      if (!manuallyConfirmed) {
        detectionSubtitle = 'एआई द्वारा स्वतः पहचाना गया';
      } else {
        detectionSubtitle = lang == 'mr' ? 'कार्यकर्त्याने पुष्टी केली' : (lang == 'hi' ? 'कार्यकर्ता द्वारा पुष्टि की गई' : 'Confirmed by worker');
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Result Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
              decoration: BoxDecoration(gradient: gradient),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_categoryIcon(cat),
                          color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(result.categoryLabelForLang(lang),
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  if (detectionSubtitle != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(!manuallyConfirmed ? Icons.auto_awesome_rounded : Icons.verified_user_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(detectionSubtitle,
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(result.getRecommendationForLang(lang),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9), fontSize: 14,
                          fontWeight: FontWeight.w500, height: 1.5)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── What Was Said ──
                    AppTheme.sectionTitle(AppStrings.get('transcription_title', lang)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Text('"${result.transcribedText}"',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textDark, fontSize: 14,
                              fontStyle: FontStyle.italic, height: 1.5)),
                    ),

                    const SizedBox(height: 20),

                    // ── Matched Symptoms ──
                    AppTheme.sectionTitle(AppStrings.get('detected_symptoms', lang)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: result.matchedSymptoms.map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.35)),
                        ),
                        child: Text(s, style: GoogleFonts.poppins(
                            color: color, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Recommendation Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_rounded,
                              color: color, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.get('asha_advice', lang),
                                    style: GoogleFonts.poppins(
                                        color: color, fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(result.getRecommendationForLang(lang),
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textDark, fontSize: 13,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── TTS Replay ──
                    OutlinedButton.icon(
                      onPressed: () =>
                          TtsService.instance.playTriageResult(cat, lang),
                      icon: Icon(Icons.volume_up_rounded,
                          color: AppTheme.primary, size: 20),
                      label: Text(AppStrings.get('listen_audio', lang),
                          style: GoogleFonts.poppins(
                              color: AppTheme.primary, fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    if (cat == TriageCategory.yellow && !result.requiresReferral) ...[
                      const SizedBox(height: 12),
                      AppTheme.gradientButton(
                        label: lang == 'hi' ? 'गंभीर स्थिति घोषित करें (Escalate)' : 'Escalate to Emergency (RED)',
                        onTap: () => context.read<TriageProvider>().escalateToRed(),
                        gradient: AppTheme.redGradient,
                        icon: Icons.emergency_share_rounded,
                      ),
                    ],

                    if (result.requiresReferral || cat == TriageCategory.green) ...[
                      const SizedBox(height: 12),
                      AppTheme.gradientButton(
                        label: cat == TriageCategory.green 
                            ? (lang == 'hi' ? 'घरेलू उपचार सलाह स्लिप' : 'Home Care Advice Slip') 
                            : AppStrings.get('create_referral_slip', lang),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ReferralScreen())),
                        gradient: cat == TriageCategory.green ? AppTheme.greenGradient : AppTheme.redGradient,
                        icon: cat == TriageCategory.green ? Icons.home_rounded : Icons.local_hospital_rounded,
                      ),
                    ],

                    const SizedBox(height: 12),

                    AppTheme.gradientButton(
                      label: AppStrings.get('new_patient', lang),
                      onTap: () {
                        context.read<TriageProvider>().reset();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const SessionStartScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
