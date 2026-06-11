import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // =========================
  // BRAND RED
  // =========================

  static const red50 = Color(0xFFFFF1F2);
  static const red100 = Color(0xFFFFE4E6);
  static const red200 = Color(0xFFFECDD3);
  static const red300 = Color(0xFFFDA4AF);
  static const red400 = Color(0xFFFB7185);
  static const red500 = Color(0xFFE53935); // Primary
  static const red600 = Color(0xFFD32F2F);
  static const red700 = Color(0xFFC62828);
  static const red800 = Color(0xFFB71C1C);
  static const red900 = Color(0xFF7F1D1D);

  // =========================
  // NEUTRAL
  // =========================

  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFEEEEEE);
  static const neutral300 = Color(0xFFE0E0E0);
  static const neutral400 = Color(0xFFBDBDBD);
  static const neutral500 = Color(0xFF9E9E9E);
  static const neutral600 = Color(0xFF757575);
  static const neutral700 = Color(0xFF616161);
  static const neutral800 = Color(0xFF424242);
  static const neutral900 = Color(0xFF1F1F1F);

  // =========================
  // SEMANTIC
  // =========================

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF3B82F6);

  // =========================
  // LIGHT THEME
  // =========================

  static const primary = red500;
  static const primaryDark = red700;

  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF1F5F9);

  // =========================
  // DARK THEME
  // =========================

  static const darkBackground = Color(0xFF0F1115);
  static const darkSurface = Color(0xFF1A1D24);

  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Color(0xFF9CA3AF);

  static const darkBorder = Color(0xFF2D3748);

  // =========================
  // EXTRA
  // =========================

  static const shimmerBase = Color(0xFFE5E7EB);
  static const shimmerHighlight = Color(0xFFF8FAFC);

  static const disabled = Color(0xFFCBD5E1);
}

class AppInsets {
  const AppInsets._();

  static const screen = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const compactScreen = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const card = EdgeInsets.all(16);
  static const cardLarge = EdgeInsets.all(18);
  static const cardXLarge = EdgeInsets.all(22);
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const double navigationRail = 900;
  static const double extendedNavigationRail = 1120;
  static const double contentMaxWidth = 1120;
}

class AppRadius {
  const AppRadius._();

  static const double icon = 8;
  static const double control = 10;
  static const double card = 8;
  static const double pill = 999;

  static const iconBorder = BorderRadius.all(Radius.circular(icon));
  static const controlBorder = BorderRadius.all(Radius.circular(control));
  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}

class AppNeumorphic {
  const AppNeumorphic._();

  static List<BoxShadow> softShadow(
    Brightness brightness, {
    double depth = 0.20,
    double distance = 10,
    double blur = 22,
  }) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: depth + 0.18),
          offset: Offset(distance * 0.72, distance * 0.72),
          blurRadius: blur,
        ),
        BoxShadow(
          color: AppColors.red900.withValues(alpha: 0.12),
          offset: Offset(-distance * 0.46, -distance * 0.46),
          blurRadius: blur * 0.8,
        ),
      ];
    }

    return [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.95),
        offset: Offset(-distance * 0.6, -distance * 0.6),
        blurRadius: blur,
      ),
      BoxShadow(
        color: AppColors.neutral400.withValues(alpha: depth),
        offset: Offset(distance * 0.72, distance * 0.72),
        blurRadius: blur,
      ),
    ];
  }

  static List<BoxShadow> pressedShadow(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          offset: const Offset(3, 3),
          blurRadius: 10,
        ),
        BoxShadow(
          color: AppColors.red900.withValues(alpha: 0.10),
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
      ];
    }

    return [
      BoxShadow(
        color: AppColors.neutral400.withValues(alpha: 0.16),
        offset: const Offset(3, 3),
        blurRadius: 9,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.84),
        offset: const Offset(-2, -2),
        blurRadius: 8,
      ),
    ];
  }

  static LinearGradient surfaceGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.darkSurface, AppColors.darkBackground],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.surface, AppColors.background],
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.red100,
        secondary: AppColors.neutral700,
        secondaryContainer: AppColors.neutral100,
        tertiary: AppColors.warning,
        tertiaryContainer: Color(0xFFFFF7ED),
        error: AppColors.error,
        errorContainer: AppColors.red100,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onPrimaryContainer: AppColors.red900,
        onSecondary: Colors.white,
        onSecondaryContainer: AppColors.textPrimary,
        onTertiary: Colors.white,
        onTertiaryContainer: Color(0xFF7C2D12),
        onError: Colors.white,
        onErrorContainer: AppColors.red900,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      outline: AppColors.border,
      secondaryText: AppColors.textSecondary,
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.red400,
        primaryContainer: AppColors.red900,
        secondary: AppColors.neutral300,
        secondaryContainer: AppColors.neutral800,
        tertiary: AppColors.warning,
        tertiaryContainer: Color(0xFF78350F),
        error: AppColors.red400,
        errorContainer: AppColors.red900,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkBackground,
        onPrimaryContainer: AppColors.red100,
        onSecondary: AppColors.darkBackground,
        onSecondaryContainer: AppColors.neutral100,
        onTertiary: AppColors.darkBackground,
        onTertiaryContainer: Color(0xFFFFEDD5),
        onError: AppColors.darkBackground,
        onErrorContainer: AppColors.red100,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      outline: AppColors.darkBorder,
      secondaryText: AppColors.darkTextSecondary,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color outline,
    required Color secondaryText,
  }) {
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );

    final baseTextTheme = brightness == Brightness.dark
        ? typography.white
        : typography.black;

    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      dividerColor: outline,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.2,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: secondaryText,
          height: 1.35,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: secondaryText,
          height: 1.35,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: outline.withValues(alpha: 0.24)),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        selectedColor: colorScheme.primary,
        disabledColor: AppColors.disabled,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.neutral600,
          elevation: brightness == Brightness.light ? 2 : 0,
          shadowColor: brightness == Brightness.light
              ? AppColors.red900.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.28),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          elevation: brightness == Brightness.light ? 1 : 0,
          shadowColor: brightness == Brightness.light
              ? AppColors.neutral400.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.22),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
          side: BorderSide(color: outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.square(44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        labelStyle: TextStyle(color: secondaryText),
        helperStyle: TextStyle(color: secondaryText),
        hintStyle: TextStyle(color: secondaryText),
        errorStyle: TextStyle(color: colorScheme.error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minLeadingWidth: 28,
        iconColor: colorScheme.primary,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: secondaryText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : secondaryText,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: brightness == Brightness.light ? 5 : 1,
        focusElevation: brightness == Brightness.light ? 7 : 2,
        highlightElevation: brightness == Brightness.light ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        dividerThickness: 0.8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.neutral900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
    );
  }
}
