import 'package:flutter/material.dart';

class KrezioColors {
  static const aiPurple = Color(0xFF6D28D9);
  static const aiPurpleLight = Color(0xFFBDA8FC);
  static const aiPurpleDark = Color(0xFF7C3AED);
  static const emeraldGreen = Color(0xFF047857);
  static const emeraldGreenLight = Color(0xFF34D399);
  static const friendlyOrange = Color(0xFFC2410C);
  static const friendlyOrangeLight = Color(0xFFFB923C);

  static const budgetOk = aiPurpleDark;
  static const budgetWarning = Color(0xFFE3A008);
  static const budgetOver = Color(0xFFEA580C);

  static const lightBackground = Color(0xFFF6F5F9);
  static const lightSurface = Colors.white;
  static const lightSurfaceVariant = Color(0xFFEFEDF4);
  static const lightPrimaryText = Color(0xFF17151C);
  static const lightSecondaryText = Color(0xFF5B5768);
  static const lightBorder = Color(0xFFE2DFEA);
  static const lightBorderStrong = Color(0xFFCDC8D9);
  static const lightFrame = Color(0xFFE8E5EF);
  static const lightAccentSoft = Color(0xFFEDE7FB);
  static const lightAccentBorder = Color(0xFFC7B6F4);
  static const lightAttentionSoft = Color(0xFFFCEBE1);
  static const lightWarning = Color(0xFF8A5300);
  static const lightWarningSoft = Color(0xFFFBF1D9);
  static const lightTrack = Color(0xFFE7E4EE);

  static const darkBackground = Color(0xFF111014);
  static const darkSurface = Color(0xFF1A1820);
  static const darkSurfaceVariant = Color(0xFF24212C);
  static const darkPrimaryText = Color(0xFFF2F0F7);
  static const darkSecondaryText = Color(0xFFABA6B8);
  static const darkBorder = Color(0xFF34303F);
  static const darkBorderStrong = Color(0xFF4A4556);
  static const darkFrame = Color(0xFF0B0A0D);
  static const darkAccentSoft = Color(0xFF2A2140);
  static const darkAccentBorder = Color(0xFF4E3C84);
  static const darkAttentionSoft = Color(0xFF34231A);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkWarningSoft = Color(0xFF2E2815);
  static const darkTrack = Color(0xFF2C2935);
}

class KrezioFont {
  static const double micro = 10;
  static const double caption = 11;
  static const double small = 12;
  static const double bodySmall = 13;
  static const double body = 15;
  static const double bodyLarge = 16;
  static const double title = 18;
  static const double headline = 24;
  static const double screenTitle = 26;
  static const double balance = 38;
}

class KrezioSpace {
  static const double hair = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class KrezioTheme {
  static const bodyFamily = 'Manrope';
  static const displayFamily = 'Bricolage Grotesque';
  static const contentWidth = 440.0;
  static const borderRadius = BorderRadius.all(Radius.circular(18));
  static const inputRadius = BorderRadius.all(Radius.circular(12));
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(24));

  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background =
        dark ? KrezioColors.darkBackground : KrezioColors.lightBackground;
    final surface = dark ? KrezioColors.darkSurface : KrezioColors.lightSurface;
    final surfaceVariant = dark
        ? KrezioColors.darkSurfaceVariant
        : KrezioColors.lightSurfaceVariant;
    final border = dark ? KrezioColors.darkBorder : KrezioColors.lightBorder;
    final borderStrong =
        dark ? KrezioColors.darkBorderStrong : KrezioColors.lightBorderStrong;
    final ink =
        dark ? KrezioColors.darkPrimaryText : KrezioColors.lightPrimaryText;
    final muted =
        dark ? KrezioColors.darkSecondaryText : KrezioColors.lightSecondaryText;
    final accent = dark ? KrezioColors.aiPurpleDark : KrezioColors.aiPurple;
    final accentText =
        dark ? KrezioColors.aiPurpleLight : KrezioColors.aiPurple;
    final accentSoft =
        dark ? KrezioColors.darkAccentSoft : KrezioColors.lightAccentSoft;
    final accentBorder =
        dark ? KrezioColors.darkAccentBorder : KrezioColors.lightAccentBorder;
    final attention =
        dark ? KrezioColors.friendlyOrangeLight : KrezioColors.friendlyOrange;

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accentSoft,
      onPrimaryContainer: accentText,
      secondary:
          dark ? KrezioColors.emeraldGreenLight : KrezioColors.emeraldGreen,
      secondaryContainer: accentSoft,
      onSecondaryContainer: accentText,
      tertiary: attention,
      error: attention,
      surface: surface,
      surfaceContainer: surfaceVariant,
      surfaceContainerHigh: surfaceVariant,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: borderStrong,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: bodyFamily,
      scaffoldBackgroundColor: background,
      dividerColor: border,
    );
    final text = base.textTheme;
    const heading = TextStyle(
      fontFamily: displayFamily,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    final shape = RoundedRectangleBorder(borderRadius: inputRadius);
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge!.merge(heading),
        displayMedium: text.displayMedium!.merge(heading),
        displaySmall: text.displaySmall!.merge(heading),
        headlineLarge: text.headlineLarge!.merge(heading),
        headlineMedium: text.headlineMedium!.merge(
          heading.copyWith(fontSize: KrezioFont.screenTitle),
        ),
        headlineSmall: text.headlineSmall!.merge(heading),
        titleLarge: text.titleLarge!.merge(
          heading.copyWith(fontSize: KrezioFont.title),
        ),
        bodyMedium: text.bodyMedium!.copyWith(
          fontSize: KrezioFont.body,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: heading.copyWith(
          color: ink,
          fontSize: KrezioFont.screenTitle,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(fontSize: KrezioFont.bodySmall, color: muted),
        hintStyle: TextStyle(fontSize: KrezioFont.body, color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KrezioSpace.lg,
          vertical: KrezioSpace.md,
        ),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(accentText, width: 1.6),
        errorBorder: inputBorder(attention),
        focusedErrorBorder: inputBorder(attention, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shape,
          minimumSize: const Size(44, 44),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: shape,
          elevation: 0,
          minimumSize: const Size(44, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: borderStrong),
          shape: shape,
          minimumSize: const Size(44, 44),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentText),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: accentSoft,
        side: BorderSide(color: borderStrong),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        modalBarrierColor:
            dark ? const Color(0x9E000000) : const Color(0x6B111014),
        surfaceTintColor: Colors.transparent,
        dragHandleColor: borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: sheetRadius),
        constraints: const BoxConstraints(maxWidth: contentWidth),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accentText),
      focusColor: accentBorder.withValues(alpha: .35),
    );
  }
}
