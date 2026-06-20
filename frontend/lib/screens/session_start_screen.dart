import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/session_model.dart';
import '../providers/triage_provider.dart';
import '../services/onboarding_service.dart';
import '../services/database_service.dart';
import '../utils/app_strings.dart';
import 'voice_screen.dart';
import 'profile_screen.dart';

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  final _patientNameController = TextEditingController();
  final _patientContactController = TextEditingController();
  
  String? _selectedGender;
  AgeGroup? _selectedAge;
  SymptomDuration? _selectedDuration;

  Map<String, int> _stats = {};

  final String workerName = OnboardingService.instance.workerName;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseService.instance.getWorkerStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientContactController.dispose();
    super.dispose();
  }

  void _startSession(BuildContext context) {
    final lang = context.read<TriageProvider>().selectedLanguage;
    final contactText = _patientContactController.text.trim();

    if (_patientNameController.text.trim().isEmpty || _selectedGender == null || _selectedAge == null || _selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('fill_all_options', lang),
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppTheme.triageRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (contactText.isNotEmpty && contactText.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('invalid_contact', lang),
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppTheme.triageRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final session = SessionModel(
      ashaWorkerName: workerName,
      patientName: _patientNameController.text.trim(),
      patientGender: _selectedGender,
      patientContact: contactText,
      patientAgeGroup: _selectedAge,
      symptomDuration: _selectedDuration,
    );

    context.read<TriageProvider>().startSession(session);
    
    // Pop the bottom sheet
    Navigator.of(context).pop();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const VoiceScreen(),
    ));
  }

  void _showPatientDetailsForm(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppTheme.bgPage,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment_ind_rounded, color: AppTheme.primary, size: 24),
                            const SizedBox(width: 10),
                            Text(AppStrings.get('patient_details_title', lang), style: GoogleFonts.poppins(
                                color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMedium),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Patient Name ──
                    _sectionLabel(AppStrings.get('patient_name_label', lang)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _patientNameController,
                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppStrings.get('patient_name_hint', lang),
                        prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Patient Gender ──
                    _sectionLabel(AppStrings.get('patient_gender_label', lang)),
                    const SizedBox(height: 10),
                    _buildGenderChips(lang, setModalState),

                    const SizedBox(height: 20),

                    // ── Age Group ──
                    _sectionLabel(AppStrings.get('patient_age_label', lang)),
                    const SizedBox(height: 10),
                    _buildAgeChips(lang, setModalState),

                    const SizedBox(height: 20),

                    // ── Patient Contact ──
                    _sectionLabel(AppStrings.get('patient_contact_label', lang)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _patientContactController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppStrings.get('patient_contact_hint', lang),
                        prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.primary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Symptom Duration ──
                    _sectionLabel(AppStrings.get('symptom_duration_label', lang)),
                    const SizedBox(height: 10),
                    _buildDurationChips(lang, setModalState),

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
            );
          },
        );
      },
    );
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

                    // ── Recent Stats Row ──
                    _buildStatsRow(lang),

                    const SizedBox(height: 32),

                    // ── Start New Patient Button ──
                    AppTheme.gradientButton(
                      label: AppStrings.get('new_patient_triage', lang),
                      onTap: () => _showPatientDetailsForm(context, lang),
                      icon: Icons.add_circle_outline_rounded,
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
          Expanded(
            child: Text(AppStrings.get('asha_triage', lang),
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
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
                if (val != null) {
                  context.read<TriageProvider>().setLanguage(val);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(
        color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildGenderChips(String lang, StateSetter setModalState) {
    final Map<String, String> genders = {
      'Male': AppStrings.get('gender_male', lang),
      'Female': AppStrings.get('gender_female', lang),
    };
    return Wrap(
      spacing: 10,
      children: genders.entries.map((entry) {
        final genderKey = entry.key;
        final selected = _selectedGender == genderKey;
        return GestureDetector(
          onTap: () => setModalState(() => _selectedGender = genderKey),
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
            child: Text(entry.value,
                style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppTheme.textMedium,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeChips(String lang, StateSetter setModalState) {
    return Wrap(
      spacing: 10,
      children: AgeGroup.values.map((age) {
        final selected = _selectedAge == age;
        return GestureDetector(
          onTap: () => setModalState(() => _selectedAge = age),
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

  Widget _buildDurationChips(String lang, StateSetter setModalState) {
    return Wrap(
      spacing: 10,
      children: SymptomDuration.values.map((dur) {
        final selected = _selectedDuration == dur;
        return GestureDetector(
          onTap: () => setModalState(() => _selectedDuration = dur),
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
    final today = _stats['today'] ?? 0;
    final critical = _stats['critical'] ?? 0;
    final normal = _stats['normal'] ?? 0;

    return Row(
      children: [
        Expanded(child: _statCard('$today', AppStrings.get('today_patients', lang), Icons.people_alt_rounded,
            const Color(0xFF6C63FF), AppTheme.primaryGradient)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('$critical', AppStrings.get('critical_cases', lang), Icons.warning_amber_rounded,
            AppTheme.triageRed, AppTheme.redGradient)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('$normal', AppStrings.get('normal_cases', lang), Icons.check_circle_outline_rounded,
            AppTheme.triageGreen, AppTheme.greenGradient)),
      ],
    );
  }

  Widget _statCard(String num, String label, IconData icon, Color color, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(num, style: GoogleFonts.poppins(
              color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.poppins(
              color: AppTheme.textMedium, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
