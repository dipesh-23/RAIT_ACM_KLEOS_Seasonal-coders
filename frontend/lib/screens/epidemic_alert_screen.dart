import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/epidemic_service.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';

class EpidemicAlertScreen extends StatefulWidget {
  const EpidemicAlertScreen({super.key});

  @override
  State<EpidemicAlertScreen> createState() => _EpidemicAlertScreenState();
}

class _EpidemicAlertScreenState extends State<EpidemicAlertScreen> {
  final EpidemicService _service = EpidemicService();
  EpidemicAlert? _currentAlert;
  List<EpidemicAlert> _history = [];
  bool _isLoading = true;
  late String _workerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workerName = context.read<TriageProvider>().currentSession?.ashaWorkerName ?? 'ASHA Worker';
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final alert = await _service.checkForAlerts(_workerName);
    final history = await _service.getAlertHistory(_workerName, 30);
    setState(() {
      _currentAlert = alert;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgPage,
        appBar: AppBar(backgroundColor: AppTheme.surface, title: Text(AppStrings.get('epidemic_alert', lang))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(AppStrings.get('epidemic_alert', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_currentAlert != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppTheme.triageRed,
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(lang == 'en' ? _currentAlert!.englishMessage : _currentAlert!.hindiMessage, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.triageRed,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentAlert = null;
                        });
                      },
                      icon: const Icon(Icons.call),
                      label: Text(AppStrings.get('informed_anm', lang), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.triageGreen),
                    const SizedBox(height: 16),
                    Text(AppStrings.get('no_unusual_pattern', lang), style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 18)),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.get('alert_history', lang), style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(AppStrings.get('no_previous_alerts', lang), textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textMedium)),
                    ))
                  else
                    ..._history.map((alert) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(alert.alertType == 'RED_CLUSTER' ? Icons.emergency : Icons.group, color: AppTheme.triageYellow, size: 20),
                              const SizedBox(width: 8),
                              Text(alert.detectedAt.toIso8601String().split('T').first, style: GoogleFonts.poppins(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(lang == 'en' ? alert.englishMessage : alert.hindiMessage, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EpidemicAlertDialog extends StatelessWidget {
  final EpidemicAlert alert;

  const EpidemicAlertDialog({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.triageRed),
            const SizedBox(height: 16),
            Text(lang == 'en' ? alert.englishMessage : alert.hindiMessage, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('ok_btn', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
