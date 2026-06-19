import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
        MaterialPageRoute(builder: (_) => const TranscriptionScreen()));
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
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(AppStrings.get('voice_screen_title', lang),
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            // ── Center Section ──
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Instruction text
                  Text(AppStrings.get('speak_instruction', lang), style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700)),
                  Text(AppStrings.get('describe_symptoms', lang),
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 18,
                          fontWeight: FontWeight.w400)),

                  const SizedBox(height: 50),

                  // Pulse Mic Button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isRecording) ...[
                              // Outer rings
                              Container(
                                width: 160 * _pulseAnim.value,
                                height: 160 * _pulseAnim.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.12),
                                ),
                              ),
                              Container(
                                width: 130 * _pulseAnim.value,
                                height: 130 * _pulseAnim.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.18),
                                ),
                              ),
                            ],
                            // Main button
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _isRecording
                                    ? const LinearGradient(
                                        colors: [Color(0xFF5B4FCF), Color(0xFF9B8FFF)])
                                    : const LinearGradient(
                                        colors: [Color(0xFF333355), Color(0xFF222244)]),
                                boxShadow: _isRecording ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.5),
                                    blurRadius: 30, spreadRadius: 5,
                                  ),
                                ] : [],
                              ),
                              child: Icon(
                                _isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white, size: 44),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    _isRecording ? AppStrings.get('listening', lang) : AppStrings.get('press_mic', lang),
                    style: GoogleFonts.poppins(
                        color: _isRecording ? AppTheme.primaryLight : Colors.white38,
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // ── Live Transcription Panel ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          color: AppTheme.primaryLight, size: 16),
                      const SizedBox(width: 6),
                      Text(AppStrings.get('live_transcription', lang),
                          style: GoogleFonts.poppins(
                              color: AppTheme.primaryLight, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 60),
                    child: _liveText.isEmpty
                        ? Text(AppStrings.get('words_placeholder', lang),
                            style: GoogleFonts.poppins(
                                color: Colors.white24, fontSize: 14,
                                fontStyle: FontStyle.italic))
                        : RichText(
                            text: TextSpan(
                              children: _buildHighlightedText(_liveText),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Action Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(AppStrings.get('rerecord', lang),
                          style: GoogleFonts.poppins(fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _liveText.isNotEmpty ? _proceed : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(AppStrings.get('continue_btn', lang),
                          style: GoogleFonts.poppins(fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
          color: isUrgent ? const Color(0xFFFF8A80) : Colors.white,
          fontSize: 15,
          fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }).toList();
  }
}
