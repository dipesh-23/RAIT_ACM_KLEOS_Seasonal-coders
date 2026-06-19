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

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _answer(BuildContext context, bool value) async {
    final provider = context.read<TriageProvider>();
    provider.answerConfirmation(value);
    final done = provider.nextConfirmationStep();

    if (done) {
      // Compute triage
      setState(() {});
      provider.computeFinalTriage();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen()));
    } else {
      // Animate to next question
      _slideCtrl.reset();
      _slideCtrl.forward();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriageProvider>();
    final total = provider.confirmationQuestions.length;
    final current = provider.confirmationStep;
    final progress = (current + 1) / total;
    final lang = provider.selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header with Progress ──
            Container(
              color: AppTheme.bgWhite,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      Text('${AppStrings.get('question_prefix', lang)} ${current + 1}/$total',
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Warning Icon ──
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFC107).withOpacity(0.4),
                              width: 2),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFF57F17), size: 42),
                      ),

                      const SizedBox(height: 28),

                      // ── Question ──
                      Text(
                        provider.currentQuestion,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: AppTheme.textDark, fontSize: 20,
                            fontWeight: FontWeight.w700, height: 1.4),
                      ),

                      const SizedBox(height: 12),

                      Text(AppStrings.get('pay_attention', lang),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textLight, fontSize: 13)),

                      const Spacer(),

                      // ── YES Button ──
                      GestureDetector(
                        onTap: () => _answer(context, true),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: AppTheme.redGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.triageRed.withOpacity(0.35),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(AppStrings.get('yes_severe', lang),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── NO Button ──
                      GestureDetector(
                        onTap: () => _answer(context, false),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.bgWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.borderColor, width: 1.5),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded,
                                  color: AppTheme.textMedium, size: 22),
                              const SizedBox(width: 10),
                              Text(AppStrings.get('no_normal', lang),
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textMedium, fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Step Dots ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(total, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: i == current ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == current ? AppTheme.primary
                                : (i < current ? AppTheme.primaryLight.withOpacity(0.4)
                                    : AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
