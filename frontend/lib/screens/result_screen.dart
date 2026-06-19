import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../app_theme.dart';
import '../models/triage_result.dart';
import '../providers/triage_provider.dart';
import '../services/tts_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeIn),
    );
    _flashController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TriageProvider>();
      if (provider.triageResult != null) {
        TtsService.instance.speakResult(provider.triageResult!.level);
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _flashController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  Color _bgColor(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return AppColors.redAlert;
      case TriageLevel.yellow:
        return AppColors.yellowAlert;
      case TriageLevel.green:
        return AppColors.greenAlert;
    }
  }

  IconData _icon(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return Icons.warning_rounded;
      case TriageLevel.yellow:
        return Icons.access_time_rounded;
      case TriageLevel.green:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final result = provider.triageResult;

    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bg = _bgColor(result.level);

    return FadeTransition(
      opacity: _flashAnimation,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session code
                Text(
                  'कोड: ${result.sessionCode}',
                  style: AppTextStyles.hindiSmall
                      .copyWith(color: Colors.white70),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_icon(result.level),
                          color: Colors.white, size: 96),
                      const SizedBox(height: 20),
                      Text(
                        result.levelHindi,
                        style: AppTextStyles.hindiLarge
                            .copyWith(fontSize: 40),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        result.hindiReason,
                        style: AppTextStyles.hindiBody
                            .copyWith(color: Colors.white.withOpacity(0.9)),
                        textAlign: TextAlign.center,
                      ),

                      // Confirmed symptoms list
                      if (result.confirmedConcepts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'पुष्ट लक्षण:',
                                style: AppTextStyles.hindiSmall
                                    .copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              ...result.confirmedConcepts.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          color: Colors.white, size: 8),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          c.hindiQuestion.replaceAll(
                                              'क्या मरीज ', ''),
                                          style: AppTextStyles.hindiBody
                                              .copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.95)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Referral slip button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bg,
                    minimumSize: const Size(double.infinity, 72),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    textStyle: AppTextStyles.hindiButton
                        .copyWith(color: bg),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/referral'),
                  child: const Text('रेफरल स्लिप बनाएं'),
                ),
                const SizedBox(height: 12),

                // New patient
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    provider.resetSession();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/session-start', (r) => false);
                  },
                  child: Text('नया मरीज →',
                      style: AppTextStyles.hindiBody
                          .copyWith(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
