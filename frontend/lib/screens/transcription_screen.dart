import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/triage_engine.dart';
import '../services/embedding_service.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  bool _isAnalyzing = false;

  Future<void> _analyze() async {
    final provider = context.read<TriageProvider>();
    setState(() => _isAnalyzing = true);

    try {
      if (!EmbeddingService.instance.isInitialized) {
        await EmbeddingService.instance.initialize();
      }
      if (!TriageEngine.instance.isInitialized) {
        await TriageEngine.instance.initialize();
      }

      final concepts = await TriageEngine.instance.analyzeText(
        provider.rawTranscript,
        provider.ageGroup,
        provider.duration,
      );
      provider.setDetectedConcepts(concepts);

      if (mounted) {
        Navigator.of(context).pushNamed('/confirmation');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('विश्लेषण में त्रुटि। पुनः प्रयास करें।')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('समीक्षा करें')),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('यह सुना गया:', style: AppTextStyles.hindiSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          provider.rawTranscript.isEmpty
                              ? '(कोई आवाज़ नहीं सुनी गई)'
                              : provider.rawTranscript,
                          style: AppTextStyles.hindiBody,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: const Size(0, 64),
                            side:
                                const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isAnalyzing
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('दोबारा बोलें'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: AppTheme.primaryButtonStyle().copyWith(
                            minimumSize: const WidgetStatePropertyAll(
                                Size(0, 64)),
                          ),
                          onPressed: _isAnalyzing ? null : _analyze,
                          child: const Text('सही है, आगे बढ़ें'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isAnalyzing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text('विश्लेषण हो रहा है...',
                          style: AppTextStyles.hindiBody),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
