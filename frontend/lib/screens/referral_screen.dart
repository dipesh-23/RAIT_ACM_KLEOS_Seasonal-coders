import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../app_theme.dart';
import '../models/triage_result.dart';
import '../providers/triage_provider.dart';
import '../services/database_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late Future<pw.Document> _pdfFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TriageProvider>();
    _pdfFuture = _buildPdf(provider);
    // Mark referral generated
    if (provider.triageResult != null) {
      DatabaseService.instance
          .markReferralGenerated(provider.triageResult!.sessionCode);
    }
  }

  Future<pw.Document> _buildPdf(TriageProvider provider) async {
    final result = provider.triageResult!;
    final doc = pw.Document();

    final levelColor = _pdfLevelColor(result.level);
    final levelHindi = result.levelHindi;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              color: PdfColor.fromHex('1A237E'),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ASHA Triage Referral',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'ASHA Triage Referral Slip',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 13),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Triage level badge
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              color: levelColor,
              child: pw.Text(
                'Triage: $levelHindi',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.SizedBox(height: 20),

            // Session info table
            _pdfRow('Session Code', result.sessionCode),
            _pdfRow('Worker Name', provider.workerName),
            _pdfRow('Age Group', _ageGroupHindi(provider.ageGroup)),
            _pdfRow('Duration', _durationHindi(provider.duration)),
            _pdfRow(
              'Date & Time',
              '${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year}  '
                  '${result.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${result.timestamp.minute.toString().padLeft(2, '0')}',
            ),

            pw.SizedBox(height: 20),

            // Confirmed symptoms — NO raw transcription
            if (result.confirmedConcepts.isNotEmpty) ...[
              pw.Text(
                'Confirmed Symptoms / पुष्ट लक्षण:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              ...result.confirmedConcepts.map(
                (c) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    children: [
                      pw.Text('• ',
                          style: const pw.TextStyle(fontSize: 13)),
                      pw.Expanded(
                        child: pw.Text(c.hindiQuestion,
                            style: const pw.TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            pw.Spacer(),

            // Disclaimer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'यह एक ट्राइएज रेफरल है। यह निदान नहीं है। दवा की सलाह नहीं है।\n'
                'This is a triage referral only. Not a diagnosis. No medication advice.',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  PdfColor _pdfLevelColor(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return PdfColor.fromHex('D32F2F');
      case TriageLevel.yellow:
        return PdfColor.fromHex('F9A825');
      case TriageLevel.green:
        return PdfColor.fromHex('388E3C');
    }
  }

  String _ageGroupHindi(String ag) {
    switch (ag) {
      case 'NEWBORN':
        return 'नवजात (0-28 दिन)';
      case 'CHILD':
        return 'बच्चा (1 माह - 12 वर्ष)';
      case 'ADULT':
        return 'वयस्क (13-60 वर्ष)';
      case 'ELDERLY':
        return 'बुजुर्ग (60+ वर्ष)';
      default:
        return ag;
    }
  }

  String _durationHindi(String d) {
    switch (d) {
      case 'TODAY':
        return 'आज';
      case 'TWO_THREE_DAYS':
        return '2-3 दिन';
      case 'FOUR_PLUS_DAYS':
        return '4+ दिन';
      default:
        return d;
    }
  }

  Future<void> _share(pw.Document doc) async {
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/referral_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'ASHA Triage Referral Slip',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('रेफरल स्लिप')),
      body: FutureBuilder<pw.Document>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('स्लिप बन रही है...',
                      style: AppTextStyles.hindiBody),
                ],
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('त्रुटि हुई। पुनः प्रयास करें।',
                  style: AppTextStyles.hindiBody),
            );
          }

          final doc = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (_) => doc.save(),
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: AppTheme.primaryButtonStyle().copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                              Size(0, 64)),
                        ),
                        onPressed: () async {
                          final bytes = await doc.save();
                          await Printing.layoutPdf(
                              onLayout: (_) async => bytes);
                        },
                        icon: const Icon(Icons.print, size: 24),
                        label: const Text('प्रिंट करें'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.confirmYes,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 64),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          textStyle: AppTextStyles.hindiButton,
                        ),
                        onPressed: () => _share(doc),
                        icon: const Icon(Icons.share, size: 24),
                        label: const Text('शेयर करें'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
