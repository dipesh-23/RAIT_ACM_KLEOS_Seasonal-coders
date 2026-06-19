import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/triage_provider.dart';
import '../utils/app_strings.dart';
import 'result_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  int index = 0;

  void _onAnswer(bool value) {
    final provider = context.read<TriageProvider>();
    final concepts = provider.detectedConcepts;

    if (index < concepts.length) {
      provider.confirmationAnswers[index] = value;
      concepts[index].confirmed = value;
      setState(() {
        index++;
      });
    } else {
      // Safety net answered
      provider.safetyNetTriggered = value;
      provider.scoreAndNavigate();
    }
  }

  Widget _buildBody(BuildContext context, TriageProvider provider, List<dynamic> concepts) {
    final lang = provider.selectedLanguage;

    if (index >= concepts.length) {
      // Show full screen safety net question
      return Scaffold(
        backgroundColor: AppTheme.bgPage,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.get('safety_net_q', lang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () => _onAnswer(true),
                    child: Text(
                      AppStrings.get('yes', lang),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () => _onAnswer(false),
                    child: Text(
                      AppStrings.get('no', lang),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Standard question with progress indicator
    final total = concepts.length;
    final progress = (index + 1) / total;
    final currentQuestionText = concepts[index].getQuestionForLang(lang);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Container(
              color: AppTheme.bgWhite,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (index > 0) {
                            setState(() => index--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.bgPage,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.textDark, size: 16),
                        ),
                      ),
                      const Spacer(),
                      Text('${AppStrings.get('question_prefix', lang)} ${index + 1}/$total',
                          style: GoogleFonts.poppins(
                              color: AppTheme.primary, fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentQuestionText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () => _onAnswer(true),
                        child: Text(
                          AppStrings.get('yes', lang),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () => _onAnswer(false),
                        child: Text(
                          AppStrings.get('no', lang),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final concepts = provider.detectedConcepts;

    return Stack(
      children: [
        _buildBody(context, provider, concepts),
        Consumer<TriageProvider>(
          builder: (context, prov, child) {
            if (prov.currentResult != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ResultScreen()),
                  );
                }
              });
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
