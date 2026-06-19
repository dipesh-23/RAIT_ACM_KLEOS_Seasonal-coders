import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/triage_engine.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  int _currentIndex = 0;
  bool _showingSafetyNet = false;
  bool _isRunningTriage = false;

  static const String _safetyNetQuestion =
      'क्या मरीज की हालत आपको बहुत गंभीर लग रही है?';

  Future<void> _answer(bool yes) async {
    final provider = context.read<TriageProvider>();
    final concepts = provider.detectedConcepts;

    if (_showingSafetyNet) {
      // Safety net answered
      if (yes) provider.setSafetyNet(true);
      await _runAndNavigate(provider);
      return;
    }

    // Answer for current concept
    if (_currentIndex < concepts.length) {
      provider.confirmConcept(concepts[_currentIndex].conceptKey, yes);
    }

    if (_currentIndex + 1 >= concepts.length) {
      // All concepts answered — show safety net
      setState(() => _showingSafetyNet = true);
    } else {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _runAndNavigate(TriageProvider provider) async {
    setState(() => _isRunningTriage = true);
    await provider.runTriage(TriageEngine.instance);
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/result', (route) => route.settings.name == '/session-start');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final concepts = provider.detectedConcepts;
    final total = concepts.length + 1; // +1 for safety net

    String question;
    int displayIndex;
    Color accentColor;

    if (_showingSafetyNet) {
      question = _safetyNetQuestion;
      displayIndex = total;
      accentColor = AppColors.yellowAlert;
    } else if (concepts.isEmpty) {
      // Edge case: no concepts detected — jump straight to safety net
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showingSafetyNet = true);
      });
      question = _safetyNetQuestion;
      displayIndex = 1;
      accentColor = AppColors.yellowAlert;
    } else {
      question = concepts[_currentIndex].hindiQuestion;
      displayIndex = _currentIndex + 1;
      accentColor = _categoryColor(concepts[_currentIndex].category);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _isRunningTriage
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 20),
                    Text('परिणाम तैयार हो रहा है...',
                        style: AppTextStyles.hindiBody),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'प्रश्न $displayIndex / $total',
                          style: AppTextStyles.hindiSmall,
                        ),
                        _buildProgressDots(displayIndex, total),
                      ],
                    ),

                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: displayIndex / total,
                      backgroundColor: AppColors.surface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),

                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_showingSafetyNet)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowAlert
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.yellowAlert
                                          .withOpacity(0.4)),
                                ),
                                child: Text(
                                  '⚠️ सुरक्षा जांच',
                                  style: AppTextStyles.hindiSmall.copyWith(
                                      color: AppColors.yellowAlert),
                                ),
                              )
                            else if (!concepts[_currentIndex].category
                                .isEmpty) ...[
                              _categoryBadge(
                                  concepts[_currentIndex].category),
                            ],
                            const SizedBox(height: 20),
                            Text(
                              question,
                              style: AppTextStyles.hindiHeading,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Answer buttons
                    ElevatedButton(
                      style: AppTheme.yesButtonStyle(),
                      onPressed: () => _answer(true),
                      child: const Text('✓  हाँ'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: AppTheme.noButtonStyle(),
                      onPressed: () => _answer(false),
                      child: const Text('✗  नहीं'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'RED':
        return AppColors.redAlert;
      case 'YELLOW':
        return AppColors.yellowAlert;
      default:
        return AppColors.greenAlert;
    }
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _categoryColor(category).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _categoryColor(category).withOpacity(0.4)),
      ),
      child: Text(
        category == 'RED'
            ? '🔴 गंभीर लक्षण'
            : category == 'YELLOW'
                ? '🟡 सावधानी'
                : '🟢 हल्का',
        style:
            AppTextStyles.hindiSmall.copyWith(color: _categoryColor(category)),
      ),
    );
  }

  Widget _buildProgressDots(int current, int total) {
    return Row(
      children: List.generate(
        total,
        (i) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < current
                ? AppColors.primary
                : AppColors.surface,
          ),
        ),
      ),
    );
  }
}
