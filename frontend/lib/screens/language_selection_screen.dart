import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/triage_provider.dart';
import '../app_theme.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Welcome to ASHA Triage",
                style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Please select your preferred language\nकृपया अपनी भाषा चुनें",
                style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              if (context.watch<TriageProvider>().initError != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    context.watch<TriageProvider>().initError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!context.watch<TriageProvider>().servicesReady)
                const Center(child: CircularProgressIndicator())
              else ...[
                _LanguageCard(
                  languageName: "हिंदी",
                  englishName: "Hindi",
                  langCode: "hi",
                  onTap: () => _selectLanguage(context, "hi"),
                ),
                const SizedBox(height: 16),
                
                _LanguageCard(
                  languageName: "मराठी",
                  englishName: "Marathi",
                  langCode: "mr",
                  onTap: () => _selectLanguage(context, "mr"),
                ),
                const SizedBox(height: 16),

                _LanguageCard(
                  languageName: "English",
                  englishName: "English",
                  langCode: "en",
                  onTap: () => _selectLanguage(context, "en"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String langCode) {
    context.read<TriageProvider>().setLanguage(langCode);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String languageName;
  final String englishName;
  final String langCode;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.languageName,
    required this.englishName,
    required this.langCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageName,
                  style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (languageName != englishName)
                  Text(
                    englishName,
                    style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 14),
                  ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
