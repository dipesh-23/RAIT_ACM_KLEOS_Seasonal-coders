import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../models/session_model.dart';
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
        title: Text('रेफरल स्लिप',
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
            onPressed: () {/* TODO: Share PDF */},
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
                        Text('ASHA तत्काल रेफरल',
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
                        _infoRow('रेफरल कोड (Session Code)',
                            session?.sessionCode ?? '--'),
                        _divider(),
                        _infoRow('ASHA कार्यकर्ता',
                            session?.ashaWorkerName ?? 'ASHA Worker'),
                        _divider(),
                        _infoRow('मरीज आयु वर्ग',
                            session?.patientAgeGroup?.labelHi ?? '--'),
                        _divider(),
                        _infoRow('लक्षण अवधि',
                            session?.symptomDuration?.labelHi ?? '--'),
                        _divider(),
                        _infoRow('ट्राइएज स्थिति',
                            result?.categoryLabel ?? 'गंभीर (Red)'),
                        _divider(),
                        _infoRow('दिनांक',
                            '${now.day}/${now.month}/${now.year}'),
                        _divider(),
                        _infoRow('समय',
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
                              Text('लक्षण / Symptoms (Confirmed Only):',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.triageRed, fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  String symptomsText = 'कोई लक्षण नहीं';
                                  
                                  // The result.matchedSymptoms has the list of confirmed concept hindiLabels (or reasons) from triage engine
                                  if (result != null && result.matchedSymptoms.isNotEmpty) {
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
                        Text('सरकारी स्वास्थ्य केंद्र / PHC में तुरंत ले जाएं',
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
              label: 'नया मरीज शुरू करें',
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
