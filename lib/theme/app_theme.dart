/// Synapse — Ultra-Minimalist "Premium Calm" Application Theme
/// Design Philosophy: Monochromatic, flat, highly legible, calm.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color Palette (Premium Calm) ─────────────────────────────────────────

  /// Slate Blue — Primary accent, used sparingly (e.g., active elements)
  static const Color primaryColor = Color(0xFF475569);

  /// Soft Teal — Secondary accent, subtle
  static const Color secondaryColor = Color(0xFF0F766E);

  /// Muted Indigo — Tertiary accent
  static const Color accentColor = Color(0xFF6366F1);

  /// Pure White — Main scaffold background (Letting it breathe)
  static const Color backgroundColor = Color(0xFFFFFFFF);

  /// Pure White — Cards & Surfaces (Merged with background visually, using borders)
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Soft Rose for errors
  static const Color errorColor = Color(0xFFEF4444);

  /// Soft Green for success
  static const Color successColor = Color(0xFF10B981);

  /// Deep Slate — Primary text (Never pure black)
  static const Color textPrimaryColor = Color(0xFF1E293B);

  /// Soft Grey — Secondary text/subtitles
  static const Color textSecondaryColor = Color(0xFF64748B);

  /// Very Light Grey Border — Used to define boundaries instead of shadows
  static const Color borderColor = Color(0xFFF1F5F9);

  /// Softer Border — For slightly more contrast
  static const Color borderColorStrong = Color(0xFFE2E8F0);

  /// Light input fill (Extremely subtle off-white)
  static const Color inputFillColor = Color(0xFFF8FAFC);

  /// Muted Amber
  static const Color warningColor = Color(0xFFF59E0B);

  // ─── Gradient (Muted/Removed) ─────────────────────────────────────────────
  // We keep the definitions to avoid breaking existing code, but make them flat/subtle.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColor],
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    colors: [surfaceColor, surfaceColor],
  );

  // ─── Generous Whitespace (Doubled/Increased) ──────────────────────────────
  static const double spacingXs = 8.0;
  static const double spacingSm = 16.0;
  static const double spacingMd = 24.0;
  static const double spacingLg = 32.0;
  static const double spacingXl = 48.0;
  static const double spacingXxl = 64.0;

  // ─── Border Radius (Smooth, elegant) ──────────────────────────────────────
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusPill = 100.0;

  // ─── Shadows (Barely Visible) ─────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get tileShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Box Decorations (Flat & Bordered) ────────────────────────────────────
  static BoxDecoration softCard({
    Color? color,
    double? radius,
    List<BoxShadow>? shadows,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
      boxShadow: shadows ?? softShadow,
      border: showBorder ? Border.all(color: borderColorStrong, width: 1.0) : null,
    );
  }

  // ─── Premium Typography (Inter) ─────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 28, // Reduced
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.2,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 20, // Reduced
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.3,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400, // Regular
        color: textSecondaryColor,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        letterSpacing: 0.3,
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
          ? Icon(prefixIcon, color: textSecondaryColor.withValues(alpha: 0.7), size: 18)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColorStrong, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColorStrong, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: 18,
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textSecondaryColor.withValues(alpha: 0.5),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.inter(
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
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondaryColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textSecondaryColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd), // Smooth instead of pill
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500, // Medium instead of SemiBold
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 16,
          ),
          side: const BorderSide(color: borderColorStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColorStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColorStrong),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400, color: textPrimaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderColorStrong),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF94A3B8), // Slate 400
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : const Color(0xFFF1F5F9), // Slate 100
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : const Color(0xFFE2E8F0), // Slate 200
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColorStrong),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor, // Deep slate background
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
