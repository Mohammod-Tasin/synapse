/// Synapse — Neuro-Minimalist Application Theme
/// Design Philosophy: Calm, soft, rounded, generous whitespace.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color Palette ────────────────────────────────────────────────────────
  /// Neural Blue — primary, soft & trustworthy
  static const Color primaryColor = Color(0xFF4A90B8);

  /// Cortex Green — secondary, calm teal
  static const Color secondaryColor = Color(0xFF5BA89A);

  /// Soft Periwinkle — accent for interactive elements
  static const Color accentColor = Color(0xFF7B9CE1);

  /// Off-white background
  static const Color backgroundColor = Color(0xFFF7F8FA);

  /// Pure white surface
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Soft rose for errors
  static const Color errorColor = Color(0xFFD9534F);

  /// Calm green for success
  static const Color successColor = Color(0xFF3DAA88);

  /// Deep calm slate for primary text
  static const Color textPrimaryColor = Color(0xFF1A2332);

  /// Muted slate for secondary text
  static const Color textSecondaryColor = Color(0xFF7A8CA0);

  /// Very soft border
  static const Color borderColor = Color(0xFFE8EEF4);

  /// Light input fill
  static const Color inputFillColor = Color(0xFFEFF4FB);

  /// Soft warning amber
  static const Color warningColor = Color(0xFFF0A84A);

  // ─── Gradient ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A90B8), Color(0xFF7B9CE1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    colors: [Color(0xFFEEF4FB), Color(0xFFE8F5F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Spacing ──────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Border Radius ────────────────────────────────────────────────────────
  static const double radiusXs = 8.0;
  static const double radiusSm = 14.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 28.0;
  static const double radiusXl = 36.0;
  static const double radiusPill = 100.0;

  // ─── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF4A90B8).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.7),
      blurRadius: 6,
      offset: const Offset(-2, -2),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A2332).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get tileShadow => [
    BoxShadow(
      color: const Color(0xFF1A2332).withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 8,
      offset: const Offset(-3, -3),
    ),
  ];

  // ─── Box Decorations ──────────────────────────────────────────────────────
  static BoxDecoration softCard({
    Color? color,
    double? radius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
      boxShadow: shadows ?? cardShadow,
    );
  }

  // ─── Typography ───────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.2,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.3,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
    letterSpacing: 0.5,
  );

  // ─── Input Decoration ─────────────────────────────────────────────────────
  static InputDecoration buildInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textSecondaryColor, size: 20)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: 18,
      ),
      labelStyle: GoogleFonts.poppins(
        color: textSecondaryColor,
        fontSize: 13,
      ),
      hintStyle: GoogleFonts.poppins(
        color: textSecondaryColor.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      errorStyle: GoogleFonts.poppins(
        color: errorColor,
        fontSize: 11,
      ),
    );
  }

  // ─── Full Theme ───────────────────────────────────────────────────────────
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      cardColor: surfaceColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          color: textSecondaryColor,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          color: textSecondaryColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 15,
          ),
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: textPrimaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFB0BEC5),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : const Color(0xFFE0E8F0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
