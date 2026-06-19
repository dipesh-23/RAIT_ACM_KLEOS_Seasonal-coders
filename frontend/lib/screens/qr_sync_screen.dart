import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/database_service.dart';
import '../services/qr_sync_service.dart';
import '../main.dart';

class QrSyncScreen extends StatefulWidget {
  const QrSyncScreen({super.key});

  @override
  State<QrSyncScreen> createState() => _QrSyncScreenState();
}

class _QrSyncScreenState extends State<QrSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _qrPayload = '';

  // Scan Results Log
  final List<Map<String, dynamic>> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generatePayload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePayload() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      final stats = await DatabaseService.instance.getWorkerStats();
      final activePregnancies = await DatabaseService.instance.getActivePregnancyProfiles();
      final pendingFollowups = await DatabaseService.instance.getPendingFollowups();

      final total = stats['total'] ?? 0;
      final red = stats['critical'] ?? 0;
      final referrals = stats['referrals'] ?? 0;

      final payload = QrSyncService.instance.serialize(
        workerName: 'ASHA Worker',
        startDate: startDate,
        endDate: now,
        total: total,
        red: red,
        yellow: 0,
        green: total - red,
        referrals: referrals,
        followups: pendingFollowups.length,
        pregnancies: activePregnancies.length,
        alerts: 0,
      );

      setState(() {
        _qrPayload = payload;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _qrPayload = 'ASHA|Worker|20260101|20260130|0|0|0|0|0|0|0|0|1.0|0';
        _isLoading = false;
      });
    }
  }

  void _onQrScanned(BarcodeCapture capture, String lang) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    final verifiedData = QrSyncService.instance.deserialize(code);
    if (verifiedData != null) {
      final alreadyExists = _scanHistory.any((element) => element['timestamp'] == verifiedData['timestamp']);
      if (!alreadyExists) {
        setState(() {
          _scanHistory.insert(0, verifiedData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'hi'
                  ? 'सत्यापित डेटा सिंक सफल: ${verifiedData['worker_name']}'
                  : 'Verified Sync Successful: ${verifiedData['worker_name']}',
            ),
            backgroundColor: AppTheme.triageGreen,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'hi' ? 'अवैध क्यूआर कोड पैटर्न' : 'Invalid QR Code Pattern',
          ),
          backgroundColor: AppTheme.triageRed,
        ),
      );
    }
  }

  void _shareReport(Map<String, dynamic> report) {
    final text = 'ASHA Worker: ${report['worker_name']}\n'
        'Total Patients: ${report['total']}\n'
        'Critical cases: ${report['red']}\n'
        'Referrals: ${report['referrals']}\n'
        'Pregnancies: ${report['pregnancies']}\n'
        'Followups: ${report['followups']}';
    Share.share(text, subject: 'ASHA Supervisor Sync Report');
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<TriageProvider>(context).selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.bgWhite,
        elevation: 1,
        title: Text(
          lang == 'hi' ? 'पर्यवेक्षक डेटा सिंक' : 'Supervisor Sync',
          style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppTheme.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: lang == 'hi' ? 'क्यूआर दिखाएं' : 'Show QR'),
            Tab(text: lang == 'hi' ? 'स्कैन करें' : 'Scan QR'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Show QR Code
                _buildShowQrTab(lang),
                // Tab 2: Scan QR Code
                _buildScanQrTab(lang),
              ],
            ),
    );
  }

  Widget _buildShowQrTab(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            lang == 'hi' ? 'पर्यवेक्षक सिंक क्यूआर' : 'Supervisor Sync QR',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          Text(
            lang == 'hi'
                ? 'डेटा साझा करने के लिए पर्यवेक्षक को यह क्यूआर दिखाएं'
                : 'Show this QR to supervisor to sync database stats',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 40),

          // QR Matrix (ECL M)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.borderColor, width: 2),
            ),
            child: QrImageView(
              data: _qrPayload,
              version: QrVersions.auto,
              size: 250.0,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              gapless: false,
            ),
          ),
          const SizedBox(height: 40),

          // Payload size summary info
          Text(
            lang == 'hi'
                ? 'डेटा पेलोड आकार: ${_qrPayload.length} वर्ण'
                : 'Data Payload Size: ${_qrPayload.length} characters',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
        ].map((w) => Center(child: w)).toList(),
      ),
    );
  }

  Widget _buildScanQrTab(String lang) {
    return Column(
      children: [
        // Camera Viewport Box with Viewfinder Overlay
        Container(
          height: 280,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) => _onQrScanned(capture, lang),
                ),
                // Optical Viewfinder Overlay (Green Target Overlay)
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.triageGreen, width: 3.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Double-Action Dashboard / Scan History Logs Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              lang == 'hi' ? 'सिंक इतिहास रिकॉर्ड' : 'Synced Reports History',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
            ),
          ),
        ),

        // Sync history list view
        Expanded(
          child: _scanHistory.isEmpty
              ? Center(
                  child: Text(
                    lang == 'hi' ? 'कोई सिंक रिकॉर्ड नहीं' : 'No sync records',
                    style: GoogleFonts.poppins(color: AppTheme.textLight),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _scanHistory.length,
                  itemBuilder: (context, index) {
                    final report = _scanHistory[index];
                    return Card(
                      elevation: 0,
                      color: AppTheme.bgWhite,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          report['worker_name'] ?? 'Worker',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          lang == 'hi'
                              ? 'मरीज़: ${report['total']} | गंभीर: ${report['red']}\nपंजीकरण: ${report['pregnancies']}'
                              : 'Patients: ${report['total']} | Critical: ${report['red']}\nPregnancies: ${report['pregnancies']}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMedium),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
                          onPressed: () => _shareReport(report),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
