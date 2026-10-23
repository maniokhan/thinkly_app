import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // 1. Strict Matte Black Palette
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF121214);
  static const Color raisedSurface = Color(0xFF1A1A1D);
  static const Color hairlineBorder = Color(0xFF26262A);
  static const Color primaryText = Color(0xFFEDEDED);
  static const Color secondaryText = Color(0xFF8A8A92);

  // 2. The Single Accent: Electric Lime (Used ONLY for primary actions & active states)
  static const Color accent = Color(0xFFD4FF3A);
  static const Color accentText = Color(0xFF0A0A0B);

  // 3. Destructive / Error
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveBg = Color(0xFF1C1315);

  // 4. Subtle Status (Only for live mic / exam priority)
  static const Color statusLive = Color(0xFF10B981);
  static const Color statusAmber = Color(0xFFF59E0B);

  // Legacy & Alias Mappings (Ensuring zero breaks across models, debate arena & canvas)
  static const Color primary = accent;
  static const Color primaryDark = accentDark;
  static const Color primaryLight = accent;
  static const Color secondary = accent;
  static const Color surfaceElevated = raisedSurface;
  static const Color accentDark = Color(0xFF98CC00);
  static const Color accentDim = Color(0x22C6FF00);
  static const Color success = statusLive;
  static const Color warning = statusAmber;
  static const Color error = destructive;
  static const Color coral = destructive;

  static const Color card = surface;
  static const Color cardRoot = raisedSurface;
  static const Color cardElevated = raisedSurface;
  static const Color pillTag = raisedSurface;
  static const Color border = hairlineBorder;
  static const Color borderSubtle = hairlineBorder;
  static const Color borderRoot = hairlineBorder;
  static const Color borderSelected = accent;
  static const Color borderLight = hairlineBorder;
  static const Color dotGrid = Color(0xFF151518);
  static const Color alabaster = primaryText;
  static const Color alabasterText = background;
  static const Color graphiteBtn = raisedSurface;
  static const Color graphiteBtnBorder = hairlineBorder;

  static const Color textPrimary = primaryText;
  static const Color textSecondary = secondaryText;
  static const Color textMuted = secondaryText;
  static const Color textPill = primaryText;

  static const Color emerald = statusLive;
  static const Color teal = accent;
  static const Color amber = statusAmber;
  static const Color rose = destructive;
  static const Color cyan = accent;
  static const Color purple = secondaryText;
  static const Color indigo = accent;
  static const Color indigoDark = surface;

  static const Color accentEmerald = statusLive;
  static const Color accentTeal = accent;
  static const Color accentAmber = statusAmber;
  static const Color accentRose = destructive;
  static const Color accentCyan = accent;
  static const Color accentViolet = secondaryText;
  static const Color accentIndigo = accent;

  // Node Category Colors on Canvas (Matte Black with hairline borders)
  static const Color nodeRoot = primaryText;
  static const Color nodeConcept = secondaryText;
  static const Color nodeDefinition = primaryText;
  static const Color nodeExample = primaryText;
  static const Color nodeQuestion = destructive;
  static const Color nodeImportant = statusAmber;
  static const Color nodeStudentNote = accent;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double full = 999.0;

  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}

class AppTypography {
  static const String fontHeading = 'SpaceGrotesk';
  static const String fontBody = 'IBMPlexSans';
  static const String fontMono = 'JetBrainsMono';

  // Headings (Space Grotesk, tight letter-spacing: -0.5 to -1.0)
  static const TextStyle display = TextStyle(
    fontFamily: fontHeading,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: AppColors.primaryText,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    color: AppColors.primaryText,
    height: 1.25,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontHeading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.primaryText,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontHeading,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.primaryText,
    height: 1.3,
  );

  // Body (IBM Plex Sans)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.primaryText,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.secondaryText,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  // Labels, Numbers, Badges (JetBrains Mono, uppercase, wide tracking: +1.0 to +1.5)
  static const TextStyle label = TextStyle(
    fontFamily: fontMono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.secondaryText,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontMono,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.secondaryText,
  );

  static const TextStyle number = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.primaryText,
  );
}

class AppTheme {
  // Legacy getters to preserve full backwards compatibility
  static TextStyle get headingStyle => AppTypography.titleMedium;
  static TextStyle get bodyStyle => AppTypography.bodyMedium;
  static TextStyle get monoStyle => AppTypography.number;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontBody,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.accentText,
        secondary: AppColors.primaryText,
        onSecondary: AppColors.background,
        error: AppColors.destructive,
        onError: AppColors.primaryText,
        surface: AppColors.surface,
        onSurface: AppColors.primaryText,
      ),

      // App Bar: Flat, border-bottom, no elevation/shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryText, size: 20),
        titleTextStyle: AppTypography.titleMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.background,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Card: Flat matte, 1px hairline border, zero elevation/shadow
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusM,
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
      ),

      // Dialog Theme: Flat matte, zero shadow
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusL,
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
        titleTextStyle: AppTypography.titleMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Bottom Sheet Theme: Flat matte, zero blur
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
      ),

      // Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accent.withAlpha(80),
        selectionHandleColor: AppColors.accent,
      ),

      // Input Decoration: Flat, 1px border, min 48px tap height
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.radiusM,
          borderSide: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusM,
          borderSide: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusM,
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusM,
          borderSide: BorderSide(color: AppColors.destructive, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusM,
          borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
        ),
      ),

      // Navigation Bar: Flat matte, hairline top border, no glow
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.raisedSurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.accent : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: isSelected ? AppColors.accent : AppColors.secondaryText,
          );
        }),
      ),

      // Dividers: 1px hairline
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineBorder,
        thickness: 1.0,
        space: 1.0,
      ),

      // Snackbars: Flat raised surface, hairline border
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.raisedSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primaryText),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusM,
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
      ),
    );
  }

  // Alias lightTheme to darkTheme to maintain strict matte black aesthetics
  static ThemeData get lightTheme => darkTheme;
}
