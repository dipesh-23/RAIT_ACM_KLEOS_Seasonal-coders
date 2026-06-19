import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/database_service.dart';
import '../services/onboarding_service.dart';
import 'package:open_filex/open_filex.dart';
import '../models/session_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _stats = {};
  List<SessionModel> _recentSessions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DatabaseService.instance.getWorkerStats();
    final sessions = _searchQuery.trim().isEmpty
        ? await DatabaseService.instance.getRecentSessions(limit: 50)
        : await DatabaseService.instance.searchSessions(_searchQuery.trim());
    if (mounted) {
      setState(() {
        _stats = stats;
        _recentSessions = sessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerName = OnboardingService.instance.workerName;
    final initials = workerName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: AppTheme.bgWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppTheme.textDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('My Profile',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Profile Card ──
                            _buildProfileCard(workerName, initials),
                            const SizedBox(height: 24),

                            // ── Stats Grid ──
                            Text('Statistics',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                            const SizedBox(height: 12),
                            _buildStatsGrid(),
                            const SizedBox(height: 24),

                            // ── Patient List Header ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Patients List',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark)),
                                Text(_searchQuery.isEmpty ? 'Recent 50' : 'Search Results',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textLight)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // ── Search Bar ──
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _loadData();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search by name or ID...',
                                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight),
                                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMedium),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildRecentPatients(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String workerName, String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Center(
              child: Text(initials,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 14),
          Text(workerName,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('ASHA Worker',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),

          // Quick summary numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickStat('${_stats['total'] ?? 0}', 'Total\nPatients'),
              _vDivider(),
              _quickStat('${_stats['today'] ?? 0}', 'Today\'s\nPatients'),
              _vDivider(),
              _quickStat('${_stats['this_month'] ?? 0}', 'This\nMonth'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.white30);

  Widget _buildStatsGrid() {
    final total = _stats['total'] ?? 0;
    final critical = _stats['critical'] ?? 0;
    final normalCount = total - critical;
    final completionPct =
        total > 0 ? '${(normalCount / total * 100).toStringAsFixed(0)}%' : '—';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          icon: Icons.people_alt_rounded,
          label: 'Total Patients\nHelped',
          value: '$total',
          color: AppTheme.primary,
          gradient: AppTheme.primaryGradient,
        ),
        _statCard(
          icon: Icons.today_rounded,
          label: 'Patients\nToday',
          value: '${_stats['today'] ?? 0}',
          color: const Color(0xFF00897B),
          gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF4DB6AC)]),
        ),
        _statCard(
          icon: Icons.calendar_month_rounded,
          label: 'Patients\nThis Month',
          value: '${_stats['this_month'] ?? 0}',
          color: const Color(0xFF1E88E5),
          gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)]),
        ),
        _statCard(
          icon: Icons.warning_amber_rounded,
          label: 'Critical\nCases (RED)',
          value: '$critical',
          color: AppTheme.triageRed,
          gradient: AppTheme.redGradient,
        ),
        _statCard(
          icon: Icons.local_hospital_rounded,
          label: 'Referrals\nGenerated',
          value: '${_stats['referrals'] ?? 0}',
          color: const Color(0xFFE65100),
          gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF8A65)]),
        ),
        _statCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Completion\nRate',
          value: completionPct,
          color: AppTheme.triageGreen,
          gradient: AppTheme.greenGradient,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style:
                        GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatients() {
    if (_recentSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.person_search_rounded,
                color: AppTheme.textLight, size: 48),
            const SizedBox(height: 12),
            Text('No patients yet',
                style: GoogleFonts.poppins(
                    color: AppTheme.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: _recentSessions.asMap().entries.map((entry) {
          final isLast = entry.key == _recentSessions.length - 1;
          return _patientTile(entry.value, isLast);
        }).toList(),
      ),
    );
  }

  Widget _patientTile(SessionModel session, bool isLast) {
    Color levelColor = AppTheme.triageGreen;
    IconData levelIcon = Icons.check_circle_rounded;
    String levelLabel = 'Normal';

    if (session.triageLevel == 'RED') {
      levelColor = AppTheme.triageRed;
      levelIcon = Icons.warning_rounded;
      levelLabel = 'Critical';
    } else if (session.triageLevel == 'YELLOW') {
      levelColor = AppTheme.triageYellow;
      levelIcon = Icons.info_rounded;
      levelLabel = 'Moderate';
    }

    final dt = session.startedAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(levelIcon, color: levelColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.patientName?.isNotEmpty == true
                          ? session.patientName!
                          : 'Patient #${session.sessionCode}',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (session.patientGender != null) ...[
                          Icon(
                            session.patientGender == 'Female'
                                ? Icons.female_rounded
                                : Icons.male_rounded,
                            size: 13,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 3),
                          Text(session.patientGender!,
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textLight, fontSize: 11)),
                          const SizedBox(width: 8),
                        ],
                        if (session.patientAgeGroup != null)
                          Text(session.patientAgeGroup!.labelForLang('en'),
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textLight, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$dateStr · $timeStr',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textHint, fontSize: 11)),
                  ],
                ),
              ),
              if (session.slipFilePath != null)
                IconButton(
                  icon: Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary, size: 24),
                  tooltip: 'View Referral Slip',
                  onPressed: () {
                    OpenFilex.open(session.slipFilePath!);
                  },
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(levelLabel,
                      style: GoogleFonts.poppins(
                          color: levelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.borderColor,
              indent: 72,
              endIndent: 16),
      ],
    );
  }
}
