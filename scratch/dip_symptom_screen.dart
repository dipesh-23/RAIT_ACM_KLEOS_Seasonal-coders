import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/custom_keyboard.dart';

/// A clean, full-screen symptom typing screen with a custom in-app keyboard.
/// Returned value: the typed text (String) via Navigator.pop.
class SymptomTextInputScreen extends StatefulWidget {
  final String language;
  final String initialText;

  const SymptomTextInputScreen({
    super.key,
    required this.language,
    this.initialText = '',
  });

  @override
  State<SymptomTextInputScreen> createState() =>
      _SymptomTextInputScreenState();
}

class _SymptomTextInputScreenState
    extends State<SymptomTextInputScreen> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    // Position cursor at end of any pre-filled text
    if (widget.initialText.isNotEmpty) {
      _ctrl.selection = TextSelection.collapsed(
          offset: widget.initialText.length);
    }
    // Grab focus so cursor is visible — readOnly: true prevents system IME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    final title = lang == 'en'
        ? 'Type Symptoms'
        : lang == 'mr'
            ? 'लक्षणे टाइप करा'
            : 'लक्षण टाइप करें';

    final placeholder = lang == 'en'
        ? 'Start typing symptoms using\nthe keyboard below…'
        : lang == 'mr'
            ? 'खालील कीबोर्डवरून लक्षणे टाइप करा…'
            : 'नीचे दिए कीबोर्ड से लक्षण टाइप करें…';

    final doneLabel = lang == 'en' ? 'Done' : 'पूर्ण';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        resizeToAvoidBottomInset: false, // keyboard is in-app
        body: SafeArea(
          child: Column(
            children: [
              // ─────────────────── Header ────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D1A),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1A1A30), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Back
                    _iconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    // Word count pill
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _ctrl,
                      builder: (_, val, __) {
                        final wc = _wordCount(val.text);
                        return AnimatedOpacity(
                          opacity: wc > 0 ? 1 : 0.3,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$wc ${lang == "en" ? "words" : "शब्द"}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Done button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _ctrl,
                      builder: (_, val, __) {
                        final ok = val.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: ok ? _submit : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: ok
                                  ? AppTheme.primary
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  doneLabel,
                                  style: GoogleFonts.poppins(
                                      color:
                                          ok ? Colors.white : Colors.white24,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.check_rounded,
                                    color: ok ? Colors.white : Colors.white24,
                                    size: 15),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ─────────────────── Text display area ─────────────────────────
              Expanded(
                child: GestureDetector(
                  // tapping anywhere in the area keeps focus
                  onTap: () => _focus.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _ctrl,
                        builder: (_, val, __) {
                          if (val.text.isEmpty) {
                            return Text(
                              placeholder,
                              style: GoogleFonts.notoSans(
                                color: Colors.black38,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                height: 1.8,
                              ),
                            );
                          }
                          // Show the typed text; TextField with readOnly keeps
                          // the cursor visible without triggering system IME.
                          return TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            readOnly: true,
                            showCursor: true,
                            maxLines: null,
                            style: GoogleFonts.notoSans(
                              color: Colors.black,
                              fontSize: 16,
                              height: 1.8,
                            ),
                            cursorColor: const Color(0xFF5B4FCF),
                            cursorWidth: 2.5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ─────────────────── Custom keyboard ───────────────────────────
              CustomKeyboard(
                controller: _ctrl,
                language: widget.language,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
