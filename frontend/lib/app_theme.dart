import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ──────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF5B4FCF);
  static const Color primaryLight = Color(0xFF7B6FE8);
  static const Color primaryDark  = Color(0xFF3D33A6);
  static const Color accent       = Color(0xFF6C63FF);

  static const Color bgPage       = Color(0xFFF4F6FF);
  static const Color bgWhite      = Color(0xFFFFFFFF);
  static const Color bgCard       = Color(0xFFFFFFFF);

  static const Color triageRed    = Color(0xFFE53935);
  static const Color triageYellow = Color(0xFFFFC107);
  static const Color triageGreen  = Color(0xFF43A047);

  static const Color textDark     = Color(0xFF1A1A2E);
  static const Color textMedium   = Color(0xFF555577);
  static const Color textLight    = Color(0xFF9898B2);
  static const Color textHint     = Color(0xFFBBBBCC);

  static const Color borderColor  = Color(0xFFE8E8F0);
  static const Color divider      = Color(0xFFF0F0F8);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B4FCF), Color(0xFF9B8FFF)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B4FCF), Color(0xFF7B6FE8)],
  );

  static const LinearGradient cardPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFFF6B6B)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
  );

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF5B4FCF).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFF5B4FCF).withOpacity(0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── ThemeData ────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPage,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
            color: textDark, fontSize: 32, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.poppins(
            color: textDark, fontSize: 26, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(
            color: textDark, fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.poppins(
            color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(
            color: textDark, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(
            color: textMedium, fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.poppins(
            color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
            color: textDark, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(color: textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgWhite,
        selectedColor: primary,
        side: const BorderSide(color: borderColor),
        labelStyle: GoogleFonts.poppins(color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgWhite,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }

  // ─── Reusable Widget Helpers ─────────────────────────────────────────────
  static Widget gradientButton({
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
    IconData? icon,
    double? width,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient ?? primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: buttonShadow,
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  static Widget sectionTitle(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(
            color: textDark, fontSize: 16, fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel, style: GoogleFonts.poppins(
                color: primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}
