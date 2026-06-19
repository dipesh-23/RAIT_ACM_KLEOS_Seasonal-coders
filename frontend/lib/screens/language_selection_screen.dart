import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/triage_provider.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub dark dim
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Welcome to ASHA Triage",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Please select your preferred language\nकृपया अपनी भाषा चुनें",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
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
          color: const Color(0xFF1C2230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageName,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (languageName != englishName)
                  Text(
                    englishName,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
                  ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
