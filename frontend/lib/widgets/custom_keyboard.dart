import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// In-app custom keyboard for Hindi (hi), Marathi (mr), and English (en).
/// Directly manipulates a [TextEditingController] — no system IME involved.
class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final String language; // 'hi' | 'mr' | 'en'

  const CustomKeyboard({
    super.key,
    required this.controller,
    required this.language,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  // 0 = consonants (or lowercase), 1 = vowels (or uppercase), 2 = numbers
  int _tab = 0;
  bool _caps = false;

  // ── Devanagari character sets ───────────────────────────────────────────────

  static const _consonants = [
    ['क', 'ख', 'ग', 'घ', 'च'],
    ['ज', 'झ', 'ट', 'ड', 'त'],
    ['थ', 'द', 'ध', 'न', 'प'],
    ['फ', 'ब', 'भ', 'म', 'य'],
    ['र', 'ल', 'व', 'श', 'स'],
    ['ह', 'ष', 'ड़', '्', '।'],
  ];

  static const _vowelsMatras = [
    ['अ', 'आ', 'इ', 'ई', 'उ'],
    ['ऊ', 'ए', 'ऐ', 'ओ', 'औ'],
    ['ा', 'ि', 'ी', 'ु', 'ू'],
    ['े', 'ै', 'ो', 'ौ', 'ं'],
    ['ः', 'ऋ', 'ृ', '़', ','],
    ['.', '?', '!', '–', '\''],
  ];

  static const _numbers = [
    ['1', '2', '3', '4', '5'],
    ['6', '7', '8', '9', '0'],
    ['+', '-', '×', '÷', '='],
    ['@', '#', '(', ')', '&'],
    [',', '.', '?', '!', "'"],
  ];

  // ── English QWERTY rows ─────────────────────────────────────────────────────

  static const _q1 = ['q','w','e','r','t','y','u','i','o','p'];
  static const _q2 = ['a','s','d','f','g','h','j','k','l'];
  static const _q3 = ['z','x','c','v','b','n','m'];

  // ── Text manipulation ───────────────────────────────────────────────────────

  void _type(String ch) {
    final c = widget.controller;
    final t = c.text;
    final sel = c.selection;
    final s = sel.isValid ? sel.start : t.length;
    final e = sel.isValid ? sel.end : t.length;
    c.value = TextEditingValue(
      text: t.replaceRange(s, e, ch),
      selection: TextSelection.collapsed(offset: s + ch.length),
    );
    if (_caps && widget.language == 'en') setState(() => _caps = false);
  }

  void _backspace() {
    final c = widget.controller;
    final t = c.text;
    if (t.isEmpty) return;
    final sel = c.selection;
    final s = sel.isValid ? sel.start : t.length;
    final e = sel.isValid ? sel.end : t.length;
    if (s != e) {
      c.value = TextEditingValue(
        text: t.replaceRange(s, e, ''),
        selection: TextSelection.collapsed(offset: s),
      );
    } else if (s > 0) {
      final before = t.substring(0, s);
      final runes = before.runes.toList();
      runes.removeLast();
      final nb = String.fromCharCodes(runes);
      c.value = TextEditingValue(
        text: nb + t.substring(s),
        selection: TextSelection.collapsed(offset: nb.length),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEn = widget.language == 'en';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A18),
        border: Border(top: BorderSide(color: Color(0xFF1E1E38), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEn) _tabBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
              child: isEn ? _buildEnglish() : _buildDeva(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab bar (Devanagari only) ───────────────────────────────────────────────

  Widget _tabBar() {
    const tabs = ['व्यंजन', 'स्वर', '123'];
    return Row(
      children: List.generate(3, (i) {
        final active = _tab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 36,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? const Color(0xFF7C6FFF) : const Color(0xFF1E1E38),
                    width: active ? 2.5 : 1,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i],
                style: GoogleFonts.poppins(
                  color: active ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Devanagari keyboard ─────────────────────────────────────────────────────

  Widget _buildDeva() {
    final rows = _tab == 0
        ? _consonants
        : _tab == 1
            ? _vowelsMatras
            : _numbers;
    return Column(
      children: [
        ...rows.map((r) => _row(r.map((ch) => _lk(ch)).toList())),
        _devaCtrlRow(),
      ],
    );
  }

  Widget _devaCtrlRow() => _row([
        _sk(label: 'Space', flex: 5, onTap: () => _type(' ')),
        _sk(label: '↵', flex: 2, onTap: () => _type('\n')),
        _bk(flex: 3),
      ]);

  // ── English QWERTY ──────────────────────────────────────────────────────────

  Widget _buildEnglish() {
    if (_tab == 2) {
      return Column(
        children: [
          ..._numbers.map((r) => _row(r.map((ch) => _lk(ch, fontSize: 14)).toList())),
          _row([
            _sk(label: 'ABC', flex: 2, onTap: () => setState(() => _tab = 0)),
            _sk(label: 'Space', flex: 5, onTap: () => _type(' ')),
            _bk(flex: 2),
          ]),
        ],
      );
    }

    List<String> apply(List<String> keys) =>
        _caps ? keys.map((k) => k.toUpperCase()).toList() : List.of(keys);

    return Column(
      children: [
        _row(apply(_q1).map((k) => _lk(k, fontSize: 13)).toList()),
        _row(apply(_q2).map((k) => _lk(k, fontSize: 13)).toList()),
        _row([
          _sk(
            icon: Icon(
              _caps ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
              color: _caps ? const Color(0xFF9B8FFF) : Colors.white38,
              size: 16,
            ),
            flex: 2,
            onTap: () => setState(() => _caps = !_caps),
          ),
          ...apply(_q3).map((k) => _lk(k, fontSize: 13)),
          _bk(flex: 2),
        ]),
        _row([
          _sk(label: '!#1', flex: 2, onTap: () => setState(() => _tab = 2)),
          _sk(label: 'Space', flex: 6, onTap: () => _type(' ')),
          _sk(
            icon: const Icon(Icons.keyboard_return_rounded,
                color: Colors.white54, size: 17),
            flex: 2,
            onTap: () => _type('\n'),
          ),
        ]),
      ],
    );
  }

  // ── Key builders ─────────────────────────────────────────────────────────────

  static const double _kh = 44; // key height
  static const _keyBg = Color(0xFF1C1C38);
  static const _specBg = Color(0xFF262650);

  Widget _row(List<Widget> keys) => SizedBox(
        height: _kh,
        child: Row(children: keys),
      );

  /// Letter / character key
  Widget _lk(String ch, {double fontSize = 16, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _type(ch),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _keyBg,
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 2)
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            ch,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: fontSize,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Special / action key (text label or icon)
  Widget _sk({
    String? label,
    Icon? icon,
    required VoidCallback onTap,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _specBg,
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 2)
            ],
          ),
          alignment: Alignment.center,
          child: icon ??
              Text(
                label ?? '',
                style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
        ),
      ),
    );
  }

  /// Backspace key with long-press to clear all
  Widget _bk({int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: _backspace,
        onLongPress: () => widget.controller.clear(),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _specBg,
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 2)
            ],
          ),
          alignment: Alignment.center,
          child:
              const Icon(Icons.backspace_outlined, color: Colors.white60, size: 18),
        ),
      ),
    );
  }
}
