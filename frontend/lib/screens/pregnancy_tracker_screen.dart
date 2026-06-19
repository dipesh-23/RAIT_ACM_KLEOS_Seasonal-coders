import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/pregnancy_service.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
}

class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
  final PregnancyService _service = PregnancyService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
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
    final profiles = await _service.getActiveProfiles(_workerName);
    setState(() {
      _profiles = profiles;
      _isLoading = false;
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
          title: Text(AppStrings.get('pregnancy_tracker', lang), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: AppStrings.get('patients', lang)),
              Tab(text: AppStrings.get('new_patient_tab', lang)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPatientsTab(),
                  _buildNewPatientTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildPatientsTab() {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pregnant_woman, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppStrings.get('no_patients_found', lang), style: GoogleFonts.poppins(fontSize: 18, color: AppTheme.textMedium)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final name = profile['patient_name']?.toString() ?? '';
        final display = name.isEmpty ? AppStrings.get('unknown', lang) : name;
        final code = profile['profile_code'];
        final lmp = profile['lmp_date'];
        final week = _service.calculateGestationalWeek(lmp);
        final trimester = _service.calculateTrimester(week);
        final edd = _service.calculateEDD(lmp);
        final daysLeft = _service.calculateDaysToEDD(lmp);
        final risk = profile['risk_level'];

        Color riskColor = AppTheme.triageGreen;
        String riskText = AppStrings.get('normal', lang);
        if (risk == 'HIGH') {
          riskColor = AppTheme.triageRed;
          riskText = AppStrings.get('high_risk', lang);
        } else if (risk == 'MEDIUM') {
          riskColor = AppTheme.triageYellow;
          riskText = AppStrings.get('medium_risk', lang);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyDetailScreen(profile: profile, service: _service)))
                .then((_) => _loadData());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(display, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: riskColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(riskText, style: GoogleFonts.poppins(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(code, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                Text('${AppStrings.get('week_prefix', lang)} $week', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                Text(trimester, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('${AppStrings.get('delivery_date', lang)} ${edd.toIso8601String().split('T').first}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                Text('$daysLeft ${AppStrings.get('days_left', lang)}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewPatientTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: NewPatientForm(workerName: _workerName, service: _service, onSaved: _loadData),
    );
  }
}

class NewPatientForm extends StatefulWidget {
  final String workerName;
  final PregnancyService service;
  final VoidCallback onSaved;

  const NewPatientForm({super.key, required this.workerName, required this.service, required this.onSaved});

  @override
  State<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends State<NewPatientForm> {
  final _nameCtrl = TextEditingController();
  DateTime? _lmpDate;
  int _selectedAge = 25;

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lmpDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.get('patient_name_optional', lang), style: GoogleFonts.poppins(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),

        Text(AppStrings.get('age', lang), style: GoogleFonts.poppins(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [20, 25, 30, 35, 40].map((age) {
            final isSel = _selectedAge == age;
            return GestureDetector(
              onTap: () => setState(() => _selectedAge = age),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(age == 20 ? '<20' : (age == 40 ? '35+' : '${age-4}-$age'), style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Text(AppStrings.get('lmp_date_label', lang), style: GoogleFonts.poppins(color: Colors.white70)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: 16),
                Text(_lmpDate == null ? AppStrings.get('select_date', lang) : _lmpDate!.toIso8601String().split('T').first, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (_lmpDate != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.triageGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.triageGreen)),
            child: Column(
              children: [
                Text('सप्ताह ${_widgetService.calculateGestationalWeek(_lmpDate!.toIso8601String())}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_widgetService.calculateTrimester(_widgetService.calculateGestationalWeek(_lmpDate!.toIso8601String())), style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('EDD: ${_widgetService.calculateEDD(_lmpDate!.toIso8601String()).toIso8601String().split('T').first}', style: GoogleFonts.poppins(color: AppTheme.triageGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        SizedBox(
          height: 72,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _lmpDate == null ? null : () async {
              await widget.service.createProfile(widget.workerName, _nameCtrl.text, _lmpDate!.toIso8601String(), _selectedAge);
              widget.onSaved();
              DefaultTabController.of(context).animateTo(0);
            },
            child: Text(AppStrings.get('create_profile', lang), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
  
  PregnancyService get _widgetService => widget.service;
}

class PregnancyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final PregnancyService service;

  const PregnancyDetailScreen({super.key, required this.profile, required this.service});

  @override
  State<PregnancyDetailScreen> createState() => _PregnancyDetailScreenState();
}

class _PregnancyDetailScreenState extends State<PregnancyDetailScreen> {
  final Set<int> _selectedSigns = {};
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    final lmp = widget.profile['lmp_date'];
    final week = widget.service.calculateGestationalWeek(lmp);
    String triKey = '1';
    if (week > 12 && week <= 27) triKey = '2';
    if (week > 27) triKey = '3';

    final hindiSigns = PregnancyService.DANGER_SIGNS_HINDI[triKey]!;
    final engSigns = PregnancyService.DANGER_SIGNS_ENGLISH[triKey]!;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(widget.profile['patient_name'] ?? AppStrings.get('unknown', lang), style: GoogleFonts.poppins(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.get('danger_signs', lang), style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(hindiSigns.length, (index) {
              final isSel = _selectedSigns.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSel) _selectedSigns.remove(index);
                    else _selectedSigns.add(index);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.triageRed.withOpacity(0.2) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? AppTheme.triageRed : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(isSel ? Icons.check_box : Icons.check_box_outline_blank, color: isSel ? AppTheme.triageRed : Colors.white54, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang == 'en' ? engSigns[index] : hindiSigns[index], style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                hintText: AppStrings.get('notes_optional', lang),
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 72,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  List<String> present = _selectedSigns.map((i) => engSigns[i]).toList();
                  await widget.service.recordVisit(widget.profile['profile_code'], present, _notesCtrl.text, null, week);
                  
                  if (!context.mounted) return;
                  
                  final risk = widget.service.assessRisk(present, week);
                  if (risk == 'HIGH') {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Icon(Icons.warning_amber, color: AppTheme.triageRed, size: 64),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('⚠ उच्च जोखिम — तुरंत रेफर करें', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          Text('⚠ High Risk — Refer Immediately', style: GoogleFonts.poppins(color: Colors.white70), textAlign: TextAlign.center),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }, child: Text('OK', style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 18)))
                      ],
                    ));
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(AppStrings.get('record_visit', lang), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
