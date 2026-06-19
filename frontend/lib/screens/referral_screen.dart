// ===== FILE: lib/screens/referral_screen.dart =====
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../models/session_model.dart';
import 'session_start_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _sharePdf(String lang) async {
    if (_isSharing) return;
    setState(() {
      _isSharing = true;
    });

    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Repaint boundary not found");
      }

      // Capture image with high resolution pixel ratio
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Create PDF
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      // Save PDF to temp directory
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/referral_slip_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      // Share PDF using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: lang == 'hi' ? 'ASHA रेफरल स्लिप' : 'ASHA Referral Slip',
      );
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'hi' ? 'शेयर करने में त्रुटि: $e' : 'Sharing Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final session = provider.currentSession;
    final result = provider.currentResult;
    final now = DateTime.now();
    final lang = provider.selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
        title: Text(
          lang == 'hi' ? 'रेफरल स्लिप' : 'Referral Slip',
          style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSharing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.share_rounded, color: AppTheme.primary),
                  onPressed: () => _sharePdf(lang),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            // ── Referral Card ──
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.bgWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.triageRed.withOpacity(0.2), width: 1.5),
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
                          const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            lang == 'hi' ? 'ASHA तत्काल रेफरल' : 'ASHA Urgent Referral',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            lang == 'hi' ? 'त्वरित स्वास्थ्य रेफरल पर्ची' : 'Urgent Health Referral Slip',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // Info Rows
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _infoRow(
                            lang == 'hi' ? 'रेफरल कोड' : 'Referral Code',
                            session?.sessionCode ?? '--',
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'ASHA कार्यकर्ता' : 'ASHA Worker',
                            session?.ashaWorkerName ?? 'ASHA Worker',
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'मरीज आयु वर्ग' : 'Patient Age Group',
                            session?.patientAgeGroup?.labelForLang(lang) ?? '--',
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'लक्षण अवधि' : 'Symptom Duration',
                            session?.symptomDuration?.labelForLang(lang) ?? '--',
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'ट्राइएज स्थिति' : 'Triage Status',
                            result?.categoryLabelForLang(lang) ?? (lang == 'hi' ? 'गंभीर' : 'Critical'),
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'दिनांक' : 'Date',
                            '${now.day}/${now.month}/${now.year}',
                          ),
                          _divider(),
                          _infoRow(
                            lang == 'hi' ? 'समय' : 'Time',
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.triageRed.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.triageRed.withOpacity(0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'hi' ? 'पुष्टि किए गए लक्षण:' : 'Confirmed Symptoms:',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.triageRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    String symptomsText = lang == 'hi' ? 'कोई लक्षण नहीं' : 'No Symptoms';
                                    if (result != null && result.matchedSymptoms.isNotEmpty) {
                                      symptomsText = result.matchedSymptoms.join(', ');
                                    }
                                    return Text(
                                      symptomsText,
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textDark,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang == 'hi'
                                ? 'सरकारी स्वास्थ्य केंद्र (PHC) में तुरंत ले जाएं'
                                : 'Take immediately to the nearest PHC / Government Health Center',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            AppTheme.gradientButton(
              label: lang == 'hi' ? 'नया मरीज शुरू करें' : 'Start New Patient',
              onTap: () {
                context.read<TriageProvider>().reset();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SessionStartScreen()),
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
          Text(
            label,
            style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: AppTheme.divider, height: 1);
}
