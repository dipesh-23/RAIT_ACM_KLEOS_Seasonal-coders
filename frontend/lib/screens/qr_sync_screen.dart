import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../app_theme.dart';
import '../services/qr_sync_service.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';

class QrSyncScreen extends StatefulWidget {
  const QrSyncScreen({super.key});

  @override
  State<QrSyncScreen> createState() => _QrSyncScreenState();
}

class _QrSyncScreenState extends State<QrSyncScreen> {
  final QrSyncService _service = QrSyncService();
  String _selectedPeriod = 'today';
  SyncPayload? _payload;
  bool _isGenerating = false;
  late String _workerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workerName = context.read<TriageProvider>().currentSession?.ashaWorkerName ?? 'ASHA Worker';
      _updatePayload();
    });
  }

  Future<void> _updatePayload() async {
    setState(() => _isGenerating = true);
    
    DateTime start;
    final now = DateTime.now();
    if (_selectedPeriod == 'today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriod == 'week') {
      start = now.subtract(const Duration(days: 7));
    } else {
      start = now.subtract(const Duration(days: 30));
    }

    final p = await _service.generatePayload(_workerName, start, now);
    setState(() {
      _payload = p;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgPage,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: Text(AppStrings.get('qr_sync', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: AppStrings.get('share_data', lang)),
              Tab(text: AppStrings.get('receive_data', lang)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSendTab(),
            _buildReceiveTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTab() {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.get('which_period', lang), style: GoogleFonts.poppins(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodBtn(AppStrings.get('today', lang), 'today'),
              _buildPeriodBtn(AppStrings.get('this_week', lang), 'week'),
              _buildPeriodBtn(AppStrings.get('this_month', lang), 'month'),
            ],
          ),
          const SizedBox(height: 24),

          if (_isGenerating)
            const Center(child: CircularProgressIndicator())
          else if (_payload != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('कुल मरीज़: ${_payload!.totalSessions}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  Text('RED रेफरल: ${_payload!.redCount}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  Text('YELLOW रेफरल: ${_payload!.yellowCount}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  Text('GREEN उपचार: ${_payload!.greenCount}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  Text('रेफरल स्लिप: ${_payload!.referralCount}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  Text('फॉलो-अप पूरे: ${_payload!.followupComplete}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: _payload!.toQrString(),
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  size: 250,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(AppStrings.get('show_qr_to_anm', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))),
            Center(child: Text(AppStrings.get('valid_30_mins', lang), style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. ANM का फोन खोलें / Open ANM phone', style: GoogleFonts.poppins(color: Colors.white)),
                  Text('2. ASHA Triage ऐप → डेटा पाएं', style: GoogleFonts.poppins(color: Colors.white)),
                  Text('3. स्कैन करें / Scan this QR code', style: GoogleFonts.poppins(color: Colors.white)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String label, String val) {
    final isSel = _selectedPeriod == val;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = val);
        _updatePayload();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildReceiveTab() {
    return const ReceiveTab();
  }
}

class ReceiveTab extends StatefulWidget {
  const ReceiveTab({super.key});

  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  bool _isScanning = false;
  SyncPayload? _scannedPayload;
  bool _isError = false;
  List<Map<String, dynamic>> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final hStr = prefs.getString('scan_history');
    if (hStr != null) {
      final List<dynamic> list = jsonDecode(hStr);
      setState(() {
        _scanHistory = list.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveToHistory(SyncPayload p) async {
    final prefs = await SharedPreferences.getInstance();
    _scanHistory.insert(0, {
      'workerName': p.workerName,
      'date': DateTime.now().toIso8601String(),
      'totalSessions': p.totalSessions,
    });
    if (_scanHistory.length > 5) _scanHistory = _scanHistory.sublist(0, 5);
    await prefs.setString('scan_history', jsonEncode(_scanHistory));
    setState(() {});
  }

  Future<void> _generatePdf(SyncPayload payload) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            children: [
              pw.Text('ANM Supervisor Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Worker: ${payload.workerName}'),
              pw.Text('Period: ${payload.periodStart.split('T').first} to ${payload.periodEnd.split('T').first}'),
              pw.Text('Total Sessions: ${payload.totalSessions}'),
              pw.Text('RED: ${payload.redCount}'),
              pw.Text('YELLOW: ${payload.yellowCount}'),
              pw.Text('GREEN: ${payload.greenCount}'),
              pw.SizedBox(height: 20),
              pw.Text('यह एक ट्राइएज रिपोर्ट है — निदान नहीं / This is a triage report — not a diagnosis', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    ));
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${payload.workerName}_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    if (_isScanning) {
      return Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final p = QrSyncService().parseScannedQr(barcode.rawValue!);
                  setState(() {
                    _isScanning = false;
                    if (p != null) {
                      _scannedPayload = p;
                      _isError = false;
                      _saveToHistory(p);
                    } else {
                      _scannedPayload = null;
                      _isError = true;
                    }
                  });
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: AppTheme.triageGreen, width: 4)),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => setState(() => _isScanning = false),
                child: const Text('Cancel'),
              ),
            ),
          )
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_scannedPayload != null) ...[
            const Icon(Icons.check_circle, color: AppTheme.triageGreen, size: 64),
            const SizedBox(height: 8),
            Center(child: Text(AppStrings.get('data_received', lang), style: GoogleFonts.poppins(color: AppTheme.triageGreen, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Worker: ${_scannedPayload!.workerName}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('कुल मरीज़: ${_scannedPayload!.totalSessions}', style: GoogleFonts.poppins(color: Colors.white)),
                  Text('RED: ${_scannedPayload!.redCount}', style: GoogleFonts.poppins(color: Colors.white)),
                  Text('YELLOW: ${_scannedPayload!.yellowCount}', style: GoogleFonts.poppins(color: Colors.white)),
                  Text('GREEN: ${_scannedPayload!.greenCount}', style: GoogleFonts.poppins(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 56)),
              onPressed: () => _generatePdf(_scannedPayload!),
              child: Text(AppStrings.get('save_report', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface, minimumSize: const Size(double.infinity, 56)),
              onPressed: () => setState(() { _scannedPayload = null; _isScanning = true; }),
              child: Text(AppStrings.get('scan_again', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ] else if (_isError) ...[
            const Icon(Icons.error_outline, color: AppTheme.triageRed, size: 64),
            const SizedBox(height: 16),
            Center(child: Text(AppStrings.get('invalid_qr', lang), style: GoogleFonts.poppins(color: AppTheme.triageRed, fontSize: 18))),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 56)),
              onPressed: () => setState(() { _isError = false; _isScanning = true; }),
              child: Text(AppStrings.get('scan_again', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isScanning = true),
                child: Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 64),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text(AppStrings.get('scan_qr', lang), style: GoogleFonts.poppins(color: Colors.white, fontSize: 18))),
            const SizedBox(height: 32),
            if (_scanHistory.isNotEmpty) ...[
              Text('Scan History', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._scanHistory.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h['workerName'], style: GoogleFonts.poppins(color: Colors.white)),
                    Text(h['date'].toString().split('T').first, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ))
            ]
          ]
        ],
      ),
    );
  }
}
