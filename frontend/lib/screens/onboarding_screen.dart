import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingService _service = OnboardingService();
  bool _checking = true;
  bool _hindiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkHindi();
  }

  Future<void> _checkHindi() async {
    final available = await _service.isHindiLanguagePackAvailable();
    if (!mounted) return;
    setState(() {
      _hindiAvailable = available;
      _checking = false;
    });
    if (available) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _proceed();
    }
  }

  Future<void> _proceed() async {
    await _service.markOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed('/session-start');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.health_and_safety,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'ASHA ट्राइएज',
                style: AppTextStyles.hindiLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ग्रामीण स्वास्थ्य सहायक',
                style: AppTextStyles.hindiSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              if (_checking)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'हिंदी भाषा पैक की जांच हो रही है...',
                      style: AppTextStyles.hindiBody,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (!_hindiAvailable) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.yellowAlert, width: 1),
                  ),
                  child: Text(
                    'कृपया हिंदी भाषा पैक डाउनलोड करें, फिर वापस आएं।',
                    style: AppTextStyles.hindiBody,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: AppTheme.primaryButtonStyle(),
                  onPressed: () => _service.openLanguageSettings(),
                  icon: const Icon(Icons.download, size: 28),
                  label: const Text('हिंदी भाषा डाउनलोड करें'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _proceed,
                  child: Text('जारी रखें',
                      style: AppTextStyles.hindiBody),
                ),
              ] else
                Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.greenAlert, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'हिंदी उपलब्ध है। शुरू हो रहा है...',
                      style: AppTextStyles.hindiBody,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
