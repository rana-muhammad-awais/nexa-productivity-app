import 'package:flutter/material.dart';

/// Nexora v4 design system — premium "liquid depth" aesthetic.
/// Deep navy-blacks, warm off-whites, curated semantic elevation,
/// tight tracking headers, and a multi-accent palette system.

class NexaColors {
  // ── Light Mode (Warm & Clean) ──
  static const lightBg = Color(0xFFFAFAF8);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardBorder = Color(0xFFE8E6E1);
  static const lightPrimary = Color(0xFF6366F1);
  static const lightText = Color(0xFF1A1A2E);
  static const lightTextSec = Color(0xFF78716C);
  static const lightBorder = Color(0xFFE7E5E4);

  // Surface elevation (Light)
  static const lightSurface0 = Color(0xFFFAFAF8); // deepest bg
  static const lightSurface1 = Color(0xFFFFFFFF); // cards
  static const lightSurface2 = Color(0xFFF5F5F0); // elevated overlays
  static const lightSurface3 = Color(0xFFEFEDE8); // popovers

  // ── Dark Mode (Navy-Black Luxury) ──
  static const darkBg = Color(0xFF0A0A12);
  static const darkCard = Color(0xFF12121E);
  static const darkCardBorder = Color(0xFF1E1E30);
  static const darkPrimary = Color(0xFF818CF8);
  static const darkText = Color(0xFFF5F5F7);
  static const darkTextSec = Color(0xFF8E8EA0);
  static const darkBorder = Color(0xFF1C1C2E);

  // Surface elevation (Dark)
  static const darkSurface0 = Color(0xFF0A0A12); // deepest bg
  static const darkSurface1 = Color(0xFF12121E); // cards
  static const darkSurface2 = Color(0xFF1A1A2A); // elevated overlays
  static const darkSurface3 = Color(0xFF222236); // popovers

  // ── Semantic ──
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF06B6D4);

  // ── Shimmer / skeleton ──
  static const shimmerBaseDark = Color(0xFF141422);
  static const shimmerHighlightDark = Color(0xFF1E1E30);
  static const shimmerBaseLight = Color(0xFFECEAE5);
  static const shimmerHighlightLight = Color(0xFFF5F3EE);

  // ── Priority ──
  static const priorityLow = Color(0xFF60A5FA);
  static const priorityMedium = Color(0xFF34D399);
  static const priorityHigh = Color(0xFFFBBF24);
  static const priorityUrgent = Color(0xFFF43F5E);

  // ── Expense categories (HSL-tuned, high-vibrancy) ──
  static const catFood = Color(0xFFFF6B35);
  static const catTransport = Color(0xFF8B5CF6);
  static const catBills = Color(0xFFEF4444);
  static const catShopping = Color(0xFFEC4899);
  static const catEntertainment = Color(0xFF06B6D4);
  static const catHealth = Color(0xFF10B981);
  static const catEducation = Color(0xFF3B82F6);
  static const catGroceries = Color(0xFF84CC16);
  static const catRent = Color(0xFFF97316);
  static const catSalary = Color(0xFF14B8A6);
  static const catInvestment = Color(0xFFA78BFA);
  static const catOther = Color(0xFF64748B);

  // ── Note accent colors ──
  static const noteDefault = Color(0x00000000);
  static const noteBlue = Color(0xFF3B82F6);
  static const notePurple = Color(0xFF8B5CF6);
  static const noteGreen = Color(0xFF10B981);
  static const noteOrange = Color(0xFFFF6B35);
  static const notePink = Color(0xFFEC4899);
  static const noteYellow = Color(0xFFFBBF24);
  static const noteTeal = Color(0xFF14B8A6);

  // ── Premium brand gradients ──
  static const gradPrimary = [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFC084FC)];
  static const gradWarm = [Color(0xFFFF6B35), Color(0xFFEF4444)];
  static const gradCool = [Color(0xFF06B6D4), Color(0xFF6366F1)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF14B8A6)];
  static const gradFocus = [Color(0xFF8B5CF6), Color(0xFFC084FC)];
  static const gradSunrise = [Color(0xFFFF6B35), Color(0xFFFBBF24)];
  static const gradOcean = [Color(0xFF06B6D4), Color(0xFF3B82F6)];
  static const gradKhata = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gradKhataGreen = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradKhataRed = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const gradAurora = [Color(0xFF6366F1), Color(0xFF06B6D4), Color(0xFF10B981)];
  static const gradRose = [Color(0xFFEC4899), Color(0xFFF43F5E)];
  static const gradAmber = [Color(0xFFF59E0B), Color(0xFFEF4444)];

  // ── Navbar glow ──
  static const navGlowDark = Color(0xFF6366F1);
  static const navGlowLight = Color(0xFF818CF8);

  // ── Category → color mapping ──
  static const Map<String, Color> categoryColors = {
    'food': catFood,
    'transport': catTransport,
    'bills': catBills,
    'shopping': catShopping,
    'entertainment': catEntertainment,
    'health': catHealth,
    'education': catEducation,
    'groceries': catGroceries,
    'rent': catRent,
    'salary': catSalary,
    'investment': catInvestment,
    'other': catOther,
  };

  static Color priorityColor(String p) => switch (p) {
        'low' => priorityLow,
        'medium' => priorityMedium,
        'high' => priorityHigh,
        'urgent' => priorityUrgent,
        _ => priorityMedium,
      };

  static Color categoryColor(String c) => categoryColors[c] ?? catOther;

  static Color noteColor(String? c) => switch (c) {
        'blue' => noteBlue,
        'purple' => notePurple,
        'green' => noteGreen,
        'orange' => noteOrange,
        'pink' => notePink,
        'yellow' => noteYellow,
        'teal' => noteTeal,
        _ => noteDefault,
      };

  /// Dynamic gradient based on user accent choice
  static List<Color> accentGradient(String? accent) => switch (accent) {
        'emerald' => gradSuccess,
        'cyan' => gradCool,
        'rose' => gradRose,
        'amber' => gradSunrise,
        'violet' => gradFocus,
        _ => gradPrimary,
      };
}

ThemeData buildLightTheme([String? accent]) => _theme(Brightness.light, accent);
ThemeData buildDarkTheme([String? accent]) => _theme(Brightness.dark, accent);

ThemeData _theme(Brightness b, [String? accent]) {
  final dark = b == Brightness.dark;
  final baseGrad = NexaColors.accentGradient(accent);
  final primary = baseGrad[0];
  final bg = dark ? NexaColors.darkBg : NexaColors.lightBg;
  final surface = dark ? NexaColors.darkCard : NexaColors.lightCard;
  final onSurface = dark ? NexaColors.darkText : NexaColors.lightText;
  final border = dark ? NexaColors.darkBorder : NexaColors.lightBorder;

  final scheme = ColorScheme(
    brightness: b,
    primary: primary,
    onPrimary: Colors.white,
    secondary: baseGrad[1],
    onSecondary: Colors.white,
    tertiary: baseGrad.length > 2 ? baseGrad[2] : baseGrad[1],
    onTertiary: Colors.white,
    surface: surface,
    onSurface: onSurface,
    error: NexaColors.danger,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: _input(border, surface, dark, primary),
    textTheme: _textTheme(onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.8,
      ),
      iconTheme: IconThemeData(color: onSurface),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface1,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(
        color: dark ? NexaColors.darkBorder : NexaColors.lightBorder,
        width: 1.5,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? NexaColors.darkSurface3 : NexaColors.lightText,
      contentTextStyle: TextStyle(
        color: dark ? NexaColors.darkText : Colors.white,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

InputDecorationTheme _input(Color border, Color surface, bool dark, Color primary) {
  return InputDecorationTheme(
    filled: true,
    fillColor: dark
        ? Colors.white.withOpacity(0.04)
        : const Color(0xFFF5F3EE),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: dark ? NexaColors.darkTextSec : NexaColors.lightTextSec,
    ),
    hintStyle: TextStyle(
      fontSize: 13,
      color: dark
          ? NexaColors.darkTextSec.withOpacity(0.6)
          : NexaColors.lightTextSec.withOpacity(0.6),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: dark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2DED8),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: NexaColors.danger, width: 1.2),
    ),
  );
}

TextTheme _textTheme(Color onSurface) => TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        color: onSurface,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: onSurface,
        height: 1.15,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: onSurface,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: onSurface,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: onSurface.withOpacity(0.65),
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: onSurface.withOpacity(0.5),
      ),
    );

// ── Helpers ──
bool isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;
Color primaryColor(BuildContext ctx) => Theme.of(ctx).colorScheme.primary;
Color surfaceColor(BuildContext ctx) => Theme.of(ctx).colorScheme.surface;
Color textPrimaryColor(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;
Color textSecondaryColor(BuildContext ctx) =>
    isDark(ctx) ? NexaColors.darkTextSec : NexaColors.lightTextSec;
Color borderColor(BuildContext ctx) =>
    isDark(ctx) ? NexaColors.darkBorder : NexaColors.lightBorder;
Color backgroundColor(BuildContext ctx) => Theme.of(ctx).scaffoldBackgroundColor;
Color surfaceElevated(BuildContext ctx) =>
    isDark(ctx) ? NexaColors.darkSurface2 : NexaColors.lightSurface2;
Color surfacePopover(BuildContext ctx) =>
    isDark(ctx) ? NexaColors.darkSurface3 : NexaColors.lightSurface3;
