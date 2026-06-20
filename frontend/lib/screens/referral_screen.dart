import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../models/session_model.dart';
import '../services/database_service.dart';
import '../models/triage_result.dart';
import 'session_start_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a slight delay to ensure the UI is fully painted
      Future.delayed(const Duration(milliseconds: 500), _saveSlipAutomatically);
    });
  }

  Future<void> _saveSlipAutomatically() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
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

      final output = await getApplicationDocumentsDirectory();
      final session = context.read<TriageProvider>().currentSession;
      if (session == null) return;

      final filePath = "${output.path}/slip_${session.sessionCode}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Update Database with slip path
      final updatedSession = session.copyWith(slipFilePath: filePath);
      context.read<TriageProvider>().updateSession(updatedSession); // Or update via DB directly
      await DatabaseService.instance.updateSession(updatedSession);
      debugPrint('[ReferralScreen] Auto-saved slip to $filePath');
    } catch (e) {
      debugPrint('[ReferralScreen] Failed to auto-save slip: $e');
    }
  }

  String _generateSummaryText() {
    final provider = context.read<TriageProvider>();
    final session = provider.currentSession;
    final result = provider.currentResult;
    final now = DateTime.now();

    // We use a purely English/ASCII string here.
    // qr_flutter (and the underlying qr package) has known bugs on some platforms
    // where complex Unicode/Hindi strings cause the layout thread to freeze or crash.
    return '''ASHA Referral Slip
Session: ${session?.sessionCode ?? '--'}
Age: ${session?.patientAgeGroup?.name.toUpperCase() ?? '--'}
Duration: ${session?.symptomDuration?.name.toUpperCase() ?? '--'}
Symptoms Count: ${result?.matchedSymptoms.length ?? 0}
Status: ${result?.category.name.toUpperCase() ?? 'RED'}
Date: ${now.day}/${now.month}/${now.year}
Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}''';
  }

  void _showQrSummary() {
    final summaryText = _generateSummaryText();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Offline QR Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ask patient to scan this QR code to instantly receive their report summary offline.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMedium)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider, width: 2),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: summaryText,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.poppins(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }



  Future<void> _sharePdf() async {
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
        text: 'ASHA Referral Slip',
      );
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('शेयर करने में त्रुटि: $e'),
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
              : Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
                      tooltip: 'Show QR Summary (Offline)',
                      onPressed: _showQrSummary,
                    ),
                    IconButton(
                      icon: Icon(Icons.share_rounded, color: AppTheme.primary),
                      tooltip: 'Share App/PDF',
                      onPressed: _sharePdf,
                    ),
                  ],
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
                  border: Border.all(
                      color: (result?.category == TriageCategory.green ? AppTheme.triageGreen : AppTheme.triageRed).withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Red Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: result?.category == TriageCategory.green ? AppTheme.greenGradient : AppTheme.redGradient,
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
                          Text(result?.category == TriageCategory.green ? 'ASHA घरेलू उपचार सलाह' : 'ASHA तत्काल रेफरल',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          Text(result?.category == TriageCategory.green ? 'Home Care Advice Slip' : 'Urgent Health Referral Slip',
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
                          Text(result?.category == TriageCategory.green 
                                  ? 'घर पर आराम करें और 2 दिन निगरानी रखें\nHome Care. Monitor for 2 days.'
                                  : 'सरकारी स्वास्थ्य केंद्र / PHC में तुरंत ले जाएं',
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
