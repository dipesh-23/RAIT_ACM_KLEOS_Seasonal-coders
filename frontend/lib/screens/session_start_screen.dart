import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/session_model.dart';
import '../providers/triage_provider.dart';
import '../services/onboarding_service.dart';
import '../utils/app_strings.dart';
import 'voice_screen.dart';

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  final _nameController = TextEditingController();
  AgeGroup? _selectedAge;
  SymptomDuration? _selectedDuration;

  final String workerName = OnboardingService.instance.workerName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startSession(BuildContext context) {
    final lang = context.read<TriageProvider>().selectedLanguage;
    if (_selectedAge == null || _selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('fill_all_options', lang),
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final session = SessionModel(
      ashaWorkerName: _nameController.text.isNotEmpty
          ? _nameController.text
          : workerName,
      patientAgeGroup: _selectedAge,
      symptomDuration: _selectedDuration,
    );

    context.read<TriageProvider>().startSession(session);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const VoiceScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.get('hello', lang), style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 14)),
                          Text(AppStrings.get('asha_worker', lang), style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(AppStrings.get('new_patient_triage', lang),
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Worker Name ──
                    _sectionLabel(AppStrings.get('worker_name_label', lang)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppStrings.get('worker_name_hint', lang),
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Age Group ──
                    _sectionLabel(AppStrings.get('patient_age_label', lang)),
                    const SizedBox(height: 10),
                    _buildAgeChips(lang),

                    const SizedBox(height: 22),

                    // ── Symptom Duration ──
                    _sectionLabel(AppStrings.get('symptom_duration_label', lang)),
                    const SizedBox(height: 10),
                    _buildDurationChips(lang),

                    const SizedBox(height: 28),

                    // ── Recent Stats Row ──
                    _buildStatsRow(lang),

                    const SizedBox(height: 32),

                    // ── Start Button ──
                    AppTheme.gradientButton(
                      label: AppStrings.get('start_btn', lang),
                      onTap: () => _startSession(context),
                      icon: Icons.play_arrow_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return Container(
      color: AppTheme.bgWhite,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.menu_rounded, color: AppTheme.textDark, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppStrings.get('asha_triage', lang),
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: lang,
              underline: const SizedBox(),
              icon: Icon(Icons.language_rounded, color: AppTheme.primary, size: 18),
              style: GoogleFonts.poppins(
                  color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) context.read<TriageProvider>().setLanguage(val);
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(
        color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildAgeChips(String lang) {
    return Wrap(
      spacing: 10,
      children: AgeGroup.values.map((age) {
        final selected = _selectedAge == age;
        return GestureDetector(
          onTap: () => setState(() => _selectedAge = age),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              gradient: selected ? AppTheme.primaryGradient : null,
              color: selected ? null : AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? Colors.transparent : AppTheme.borderColor,
                  width: 1.5),
              boxShadow: selected ? AppTheme.buttonShadow : AppTheme.cardShadow,
            ),
            child: Text(age.labelForLang(lang),
                style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppTheme.textMedium,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationChips(String lang) {
    return Wrap(
      spacing: 10,
      children: SymptomDuration.values.map((dur) {
        final selected = _selectedDuration == dur;
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = dur),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              gradient: selected ? AppTheme.primaryGradient : null,
              color: selected ? null : AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? Colors.transparent : AppTheme.borderColor,
                  width: 1.5),
              boxShadow: selected ? AppTheme.buttonShadow : AppTheme.cardShadow,
            ),
            child: Text(dur.labelForLang(lang),
                style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppTheme.textMedium,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(String lang) {
    return Row(
      children: [
        Expanded(child: _statCard('12', AppStrings.get('today_patients', lang), Icons.people_alt_rounded,
            const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(child: _statCard('3', AppStrings.get('critical_cases', lang), Icons.warning_amber_rounded,
            AppTheme.triageRed)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('9', AppStrings.get('normal_cases', lang), Icons.check_circle_outline_rounded,
            AppTheme.triageGreen)),
      ],
    );
  }

  Widget _statCard(String num, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(num, style: GoogleFonts.poppins(
              color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.poppins(
              color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
