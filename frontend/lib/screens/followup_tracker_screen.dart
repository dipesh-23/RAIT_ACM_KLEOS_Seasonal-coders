import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/database_service.dart';
import '../services/followup_service.dart';
import '../main.dart';

class FollowupTrackerScreen extends StatefulWidget {
  const FollowupTrackerScreen({super.key});

  @override
  State<FollowupTrackerScreen> createState() => _FollowupTrackerScreenState();
}

class _FollowupTrackerScreenState extends State<FollowupTrackerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _followups = [];

  // Metrics counter
  int _totalFollowups = 0;
  int _reachedHospitalCount = 0;
  int _treatmentReceivedCount = 0;
  int _returnedHomeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFollowups();
  }

  Future<void> _loadFollowups() async {
    setState(() => _isLoading = true);

    final records = await FollowupService.instance.getPendingFollowups();

    int reached = 0;
    int treated = 0;
    int returned = 0;

    for (var r in records) {
      if (r['reached_hospital'] == 1) reached++;
      if (r['treatment_received'] == 1) treated++;
      if (r['returned_home'] == 1) returned++;
    }

    setState(() {
      _followups = records;
      _totalFollowups = records.length;
      _reachedHospitalCount = reached;
      _treatmentReceivedCount = treated;
      _returnedHomeCount = returned;
      _isLoading = false;
    });
  }

  Future<void> _toggleMetric(String sessionCode, String columnName, int currentValue) async {
    final newValue = currentValue == 1 ? 0 : 1;
    await DatabaseService.instance.updateFollowupStatus(sessionCode, {
      columnName: newValue,
      'last_updated': DateTime.now().toIso8601String(),
    });
    _loadFollowups();
  }

  Future<void> _completeFollowup(String sessionCode, String notes) async {
    await FollowupService.instance.updateStatus(
      sessionCode: sessionCode,
      reachedHospital: true,
      treatmentReceived: true,
      returnedHome: true,
      notes: notes,
    );
    _loadFollowups();
  }

  String getTriageLevelLabel(String level, String lang) {
    if (lang == 'hi') {
      switch (level) {
        case 'RED': return 'गंभीर (RED)';
        case 'YELLOW': return 'मध्यम (YELLOW)';
        default: return 'सामान्य (GREEN)';
      }
    } else {
      switch (level) {
        case 'RED': return 'Critical (RED)';
        case 'YELLOW': return 'Moderate (YELLOW)';
        default: return 'Normal (GREEN)';
      }
    }
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
          lang == 'hi' ? 'फॉलो-अप सूची' : 'Follow-up Monitor',
          style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppTheme.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Metrics Ribbon
                _buildMetricsRibbon(lang),

                // Followup Cards List
                Expanded(
                  child: _followups.isEmpty
                      ? Center(
                          child: Text(
                            lang == 'hi' ? 'कोई लंबित फॉलो-अप नहीं' : 'No pending follow-ups',
                            style: GoogleFonts.poppins(color: AppTheme.textLight),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _followups.length,
                          itemBuilder: (context, index) {
                            final followup = _followups[index];
                            final sessionCode = followup['session_code'] as String? ?? '';
                            final referralDateStr = followup['referral_date'] as String? ?? '';
                            final date = DateTime.tryParse(referralDateStr) ?? DateTime.now();

                            final reached = followup['reached_hospital'] as int? ?? 0;
                            final treated = followup['treatment_received'] as int? ?? 0;
                            final returned = followup['returned_home'] as int? ?? 0;

                            final isComplete = reached == 1 && treated == 1 && returned == 1;
                            final level = followup['triage_level'] as String? ?? 'YELLOW';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: AppTheme.bgWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isComplete ? AppTheme.triageGreen : AppTheme.borderColor,
                                  width: isComplete ? 2.5 : 1.5,
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Session and Date
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          lang == 'hi' ? 'मरीज कोड: $sessionCode' : 'Patient Code: $sessionCode',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                                        ),
                                        Text(
                                          '${date.day}/${date.month}/${date.year}',
                                          style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lang == 'hi'
                                          ? 'रेफरल स्तर: ${getTriageLevelLabel(level, lang)}'
                                          : 'Referral Level: ${getTriageLevelLabel(level, lang)}',
                                      style: GoogleFonts.poppins(
                                        color: level == 'RED' ? AppTheme.triageRed : AppTheme.triageYellow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Row 2: Status Indicator Buttons (minimum 56px high targets)
                                    Row(
                                      children: [
                                        _buildStatusToggleButton(
                                          label: lang == 'hi' ? '🏥 अस्पताल?' : '🏥 Reached?',
                                          value: reached == 1,
                                          onTap: () => _toggleMetric(sessionCode, 'reached_hospital', reached),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildStatusToggleButton(
                                          label: lang == 'hi' ? '💊 इलाज?' : '💊 Treated?',
                                          value: treated == 1,
                                          onTap: () => _toggleMetric(sessionCode, 'treatment_received', treated),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildStatusToggleButton(
                                          label: lang == 'hi' ? '🏠 वापसी?' : '🏠 Home?',
                                          value: returned == 1,
                                          onTap: () => _toggleMetric(sessionCode, 'returned_home', returned),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Outcome Highlight
                                    if (isComplete)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.triageGreen.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.triageGreen, width: 1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lang == 'hi' ? '✓ फॉलो-अप पूरा' : '✓ Follow-up Complete',
                                            style: GoogleFonts.poppins(
                                              color: AppTheme.triageGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: OutlinedButton(
                                          onPressed: () => _completeFollowup(sessionCode, 'Completed on-site follow-up'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primary,
                                            side: const BorderSide(color: AppTheme.primary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                            lang == 'hi' ? 'पूरा घोषित करें' : 'Set Complete',
                                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricsRibbon(String lang) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgWhite,
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ribbonItem(lang == 'hi' ? 'कुल' : 'Total', '$_totalFollowups'),
          _ribbonItem(lang == 'hi' ? '🏥 अस्पताल' : '🏥 Reached', '$_reachedHospitalCount'),
          _ribbonItem(lang == 'hi' ? '💊 इलाज' : '💊 Treated', '$_treatmentReceivedCount'),
          _ribbonItem(lang == 'hi' ? '🏠 वापसी' : '🏠 Home', '$_returnedHomeCount'),
        ],
      ),
    );
  }

  Widget _ribbonItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusToggleButton({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56, // Minimum 56px vertical target
          decoration: BoxDecoration(
            color: value ? AppTheme.primary : AppTheme.bgPage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? Colors.transparent : AppTheme.borderColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: value ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
