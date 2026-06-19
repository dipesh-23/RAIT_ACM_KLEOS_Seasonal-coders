import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  final _nameController = TextEditingController();
  String _selectedAge = '';
  String _selectedDuration = '';

  final List<Map<String, String>> _ageGroups = [
    {'key': 'NEWBORN', 'label': 'नवजात', 'sub': '0-28 दिन'},
    {'key': 'CHILD', 'label': 'बच्चा', 'sub': '1 माह - 12 वर्ष'},
    {'key': 'ADULT', 'label': 'वयस्क', 'sub': '13-60 वर्ष'},
    {'key': 'ELDERLY', 'label': 'बुजुर्ग', 'sub': '60+ वर्ष'},
  ];

  final List<Map<String, String>> _durations = [
    {'key': 'TODAY', 'label': 'आज'},
    {'key': 'TWO_THREE_DAYS', 'label': '2-3 दिन'},
    {'key': 'FOUR_PLUS_DAYS', 'label': '4+ दिन'},
  ];

  bool get _canStart =>
      _nameController.text.trim().isNotEmpty &&
      _selectedAge.isNotEmpty &&
      _selectedDuration.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    final provider = context.read<TriageProvider>();
    provider.setWorkerName(_nameController.text.trim());
    provider.setAgeGroup(_selectedAge);
    provider.setDuration(_selectedDuration);
    Navigator.of(context).pushNamed('/voice');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('नया मरीज'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Worker name
              Text('आपका नाम', style: AppTextStyles.hindiSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: AppTextStyles.hindiBody,
                decoration: const InputDecoration(
                  hintText: 'अपना नाम लिखें',
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 28),

              // Age group
              Text('मरीज की उम्र', style: AppTextStyles.hindiSmall),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: _ageGroups.map((ag) {
                  final selected = _selectedAge == ag['key'];
                  return ElevatedButton(
                    style: AppTheme.selectionButtonStyle(selected: selected),
                    onPressed: () =>
                        setState(() => _selectedAge = ag['key']!),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ag['label']!,
                            style: AppTextStyles.hindiTitle),
                        Text(ag['sub']!,
                            style: AppTextStyles.hindiSmall
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Duration
              Text('लक्षण कब से हैं?', style: AppTextStyles.hindiSmall),
              const SizedBox(height: 12),
              Row(
                children: _durations.map((d) {
                  final selected = _selectedDuration == d['key'];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: d == _durations.last ? 0 : 12),
                      child: ElevatedButton(
                        style: AppTheme.selectionButtonStyle(
                            selected: selected),
                        onPressed: () =>
                            setState(() => _selectedDuration = d['key']!),
                        child: Text(d['label']!,
                            style: AppTextStyles.hindiTitle),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              // Start button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canStart
                      ? AppColors.buttonColor
                      : AppColors.surface,
                  foregroundColor: _canStart
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  minimumSize: const Size(double.infinity, 72),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: _canStart ? 4 : 0,
                  textStyle: AppTextStyles.hindiButton,
                ),
                onPressed: _canStart ? _start : null,
                child: const Text('शुरू करें →'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
