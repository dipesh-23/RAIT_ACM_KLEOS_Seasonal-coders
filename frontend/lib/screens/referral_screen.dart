import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../models/session_model.dart';
import '../services/followup_service.dart';
import '../utils/app_strings.dart';
import 'session_start_screen.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final session = provider.currentSession;
    final result = provider.currentResult;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
        title: Text(AppStrings.get('referral_slip', provider.selectedLanguage),
            style: GoogleFonts.poppins(
                color: AppTheme.textDark, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: AppTheme.primary),
            onPressed: () async {
              /* TODO: Share PDF logic (simplified for now) */
              
              if (session != null && result != null) {
                await FollowupService().createFollowupRecord(
                  session.sessionCode,
                  session.ashaWorkerName,
                  result.category.name,
                  DateTime.now().toIso8601String(),
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral recorded for follow-up')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            // ── Referral Card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                    color: AppTheme.triageRed.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  // Red Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.redGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_hospital_rounded,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        Text(AppStrings.get('asha_triage', provider.selectedLanguage),
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('Urgent Health Referral Slip',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),

                  // Info Rows
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _infoRow('Session Code',
                            session?.sessionCode ?? '--'),
                        _divider(),
                        _infoRow(AppStrings.get('asha_worker', provider.selectedLanguage),
                            session?.ashaWorkerName ?? 'ASHA Worker'),
                        _divider(),
                        _infoRow(AppStrings.get('patient_age_label', provider.selectedLanguage),
                            session?.patientAgeGroup?.name ?? '--'),
                        _divider(),
                        _infoRow(AppStrings.get('symptom_duration_label', provider.selectedLanguage),
                            session?.symptomDuration?.name ?? '--'),
                        _divider(),
                        _infoRow('Triage Level',
                            result?.categoryLabelForLang(provider.selectedLanguage) ?? '--'),
                        _divider(),
                        _infoRow('Date',
                            '${now.day}/${now.month}/${now.year}'),
                        _divider(),
                        _infoRow('Time',
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.triageRed.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.triageRed.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Symptoms (Confirmed):',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.triageRed, fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  String symptomsText = '--';
                                  final concepts = provider.detectedConcepts.where((c) => c.confirmed).toList();
                                  
                                  if (concepts.isNotEmpty) {
                                    symptomsText = concepts.map((c) => c.getLabelForLang(provider.selectedLanguage)).join(', ');
                                  } else if (result != null && result.matchedSymptoms.isNotEmpty) {
                                    symptomsText = result.matchedSymptoms.join(', ');
                                  }
                                  
                                  return Text(
                                    symptomsText,
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textDark, fontSize: 13,
                                        height: 1.5),
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Immediate referral to Government Health Center / PHC',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: AppTheme.textMedium, fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            AppTheme.gradientButton(
              label: AppStrings.get('new_patient_triage', provider.selectedLanguage),
              onTap: () {
                context.read<TriageProvider>().reset();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const SessionStartScreen()),
                  (route) => false,
                );
              },
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.poppins(
              color: AppTheme.textLight, fontSize: 13,
              fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(
              color: AppTheme.textDark, fontSize: 13,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: AppTheme.divider, height: 1);
}
