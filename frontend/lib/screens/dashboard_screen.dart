import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../app_theme.dart';
import '../services/dashboard_service.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  DashboardStats? _stats;
  String _selectedPeriod = 'today';
  bool _isLoading = true;
  late String _workerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workerName = context.read<TriageProvider>().currentSession?.ashaWorkerName ?? 'ASHA Worker';
      _loadStats('today');
    });
  }

  Future<void> _loadStats(String period) async {
    setState(() {
      _isLoading = true;
      _selectedPeriod = period;
    });

    DashboardStats stats;
    if (period == 'today') {
      stats = await _dashboardService.getStatsForToday(_workerName);
    } else if (period == 'week') {
      stats = await _dashboardService.getStatsForThisWeek(_workerName);
    } else {
      stats = await _dashboardService.getStatsForThisMonth(_workerName);
    }

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _generateMonthlyReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ASHA Triage - Monthly Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Worker: $_workerName'),
                pw.Text('Total Patients: ${_stats?.totalSessions ?? 0}'),
                pw.Text('RED Alerts: ${_stats?.redCount ?? 0}'),
                pw.Text('YELLOW Alerts: ${_stats?.yellowCount ?? 0}'),
                pw.Text('GREEN Cases: ${_stats?.greenCount ?? 0}'),
                pw.SizedBox(height: 20),
                pw.Text('यह एक ट्राइएज रिपोर्ट है — निदान नहीं / This is a triage report — not a diagnosis', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'asha_monthly_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;

    if (_isLoading || _stats == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgPage,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: Text(AppStrings.get('performance_dashboard', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(AppStrings.get('performance_dashboard', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text(_workerName, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToggleButton(AppStrings.get('today', lang), 'today'),
                _buildToggleButton(AppStrings.get('this_week', lang), 'week'),
                _buildToggleButton(AppStrings.get('this_month', lang), 'month'),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(AppStrings.get('total_patients_card', lang), _stats!.totalSessions.toString(), AppTheme.surface, Colors.white),
                _buildStatCard(AppStrings.get('immediate_referral', lang), _stats!.redCount.toString(), AppTheme.triageRed.withOpacity(0.2), AppTheme.triageRed),
                _buildStatCard(AppStrings.get('today_referral', lang), _stats!.yellowCount.toString(), AppTheme.triageYellow.withOpacity(0.2), AppTheme.triageYellow),
                _buildStatCard(AppStrings.get('local_treatment', lang), _stats!.greenCount.toString(), AppTheme.triageGreen.withOpacity(0.2), AppTheme.triageGreen),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart
            if (_stats!.dailyCounts.isNotEmpty) ...[
              Text(AppStrings.get('last_7_days', lang), style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (_stats!.dailyCounts.map((e) => e.red + e.yellow + e.green).fold(0, (max, e) => e > max ? e : max) + 2).toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const days = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
                            final dayName = days[_stats!.dailyCounts[value.toInt()].date.weekday - 1];
                            return Text(dayName, style: const TextStyle(color: Colors.white70, fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _stats!.dailyCounts.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: (e.value.red + e.value.yellow + e.value.green).toDouble(),
                            rodStackItems: [
                              BarChartRodStackItem(0, e.value.green.toDouble(), AppTheme.triageGreen),
                              BarChartRodStackItem(e.value.green.toDouble(), (e.value.green + e.value.yellow).toDouble(), AppTheme.triageYellow),
                              BarChartRodStackItem((e.value.green + e.value.yellow).toDouble(), (e.value.green + e.value.yellow + e.value.red).toDouble(), AppTheme.triageRed),
                            ],
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Referral Stats
            Row(
              children: [
                Expanded(child: _buildInfoTile(AppStrings.get('referral_slip', lang), _stats!.referralCount.toString())),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoTile(AppStrings.get('pending_followup', lang), _stats!.pendingFollowups.toString())),
              ],
            ),
            const SizedBox(height: 24),

            // Most Common Concern
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Text(AppStrings.get('most_common_symptom', lang), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_stats!.topConcept, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Monthly Report Button
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _generateMonthlyReport,
                child: Text(AppStrings.get('generate_monthly_report', lang), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text('ASHA Triage', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _loadStats(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMedium), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMedium), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
