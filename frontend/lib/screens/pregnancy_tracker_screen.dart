import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/database_service.dart';
import '../services/pregnancy_service.dart';
import '../main.dart';

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
}

class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];

  // Register Form States
  final _nameController = TextEditingController();
  DateTime? _selectedLmpDate;
  String _selectedAgeBracket = '20-25';

  final List<String> _ageBrackets = ['<20', '20-25', '26-30', '31-35', '35+'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final activeProfiles = await DatabaseService.instance.getActivePregnancyProfiles();
    setState(() {
      _profiles = activeProfiles;
      _isLoading = false;
    });
  }

  Future<void> _selectLmpDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedLmpDate = picked;
      });
    }
  }

  Future<void> _registerProfile(String lang) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedLmpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'hi' ? 'कृपया सभी फ़ील्ड भरें' : 'Please fill all fields',
          ),
        ),
      );
      return;
    }

    final code = 'PRG-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final lmpStr = _selectedLmpDate!.toIso8601String();
    
    // Evaluate initial risk
    final metrics = PregnancyService.instance.calculateGestationalMetrics(lmpStr);
    final gestationalWeek = metrics['week'] as int? ?? 0;
    final riskLevel = PregnancyService.instance.evaluateRiskLevel(
      gestationalWeek: gestationalWeek,
      selectedDangerSigns: [],
    );

    int ageVal = 22;
    if (_selectedAgeBracket == '<20') ageVal = 18;
    if (_selectedAgeBracket == '26-30') ageVal = 28;
    if (_selectedAgeBracket == '31-35') ageVal = 33;
    if (_selectedAgeBracket == '35+') ageVal = 38;

    final row = {
      'profile_code': code,
      'worker_name': 'ASHA Worker',
      'patient_name': name,
      'lmp_date': lmpStr,
      'age_years': ageVal,
      'visit_count': 0,
      'last_visit_date': '',
      'risk_level': riskLevel,
      'notes': 'Age bracket: $_selectedAgeBracket',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    };

    await DatabaseService.instance.insertPregnancyProfile(row);
    
    _nameController.clear();
    setState(() {
      _selectedLmpDate = null;
      _selectedAgeBracket = '20-25';
    });

    _tabController.animateTo(0);
    _loadProfiles();
  }

  void _openCheckinScreen(Map<String, dynamic> profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PregnancyCheckinScreen(
          profile: profile,
          onComplete: _loadProfiles,
        ),
      ),
    );
  }

  String getRiskLabel(String risk, String lang) {
    switch (risk) {
      case 'HIGH': return lang == 'hi' ? 'उच्च जोखिम' : 'High Risk';
      case 'MEDIUM': return lang == 'hi' ? 'मध्यम जोखिम' : 'Medium Risk';
      case 'LOW': default: return lang == 'hi' ? 'सामान्य' : 'Low Risk';
    }
  }

  String getTrimesterLabel(String trimester, String lang) {
    switch (trimester) {
      case 'FIRST': return lang == 'hi' ? 'पहला तिमाही' : 'First Trimester';
      case 'SECOND': return lang == 'hi' ? 'दूसरा तिमाही' : 'Second Trimester';
      case 'THIRD': default: return lang == 'hi' ? 'तीसरा तिमाही' : 'Third Trimester';
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
          lang == 'hi' ? 'गर्भावस्था ट्रैकर' : 'Pregnancy Tracker',
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
            Tab(text: lang == 'hi' ? 'सक्रिय सूची' : 'Active List'),
            Tab(text: lang == 'hi' ? 'नया पंजीकरण' : 'New Register'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active List
                _buildActiveListTab(lang),
                // Tab 2: New Registration Form
                _buildRegistrationFormTab(lang),
              ],
            ),
    );
  }

  Widget _buildActiveListTab(String lang) {
    if (_profiles.isEmpty) {
      return Center(
        child: Text(
          lang == 'hi' ? 'कोई पंजीकृत मरीज नहीं' : 'No registered patients',
          style: GoogleFonts.poppins(color: AppTheme.textLight),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final riskKey = profile['risk_level'] as String? ?? 'LOW';
        final isHighRisk = riskKey == 'HIGH';
        final isMediumRisk = riskKey == 'MEDIUM';

        Color badgeColor = AppTheme.triageGreen;
        if (isHighRisk) badgeColor = AppTheme.triageRed;
        if (isMediumRisk) badgeColor = AppTheme.triageYellow;

        final metrics = PregnancyService.instance.calculateGestationalMetrics(profile['lmp_date']);
        final week = metrics['week'] ?? 0;
        final trimesterKey = metrics['trimester'] ?? 'FIRST';
        final trimesterLabel = getTrimesterLabel(trimesterKey, lang);

        return Card(
          elevation: 0,
          color: AppTheme.bgWhite,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
          ),
          child: InkWell(
            onTap: () => _openCheckinScreen(profile),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        profile['patient_name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          getRiskLabel(riskKey, lang),
                          style: GoogleFonts.poppins(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'hi'
                        ? 'कोड: ${profile['profile_code']} | आयु: ${profile['age_years']} वर्ष'
                        : 'Code: ${profile['profile_code']} | Age: ${profile['age_years']} Years',
                    style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang == 'hi'
                        ? 'गर्भधारण अवधि: $week सप्ताह | तिमाही: $trimesterLabel'
                        : 'Gestation: $week Weeks | Trimester: $trimesterLabel',
                    style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'hi'
                            ? 'जांच संख्या: ${profile['visit_count']}'
                            : 'Check-ups: ${profile['visit_count']}',
                        style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        lang == 'hi' ? 'चेक-अप शुरू करें  →' : 'Start Check-up  →',
                        style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegistrationFormTab(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Name
          Text(
            lang == 'hi' ? 'मरीज का नाम' : 'Patient Name',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              hintText: lang == 'hi' ? 'नाम दर्ज करें...' : 'Enter patient name...',
              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),

          // LMP Date Picker
          Text(
            lang == 'hi' ? 'अंतिम मासिक धर्म की तारीख (LMP)' : 'Last Menstrual Period (LMP)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectLmpDate(context),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bgWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _selectedLmpDate == null
                        ? (lang == 'hi' ? 'तारीख चुनें' : 'Select Date')
                        : '${_selectedLmpDate!.day}/${_selectedLmpDate!.month}/${_selectedLmpDate!.year}',
                    style: GoogleFonts.poppins(
                      color: _selectedLmpDate == null ? AppTheme.textHint : AppTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Age Bracket Cards
          Text(
            lang == 'hi' ? 'आयु वर्ग' : 'Age Bracket',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: _ageBrackets.map((bracket) {
              final isSelected = _selectedAgeBracket == bracket;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAgeBracket = bracket;
                      });
                    },
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.borderColor,
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? AppTheme.buttonShadow : AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          bracket,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : AppTheme.textMedium,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          // Register Action Button (Min 72px)
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton.icon(
              onPressed: () => _registerProfile(lang),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
              label: Text(
                lang == 'hi' ? 'पंजीकरण करें' : 'Register Profile',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== INTERACTIVE CHECKOUT DANGER SIGNS CHECKLIST =====
class PregnancyCheckinScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onComplete;

  const PregnancyCheckinScreen({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  @override
  State<PregnancyCheckinScreen> createState() => _PregnancyCheckinScreenState();
}

class _PregnancyCheckinScreenState extends State<PregnancyCheckinScreen> {
  final List<String> _selectedDangerSigns = [];
  final _visitNotesController = TextEditingController();
  bool _referred = false;

  @override
  void dispose() {
    _visitNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckin(String lang) async {
    final metrics = PregnancyService.instance.calculateGestationalMetrics(widget.profile['lmp_date']);
    final gestationalWeek = metrics['week'] as int? ?? 0;

    // Evaluate Risk Level dynamically
    final newRiskLevel = PregnancyService.instance.evaluateRiskLevel(
      gestationalWeek: gestationalWeek,
      selectedDangerSigns: _selectedDangerSigns,
    );

    final visitRow = {
      'profile_code': widget.profile['profile_code'],
      'visit_date': DateTime.now().toIso8601String(),
      'gestational_week': gestationalWeek,
      'triage_session_code': 'VIS-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      'danger_signs_present': _selectedDangerSigns.join('|'),
      'visit_notes': _visitNotesController.text.trim(),
      'referred': _referred ? 1 : 0,
    };

    await DatabaseService.instance.addPregnancyVisit(visitRow);
    await DatabaseService.instance.updatePregnancyRisk(widget.profile['profile_code'], newRiskLevel);

    widget.onComplete();

    if (mounted) {
      final riskLabel = newRiskLevel == 'HIGH'
          ? (lang == 'hi' ? 'उच्च जोखिम' : 'High Risk')
          : (newRiskLevel == 'MEDIUM' ? (lang == 'hi' ? 'मध्यम जोखिम' : 'Medium Risk') : (lang == 'hi' ? 'सामान्य' : 'Low Risk'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'hi' ? 'जांच डेटा सहेज लिया गया: $riskLabel' : 'Check-up visit saved: $riskLabel',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<TriageProvider>(context).selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgWhite,
        elevation: 1,
        title: Text(
          lang == 'hi' ? 'स्वास्थ्य जांच' : 'Check-up Visit',
          style: GoogleFonts.poppins(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile['patient_name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang == 'hi'
                        ? 'पंजीकरण कोड: ${widget.profile['profile_code']}'
                        : 'Profile Code: ${widget.profile['profile_code']}',
                    style: GoogleFonts.poppins(color: AppTheme.textMedium, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger signs checklist title
            Text(
              lang == 'hi' ? 'खतरे के लक्षण (चेकलिस्ट)' : 'Danger Signs Checklist',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Checklist Grid (minimum 72px high tap-only options)
            Column(
              children: PregnancyService.dangerSigns.map((signKey) {
                final isChecked = _selectedDangerSigns.contains(signKey);
                final signText = PregnancyService.dangerSignsLocalized[signKey]?[lang] ?? signKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _selectedDangerSigns.remove(signKey);
                        } else {
                          _selectedDangerSigns.add(signKey);
                        }
                      });
                    },
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isChecked ? AppTheme.triageRed.withOpacity(0.08) : AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isChecked ? AppTheme.triageRed : AppTheme.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isChecked ? AppTheme.triageRed : AppTheme.textLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              signText,
                              style: GoogleFonts.poppins(
                                color: isChecked ? AppTheme.triageRed : AppTheme.textMedium,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Referral Action Button Grid
            Text(
              lang == 'hi' ? 'क्या अस्पताल रेफरल की आवश्यकता है?' : 'Is hospital referral required?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _referred = true),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: _referred ? AppTheme.triageRed : AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _referred ? Colors.transparent : AppTheme.borderColor, width: 1.5),
                        boxShadow: _referred ? AppTheme.buttonShadow : AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          lang == 'hi' ? 'हाँ' : 'YES',
                          style: GoogleFonts.poppins(
                            color: _referred ? Colors.white : AppTheme.textMedium,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _referred = false),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: !_referred ? AppTheme.primary : AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: !_referred ? Colors.transparent : AppTheme.borderColor, width: 1.5),
                        boxShadow: !_referred ? AppTheme.buttonShadow : AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          lang == 'hi' ? 'नहीं' : 'NO',
                          style: GoogleFonts.poppins(
                            color: !_referred ? Colors.white : AppTheme.textMedium,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              lang == 'hi' ? 'जांच विवरण टिप्पणी' : 'Visit Notes',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _visitNotesController,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                hintText: lang == 'hi' ? 'विवरण लिखें...' : 'Write details...',
              ),
            ),
            const SizedBox(height: 48),

            // Submit checkin button (72px)
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton.icon(
                onPressed: () => _submitCheckin(lang),
                icon: const Icon(Icons.save_rounded, size: 24),
                label: Text(
                  lang == 'hi' ? 'जांच डेटा सहेजें' : 'Save Check-up Data',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
