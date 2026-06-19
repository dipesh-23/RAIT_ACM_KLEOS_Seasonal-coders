import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/triage_provider.dart';
import '../models/triage_result.dart';
import '../utils/app_strings.dart';
import 'referral_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = context.read<TriageProvider>().currentResult;
      if (result != null) {
        String audioPath = '';
        switch (result.category) {
          case TriageCategory.red:
            audioPath = 'audio/red_hindi.mp3';
            break;
          case TriageCategory.yellow:
            audioPath = 'audio/yellow_hindi.mp3';
            break;
          case TriageCategory.green:
            audioPath = 'audio/green_hindi.mp3';
            break;
        }
        // TODO: Re-enable when mp3 files are no longer 0-byte
        // try {
        //   _audioPlayer.play(AssetSource(audioPath));
        // } catch (e) {
        //   debugPrint('Audio playback failed (possibly 0-byte file): $e');
        // }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final result = provider.currentResult;
    final lang = provider.selectedLanguage;
    final concepts = provider.detectedConcepts.where((c) => c.confirmed).toList();

    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Color bgColor;
    switch (result.category) {
      case TriageCategory.red:
        bgColor = Colors.red.shade800;
        break;
      case TriageCategory.yellow:
        bgColor = Colors.amber.shade700;
        break;
      case TriageCategory.green:
        bgColor = Colors.green.shade700;
        break;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Level Localized
              Text(
                result.levelTitleForLang(lang),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Level Subtitle
              Text(
                result.levelSubtitleForLang(lang),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Dividing line
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              
              const SizedBox(height: 32),
              
              // Confirmed Concepts List
              if (concepts.isEmpty)
                Text(
                  lang == 'en' ? 'No specific symptoms' : (lang == 'mr' ? 'कोणतीही विशिष्ट लक्षणे नाहीत' : 'कोई विशेष लक्षण नहीं'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                )
              else
                ...concepts.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '• ${c.getLabelForLang(lang)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                )),
              
              const Spacer(),
              
              // Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReferralScreen()),
                  );
                },
                child: Text(
                  AppStrings.get('create_referral_slip', lang),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
