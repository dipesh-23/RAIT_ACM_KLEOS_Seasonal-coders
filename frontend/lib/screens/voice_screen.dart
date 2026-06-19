import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as Math;
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/stt_service.dart';
import '../utils/app_strings.dart';
import 'transcription_screen.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;

  String _liveText = '';
  bool _isRecording = false;
  StreamSubscription<String>? _sttSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _sttSub?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    final lang = context.read<TriageProvider>().selectedLanguage;
    final localeMap = {'hi': 'hi-IN', 'mr': 'mr-IN', 'en': 'en-IN'};
    final sttLocale = localeMap[lang] ?? 'hi-IN';

    setState(() => _isRecording = !_isRecording);
    context.read<TriageProvider>().setRecording(_isRecording);

    if (_isRecording) {
      _liveText = '';
      _sttSub?.cancel();
      _sttSub = SttService.instance.transcriptStream.listen((text) {
        setState(() => _liveText = text);
      });
      SttService.instance.startListening(locale: sttLocale);
    } else {
      _sttSub?.cancel();
      SttService.instance.stopListening();
    }
  }

  void _proceed() {
    if (_liveText.isEmpty) return;
    context.read<TriageProvider>().updateTranscription(_liveText);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TranscriptionScreen()),
    );
  }

  void _retry() {
    setState(() {
      _liveText = '';
      _isRecording = false;
    });
    _sttSub?.cancel();
    SttService.instance.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TriageProvider>().selectedLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // glare-reducing light background
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppStrings.get('voice_screen_title', lang),
                      style: GoogleFonts.poppins(
                        color: AppTheme.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Language selector is now exclusively in the drawer.
                ],
              ),
            ),

            // ── Center Focus Section ──
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prominent circular white mic button in subtle glow container
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft, subtle glow container
                            Container(
                              width: 140 * (_isRecording ? _pulseAnim.value : 1.0),
                              height: 140 * (_isRecording ? _pulseAnim.value : 1.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.06),
                              ),
                            ),
                            Container(
                              width: 116 * (_isRecording ? _pulseAnim.value : 1.0),
                              height: 116 * (_isRecording ? _pulseAnim.value : 1.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.09),
                              ),
                            ),
                            // Circular white microphone action button (minimum 96x96 px)
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.12),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  if (_isRecording)
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.24),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                color: AppTheme.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Headline instructions: strictly monolingual
                  Text(
                    lang == 'hi' ? "बोलिए" : "Talk",
                    style: GoogleFonts.poppins(
                      color: AppTheme.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRecording
                        ? AppStrings.get('listening', lang)
                        : AppStrings.get('press_mic', lang),
                    style: GoogleFonts.poppins(
                      color: _isRecording ? AppTheme.primary : AppTheme.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic multi-colored Bezier audio visualization curve
                  Container(
                    width: double.infinity,
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: WaveformPainter(
                            animationValue: _waveCtrl.value,
                            isRecording: _isRecording,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Transcription Box ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.get('live_transcription', lang),
                        style: GoogleFonts.poppins(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 70),
                    child: _liveText.isEmpty
                        ? Text(
                            "पांच साल का बच्चा, दो दिन से तेज बुखार...",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textLight.withOpacity(0.6),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              children: _buildHighlightedText(_liveText),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        AppStrings.get('rerecord', lang),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMedium,
                        side: BorderSide(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _liveText.isNotEmpty ? _proceed : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        AppStrings.get('continue_btn', lang),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedText(String text) {
    final words = text.split(' ');
    final urgentWords = ['बुखार', 'दर्द', 'तेज', 'गंभीर', 'सांस', 'बेहोश'];
    return words.map((w) {
      final isUrgent = urgentWords.any((u) => w.contains(u));
      return TextSpan(
        text: '$w ',
        style: GoogleFonts.poppins(
          color: isUrgent ? const Color(0xffD32F2F) : AppTheme.textDark,
          fontSize: 16,
          fontWeight: isUrgent ? FontWeight.bold : FontWeight.w500,
        ),
      );
    }).toList();
  }
}

// ── Custom Waveform Painter ──
class WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isRecording;

  WaveformPainter({required this.animationValue, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xffD32F2F), // crimson red
          Color(0xffF9A825), // amber yellow
          Color(0xff388E3C), // emerald green
          Color(0xff1565C0), // cobalt blue
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    path1.moveTo(0, midY);

    if (isRecording) {
      for (double x = 0; x <= width; x += 1) {
        final wave1 = Math.sin((x / width * 3 * Math.pi) + animationValue * 2 * Math.pi) * 18;
        final wave2 = Math.cos((x / width * 5 * Math.pi) - animationValue * 4 * Math.pi) * 8;
        final envelope = Math.sin(x / width * Math.pi);
        final y = midY + (wave1 + wave2) * envelope;
        path1.lineTo(x, y);
      }
    } else {
      for (double x = 0; x <= width; x += 1) {
        final envelope = Math.sin(x / width * Math.pi);
        final y = midY + Math.sin((x / width * 2 * Math.pi) + animationValue * 2 * Math.pi) * 2 * envelope;
        path1.lineTo(x, y);
      }
    }

    canvas.drawPath(path1, paint1);

    // Second overlapping wave for visual depth
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xff1565C0), // cobalt blue
          Color(0xff388E3C), // emerald green
          Color(0xffF9A825), // amber yellow
          Color(0xffD32F2F), // crimson red
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(0, midY);

    if (isRecording) {
      for (double x = 0; x <= width; x += 1) {
        final wave1 = Math.cos((x / width * 4 * Math.pi) - animationValue * 2 * Math.pi) * 12;
        final wave2 = Math.sin((x / width * 6 * Math.pi) + animationValue * 3 * Math.pi) * 6;
        final envelope = Math.sin(x / width * Math.pi);
        final y = midY + (wave1 + wave2) * envelope;
        path2.lineTo(x, y);
      }
    } else {
      for (double x = 0; x <= width; x += 1) {
        final envelope = Math.sin(x / width * Math.pi);
        final y = midY + Math.cos((x / width * 2 * Math.pi) - animationValue * 2 * Math.pi) * 1 * envelope;
        path2.lineTo(x, y);
      }
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isRecording != isRecording;
  }
}
