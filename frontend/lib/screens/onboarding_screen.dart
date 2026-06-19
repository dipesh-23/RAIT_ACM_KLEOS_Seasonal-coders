import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/onboarding_service.dart';
import '../services/stt_service.dart';
import '../providers/triage_provider.dart';
import 'session_start_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isChecking = false;
  OfflineModelStatus _status = OfflineModelStatus.unknown;
  bool _showEnglish = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  String _getLocaleForLang(String langCode) {
    if (langCode == 'hi') return 'hi_IN';
    if (langCode == 'mr') return 'mr_IN';
    return 'en_IN';
  }

  String _getDisplayLang(String langCode) {
    if (langCode == 'hi') return 'हिंदी / Hindi';
    if (langCode == 'mr') return 'मराठी / Marathi';
    return 'English';
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    final langCode = context.read<TriageProvider>().selectedLanguage;
    final localeId = _getLocaleForLang(langCode);

    _status = await SttService.instance.isLocaleAvailable(localeId);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (_status == OfflineModelStatus.available) {
      await OnboardingService.instance.completeOnboarding('ASHA कार्यकर्ता', language: langCode);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SessionStartScreen()),
      );
    }
  }

  Future<void> _runManualCheck() async {
    if (_isChecking) return;
    await _checkStatus();
    if (!mounted) return;

    if (_status != OfflineModelStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _showEnglish ? "Model still not found. Please download." : "मॉडल अभी भी नहीं मिला। कृपया डाउनलोड करें।",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildStatusCard(String title, OfflineModelStatus status) {
    IconData icon;
    Color iconColor;
    String statusText;

    switch (status) {
      case OfflineModelStatus.available:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = _showEnglish ? "Ready" : "तैयार है";
        break;
      case OfflineModelStatus.offlineModelMissing:
        icon = Icons.warning;
        iconColor = Colors.orange;
        statusText = _showEnglish ? "Offline model needed" : "ऑफ़लाइन मॉडल चाहिए";
        break;
      case OfflineModelStatus.languagePackMissing:
        icon = Icons.error;
        iconColor = Colors.red;
        statusText = _showEnglish ? "Language pack needed" : "भाषा पैक चाहिए";
        break;
      case OfflineModelStatus.unknown:
      default:
        icon = Icons.help;
        iconColor = Colors.grey;
        statusText = _showEnglish ? "Checking..." : "जांच हो रही है...";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(color: iconColor, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    if (_status == OfflineModelStatus.available || _status == OfflineModelStatus.unknown) {
      return const SizedBox.shrink();
    }

    bool needsLanguagePack = _status == OfflineModelStatus.languagePackMissing;
    final langCode = context.read<TriageProvider>().selectedLanguage;
    final displayLang = _getDisplayLang(langCode).split(' / ').last; // "Hindi", "Marathi", "English"
    final displayLangLocal = _getDisplayLang(langCode).split(' / ')[0]; // "हिंदी", "मराठी", "English"

    String title;
    List<String> steps;

    if (needsLanguagePack) {
      if (_showEnglish) {
        title = "How to install language pack";
        steps = [
          "1. Tap 'Language Settings' button below",
          "2. Tap 'Add a language'",
          "3. Search and install '$displayLang'",
          "4. Come back and tap 'Check Again'",
        ];
      } else {
        title = "भाषा पैक कैसे इंस्टॉल करें";
        steps = [
          "1. नीचे 'भाषा सेटिंग्स' बटन दबाएं",
          "2. 'Add a language' चुनें",
          "3. '$displayLangLocal' खोजें और इंस्टॉल करें",
          "4. वापस आएं और 'जांचें' दबाएं",
        ];
      }
    } else {
      // Offline model missing
      if (_showEnglish) {
        title = "How to enable offline speech";
        steps = [
          "1. Tap 'Open Google Settings' below",
          "2. LONG PRESS on '$displayLang' to make it Primary",
          "3. Wait for the model to download (if needed)",
          "4. Come back and tap 'Check Again'",
        ];
      } else {
        title = "ऑफलाइन मॉडल कैसे चालू करें";
        steps = [
          "1. नीचे 'Google सेटिंग्स' बटन दबाएं",
          "2. '$displayLang' पर LONG PRESS करके उसे Primary बनाएं",
          "3. डाउनलोड पूरा होने दें",
          "4. वापस आकर 'जांचें' बटन दबाएं",
        ];
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  step,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2230),
        border: const Border(left: BorderSide(color: Color(0xFFF9A825), width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _showEnglish
            ? "⚠ Note: Internet is required once to download the model.\nAfter downloading, the app works fully offline."
            : "⚠ ध्यान दें: डाउनलोड के लिए एक बार इंटरनेट चाहिए।\nडाउनलोड के बाद ऐप पूरी तरह ऑफलाइन काम करेगा।",
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<TriageProvider>().selectedLanguage;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ASHA Triage",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C2230),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _showEnglish = !_showEnglish;
                        });
                      },
                      child: Text(
                        _showEnglish ? "हिंदी" : "English",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatusCard(_getDisplayLang(langCode), _status),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                     child: Column(
                      children: [
                        _buildInstructions(),
                        _buildNoteBox(),
                      ],
                    ),
                  ),
                ),
                if (_isChecking)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (_status == OfflineModelStatus.languagePackMissing) {
                          await OnboardingService.instance.openSpeechSettings();
                        } else {
                          await OnboardingService.instance.openGoogleOfflineSpeechSettings();
                        }
                      },
                      child: Text(
                        _showEnglish ? "📥  Open Google Settings" : "📥  Google सेटिंग्स खोलें",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C2230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _runManualCheck,
                      child: Text(
                        _showEnglish ? "🔄  Check Again — Model found?" : "🔄  जांचें — मॉडल मिला?",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
