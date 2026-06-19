import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/stt_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final SttService _stt = SttService();
  bool _isListening = false;
  String _partialText = '';
  String _finalText = '';
  String _status = 'माइक दबाएं और लक्षण बोलें';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stt.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stopListening();
      setState(() {
        _isListening = false;
        _status = 'समझ रहा है...';
      });
      _pulseController.stop();
      _pulseController.reset();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _status = 'माइक दबाएं और लक्षण बोलें';
        });
      }
    } else {
      final ok = await _stt.initialize();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('माइक उपलब्ध नहीं है')),
          );
        }
        return;
      }
      setState(() {
        _isListening = true;
        _partialText = '';
        _status = 'सुन रहा है...';
      });
      _pulseController.repeat(reverse: true);

      await _stt.startListening(
        localeId: 'hi_IN',
        onResult: (text) {
          if (mounted) {
            setState(() {
              _finalText = text;
              _partialText = text;
              _isListening = false;
              _status = 'माइक दबाएं और लक्षण बोलें';
            });
            _pulseController.stop();
            _pulseController.reset();
          }
        },
        onPartialResult: (text) {
          if (mounted) {
            setState(() => _partialText = text);
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _status = 'माइक दबाएं और लक्षण बोलें';
            });
            _pulseController.stop();
            _pulseController.reset();
          }
        },
      );
    }
  }

  void _reRecord() {
    setState(() {
      _finalText = '';
      _partialText = '';
      _status = 'माइक दबाएं और लक्षण बोलें';
    });
  }

  void _proceed() {
    final text = _finalText.isNotEmpty ? _finalText : _partialText;
    if (text.isEmpty) return;
    context.read<TriageProvider>().setRawTranscript(text);
    Navigator.of(context).pushNamed('/transcription');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final hasText = _finalText.isNotEmpty || _partialText.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Patient summary bar
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surface,
              child: Text(
                '${_ageHindi(provider.ageGroup)}  •  ${_durHindi(provider.duration)}',
                style: AppTextStyles.hindiSmall,
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mic button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, child) => Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? AppColors.redAlert
                              : AppColors.buttonColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? AppColors.redAlert
                                      : AppColors.buttonColor)
                                  .withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Status
                  Text(
                    _status,
                    style: _isListening
                        ? AppTextStyles.hindiBody
                            .copyWith(color: AppColors.redAlert)
                        : AppTextStyles.hindiBody,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Live transcript
                  if (hasText)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _partialText.isNotEmpty
                              ? _partialText
                              : _finalText,
                          style: AppTextStyles.hindiBody,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(0, 64),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _reRecord,
                      child: Text('दोबारा बोलें',
                          style: AppTextStyles.hindiBody),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasText
                            ? AppColors.buttonColor
                            : AppColors.surface,
                        foregroundColor: hasText
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        minimumSize: const Size(0, 64),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: hasText ? 4 : 0,
                        textStyle: AppTextStyles.hindiButton,
                      ),
                      onPressed: hasText ? _proceed : null,
                      child: const Text('आगे बढ़ें'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ageHindi(String ag) {
    switch (ag) {
      case 'NEWBORN':
        return 'नवजात';
      case 'CHILD':
        return 'बच्चा';
      case 'ADULT':
        return 'वयस्क';
      case 'ELDERLY':
        return 'बुजुर्ग';
      default:
        return ag;
    }
  }

  String _durHindi(String d) {
    switch (d) {
      case 'TODAY':
        return 'आज';
      case 'TWO_THREE_DAYS':
        return '2-3 दिन';
      case 'FOUR_PLUS_DAYS':
        return '4+ दिन';
      default:
        return d;
    }
  }
}
