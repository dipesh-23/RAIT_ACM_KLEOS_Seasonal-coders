import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';
import 'confirmation_screen.dart';
import 'voice_screen.dart';
import 'result_screen.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  bool _wasAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final text = provider.transcribedText;
    final lang = provider.selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            // ── Header ──
            Container(
              color: AppTheme.bgWhite,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.menu_rounded, color: AppTheme.textDark, size: 26),
                  const SizedBox(width: 12),
                  Expanded(child: Text(AppStrings.get('asha_triage', lang),
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark))),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subtitle ──
                    Text(AppStrings.get('heard_label', lang),
                        style: GoogleFonts.poppins(
                            color: AppTheme.textMedium, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(AppStrings.get('check_patient_options', lang),
                        style: GoogleFonts.poppins(
                            color: AppTheme.textLight, fontSize: 12)),

                    const SizedBox(height: 20),

                    // ── Transcription Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.15),
                            width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.mic_rounded,
                                    color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(AppStrings.get('audio_transcription', lang),
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.primary, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 1, color: AppTheme.divider,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            text.isEmpty
                                ? '"मरीज को तीन दिन से तेज बुखार है। उन्हें खांसी भी आ रही है और मांस लेने में कुछ तकलीफ महसूस हो रही है..."'
                                : '"$text"',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textDark, fontSize: 15,
                                height: 1.6, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Detected Symptoms ──
                    Text(AppStrings.get('detected_symptoms', lang),
                        style: GoogleFonts.poppins(
                            color: AppTheme.textDark, fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _symptomChip('बुखार', AppTheme.triageYellow),
                        _symptomChip('खांसी', AppTheme.triageYellow),
                        _symptomChip('सांस में तकलीफ', AppTheme.triageRed),
                        _symptomChip('3 दिन से लक्षण', AppTheme.textLight),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Confidence Indicator ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.get('ai_confidence_score', lang),
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textDark, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text('82%',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.primary, fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: 0.82,
                              minHeight: 8,
                              backgroundColor: AppTheme.borderColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Question ──
                    Center(
                      child: Text(AppStrings.get('is_this_correct', lang),
                          style: GoogleFonts.poppins(
                              color: AppTheme.textDark, fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 16),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                                    builder: (_) => const VoiceScreen())),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(AppStrings.get('rerecord', lang),
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<TriageProvider>().setTranscript(text);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(AppStrings.get('correct_continue', lang),
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Consumer<TriageProvider>(
        builder: (context, provider, child) {
          if (provider.isAnalyzing) {
            _wasAnalyzing = true;
            return Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 20),
                    Text('विश्लेषण हो रहा है',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          } else if (_wasAnalyzing) {
            _wasAnalyzing = false;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (provider.detectedConcepts.isEmpty) {
                await provider.scoreAndNavigate();
                if (mounted) {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResultScreen()));
                }
              } else {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConfirmationScreen()));
              }
            });
          }
          return const SizedBox.shrink();
        },
      ),
      ],
      ),
    );
  }

  Widget _symptomChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: GoogleFonts.poppins(
          color: color == AppTheme.textLight ? AppTheme.textMedium : color,
          fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
