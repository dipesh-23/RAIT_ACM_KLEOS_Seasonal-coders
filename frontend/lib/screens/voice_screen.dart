import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../services/audio_recorder_service.dart';
import '../services/whisper_service.dart';
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
  bool _isProcessingAI = false;



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
    // Dispose recorder only when needed; we keep instance for reuse
    // (no changes needed here)
    super.dispose();
  }

  // Toggle between voice recording and manual typing
  bool _isManual = false;
  final _textController = TextEditingController();

  Future<void> _toggleRecording() async {
    if (_isManual) {
      // Switch back to voice mode
      setState(() {
        _isManual = false;
        _liveText = '';
        _textController.clear();
      });
      return;
    }

    final lang = context.read<TriageProvider>().selectedLanguage;
    final localeMap = {'hi': 'hi', 'mr': 'mr', 'en': 'en', 'te': 'te'};
    final sttLocale = localeMap[lang] ?? 'hi';

    if (!_isRecording) {
      final hasPerm = await AudioRecorderService.instance.initRecorder();
      if (!hasPerm) return;

      setState(() => _isRecording = true);
      context.read<TriageProvider>().setRecording(true);
      await AudioRecorderService.instance.startRecording();
    } else {
      setState(() {
        _isRecording = false;
        _isProcessingAI = true;
      });
      context.read<TriageProvider>().setRecording(false);

      final path = await AudioRecorderService.instance.stopRecording();
      if (path != null) {
        final result = await WhisperService.instance.transcribe(path, expectedLanguage: sttLocale);
        if (result != null) {
          setState(() {
            _liveText = result['text'] ?? '';
            _isProcessingAI = false;
            _textController.text = _liveText;
          });
        } else {
          setState(() => _isProcessingAI = false);
        }
      } else {
        setState(() => _isProcessingAI = false);
      }
    }
  }

  void _proceed() {
    if (_isManual) {
      final manualText = _textController.text.trim();
      if (manualText.isNotEmpty) {
        context.read<TriageProvider>().updateTranscription(manualText);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TranscriptionScreen()),
        );
      }
    } else {
      if (_liveText.isNotEmpty) {
        context.read<TriageProvider>().updateTranscription(_liveText);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TranscriptionScreen()),
        );
      }
    }
  }

  void _retry() {
    setState(() {
      _liveText = '';
      _isRecording = false;
      _isProcessingAI = false;
      _isManual = false;
      _textController.clear();
    });
    AudioRecorderService.instance.stopRecording();
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
                  _isManual
                    ? Text(AppStrings.get('type_instruction', lang),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))
                    : Text(AppStrings.get('speak_instruction', lang),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  _isManual
                    ? Container()
                    : Text(AppStrings.get('describe_symptoms', lang),
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w400)),

                  const SizedBox(height: 50),

                  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isRecording) ...[
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
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _isRecording
                                          ? const LinearGradient(colors: [Color(0xFF5B4FCF), Color(0xFF9B8FFF)])
                                          : const LinearGradient(colors: [Color(0xFF333355), Color(0xFF222244)]),
                                      boxShadow: _isRecording
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primary.withOpacity(0.5),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: _isManual ? AppStrings.get('switch_to_voice', lang) : AppStrings.get('switch_to_keyboard', lang),
                          icon: Icon(_isManual ? Icons.mic_rounded : Icons.keyboard_rounded, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isManual = !_isManual;
                              if (_isManual) {
                                if (_isRecording) {
                                  _isRecording = false;
                                  AudioRecorderService.instance.stopRecording();
                                }
                                _textController.text = _liveText;
                              } else {
                                _liveText = '';
                                _textController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  Text(
                    _isProcessingAI 
                        ? AppStrings.get('processing', lang) 
                        : (_isRecording ? AppStrings.get('listening', lang) : AppStrings.get('press_mic', lang)),
                    style: GoogleFonts.poppins(
                        color: _isRecording ? AppTheme.primaryLight : Colors.white38,
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

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
                  _isManual
                      ? TextField(
                          controller: _textController,
                          maxLines: null,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: AppStrings.get('type_here', lang),
                            hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 15),
                            border: InputBorder.none,
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 60),
                          child: _isProcessingAI
                              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
                              : (_liveText.isEmpty
                                  ? Text(AppStrings.get('words_placeholder', lang),
                                      style: GoogleFonts.poppins(
                                          color: Colors.white24, fontSize: 14, fontStyle: FontStyle.italic))
                                  : RichText(
                                      text: TextSpan(
                                        children: _buildHighlightedText(_liveText),
                                      ),
                                    )),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                      onPressed: (_isManual ? _textController.text.isNotEmpty : _liveText.isNotEmpty) ? _proceed : null,
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
      return [TextSpan(text: text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15))];
  }
}
