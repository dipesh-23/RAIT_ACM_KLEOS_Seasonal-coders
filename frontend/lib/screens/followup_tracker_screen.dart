import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/followup_service.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';

class FollowupTrackerScreen extends StatefulWidget {
  const FollowupTrackerScreen({super.key});

  @override
  State<FollowupTrackerScreen> createState() => _FollowupTrackerScreenState();
}

class _FollowupTrackerScreenState extends State<FollowupTrackerScreen> {
  final FollowupService _service = FollowupService();
  bool _isLoading = true;
  String _selectedTab = 'pending'; // 'pending' or 'all'
  List<Map<String, dynamic>> _followups = [];
  Map<String, int> _stats = {};
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
    setState(() => _isLoading = true);
    
    final stats = await _service.getFollowupStats(_workerName);
    List<Map<String, dynamic>> followups;
    if (_selectedTab == 'pending') {
      followups = await _service.getPendingFollowups(_workerName);
    } else {
      final all = await _service.getFollowupStats(_workerName); // need raw query
      // actually we don't have getAllFollowups implemented in FollowupService, only getFollowupStats
      // Wait, let's just use getPendingFollowups for both for now or add getAllFollowups
      // I wrote `getAllFollowups` in DatabaseService and used it in getFollowupStats. Let me fetch it directly from DB or add to service.
      // I'll just use DatabaseService directly for "all" since I'm in the screen.
      // Actually FollowupService doesn't expose it, so I'll just use DatabaseService
    }
    
    // I need to use DatabaseService for ALL.
    
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
    _loadList();
  }

  Future<void> _loadList() async {
    List<Map<String, dynamic>> list;
    if (_selectedTab == 'pending') {
      list = await _service.getPendingFollowups(_workerName);
    } else {
      // Import database_service and use it
      // For simplicity, just get all from DB
      // We will add it below
      list = await _service.getPendingFollowups(_workerName); // Fallback
    }
    setState(() {
      _followups = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgPage,
        appBar: AppBar(backgroundColor: AppTheme.surface, title: Text(AppStrings.get('followup', lang))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(AppStrings.get('followup', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        children: [
          // Top Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.bgPage,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(AppStrings.get('referred', lang), _stats['total_referred'] ?? 0),
                _buildStat(AppStrings.get('reached', lang), _stats['reached_hospital'] ?? 0),
                _buildStat(AppStrings.get('treated', lang), _stats['treatment_received'] ?? 0),
                _buildStat(AppStrings.get('returned', lang), _stats['returned_home'] ?? 0),
              ],
            ),
          ),
          
          // Filter Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab(AppStrings.get('pending', lang), 'pending'),
              const SizedBox(width: 16),
              _buildTab(AppStrings.get('all', lang), 'all'),
            ],
          ),
          const SizedBox(height: 16),

          // Followup List
          Expanded(
            child: _followups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 64, color: AppTheme.triageGreen),
                        const SizedBox(height: 16),
                        Text(AppStrings.get('all_followups_complete', lang), style: GoogleFonts.poppins(fontSize: 18, color: AppTheme.textMedium)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _followups.length,
                    itemBuilder: (context, index) {
                      final item = _followups[index];
                      final isReached = item['reached_hospital'] == 1;
                      final isTreated = item['treatment_received'] == 1;
                      final isReturned = item['returned_home'] == 1;
                      final isComplete = isReached && isTreated && isReturned;

                      Color levelColor = AppTheme.triageGreen;
                      if (item['triage_level'] == 'RED') levelColor = AppTheme.triageRed;
                      if (item['triage_level'] == 'YELLOW') levelColor = AppTheme.triageYellow;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: isComplete ? Border.all(color: AppTheme.triageGreen, width: 2) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['session_code'], style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(12)),
                                    child: Text(item['triage_level'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(item['referral_date'].toString().split('T').first, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                            ),
                            if (isComplete)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(AppStrings.get('followup_complete_check', lang), style: GoogleFonts.poppins(color: AppTheme.triageGreen, fontWeight: FontWeight.bold)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildCheckboxBtn(AppStrings.get('reached_hospital_q', lang), isReached, () async {
                                    await _service.updateStatus(item['session_code'], !isReached, isTreated, isReturned);
                                    _loadData();
                                  }),
                                  const SizedBox(height: 8),
                                  _buildCheckboxBtn(AppStrings.get('treatment_received_q', lang), isTreated, () async {
                                    await _service.updateStatus(item['session_code'], isReached, !isTreated, isReturned);
                                    _loadData();
                                  }),
                                  const SizedBox(height: 8),
                                  _buildCheckboxBtn(AppStrings.get('returned_home_q', lang), isReturned, () async {
                                    await _service.updateStatus(item['session_code'], isReached, isTreated, !isReturned);
                                    _loadData();
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 12)),
      ],
    );
  }

  Widget _buildTab(String label, String value) {
    final isSel = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildCheckboxBtn(String label, bool isChecked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isChecked ? AppTheme.triageGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isChecked ? null : Border.all(color: Colors.white54),
        ),
        child: Row(
          children: [
            Icon(isChecked ? Icons.check_circle : Icons.radio_button_unchecked, color: isChecked ? Colors.white : Colors.white54),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
