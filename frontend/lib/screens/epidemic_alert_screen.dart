import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/database_service.dart';
import '../services/epidemic_service.dart';
import '../services/dashboard_service.dart';

class EpidemicAlertScreen extends StatefulWidget {
  const EpidemicAlertScreen({super.key});

  @override
  State<EpidemicAlertScreen> createState() => _EpidemicAlertScreenState();
}

class _EpidemicAlertScreenState extends State<EpidemicAlertScreen> {
  bool _isLoading = true;
  bool _alertTriggered = false;
  String _alertMessageHi = '';
  String _alertMessageEn = '';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _checkStatusAndLoadHistory();
  }

  Future<void> _checkStatusAndLoadHistory() async {
    setState(() => _isLoading = true);

    final result = await EpidemicService.instance.checkEpidemicAlerts();
    final snapshots = await DatabaseService.instance.getEpidemicSnapshots();

    setState(() {
      _alertTriggered = result['alert_triggered'] as bool? ?? false;
      _alertMessageHi = result['alert_message_hi'] as String? ?? '';
      _alertMessageEn = result['alert_message_en'] as String? ?? '';
      _history = snapshots;
      _isLoading = false;
    });
  }

  void _triggerSimulatedAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EpidemicAlertDialog(
        titleHindi: 'चेतावनी: संभावित महामारी का खतरा!',
        titleEnglish: 'Warning: Possible Epidemic Threat Detected!',
        messageHindi: 'समान लक्षणों का संकेंद्रीय संकेत मिला है। कृपया तुरंत उच्च अधिकारी को रिपोर्ट करें।',
        messageEnglish: 'High concentration of matching symptom patterns. Please report to supervisor immediately.',
      ),
    ).then((_) => _checkStatusAndLoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<TriageProvider>(context).selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with back button & simulated alert trigger
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang == 'hi' ? 'महामारी चेतावनी' : 'Epidemic Alerts',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bug_report_rounded, color: AppTheme.triageRed),
                          onPressed: _triggerSimulatedAlert,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Alert Panel
                    if (_alertTriggered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.triageRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.triageRed, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.triageRed, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang == 'hi' ? 'सक्रिय अलर्ट' : 'ACTIVE ALERT',
                                    style: const TextStyle(
                                      color: AppTheme.triageRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lang == 'hi' ? _alertMessageHi : _alertMessageEn,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.triageGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.triageGreen, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppTheme.triageGreen, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang == 'hi' ? 'सुरक्षित स्थिति' : 'Safe State',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.triageGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    lang == 'hi'
                                        ? 'पिछले 48 घंटों में कोई असामान्य लक्षण पैटर्न नहीं मिला।'
                                        : 'No unusual symptom patterns detected in the last 48 hours.',
                                    style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Log History Title
                    Text(
                      lang == 'hi' ? 'इतिहास लॉग' : 'Alert History Logs',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Log list
                    Expanded(
                      child: _history.isEmpty
                          ? Center(
                              child: Text(
                                lang == 'hi' ? 'कोई पिछला रिकॉर्ड नहीं' : 'No historical logs',
                                style: GoogleFonts.poppins(color: AppTheme.textLight),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final log = _history[index];
                                final dateStr = log['snapshot_date'] as String? ?? '';
                                final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                                final concept = log['dominant_concepts'] as String? ?? 'none';
                                final conceptText = DashboardService.symptomTranslationsLocalized[concept]?[lang] ?? concept;

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
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.triageRed.withOpacity(0.1),
                                      child: const Icon(Icons.notification_important_rounded, color: AppTheme.triageRed),
                                    ),
                                    title: Text(
                                      '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      lang == 'hi'
                                          ? 'संकेत: $conceptText\nगंभीर: ${log['red_count']} | मध्यम: ${log['yellow_count']}'
                                          : 'Indicator: $conceptText\nCritical: ${log['red_count']} | Moderate: ${log['yellow_count']}',
                                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMedium),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ===== SELF-CONTAINED HIGH-VISIBILITY OVERLAY WIDGET =====
class EpidemicAlertDialog extends StatelessWidget {
  final String titleHindi;
  final String titleEnglish;
  final String messageHindi;
  final String messageEnglish;

  const EpidemicAlertDialog({
    super.key,
    required this.titleHindi,
    required this.titleEnglish,
    required this.messageHindi,
    required this.messageEnglish,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TriageProvider>(context);
    final lang = provider.selectedLanguage;
    final title = lang == 'hi' ? titleHindi : titleEnglish;
    final message = lang == 'hi' ? messageHindi : messageEnglish;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppTheme.bgWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // High Visibility Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.triageRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppTheme.triageRed,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),

              // Monolingual Title (Wrapped in SafeArea and FittedBox to prevent 20px top-right overflow)
              SafeArea(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppTheme.triageRed,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monolingual Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppTheme.textMedium,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Acknowledgment Button (Height adjusted and wrapped in FittedBox to prevent 2px vertical overflow)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.triageRed,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        lang == 'hi' ? 'ANM को सूचित किया' : 'ANM Informed',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
