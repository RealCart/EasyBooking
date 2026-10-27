import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Application themes assembled from the EasyBooking design primitives.
abstract final class AppTheme {
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.onAccent,
      secondary: AppColors.text,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.surface,
      onSecondaryContainer: AppColors.text,
      surface: AppColors.background,
      onSurface: AppColors.text,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.border,
    );

    const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );

    const OutlineInputBorder enabledInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.border),
    );

    const OutlineInputBorder focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.text, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.background,
      dividerColor: AppColors.border,
      disabledColor: AppColors.border,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.primaryText,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 48)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 24),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTypography.action,
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.onAccent,
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.accentPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.accentHover;
            }
            return AppColors.accent;
          }),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll<Size>(Size(64, 48)),
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 24),
          ),
          elevation: WidgetStatePropertyAll<double>(0),
          shape: WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            AppTypography.action,
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(AppColors.text),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppColors.text),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          height: 20 / 12,
          color: AppColors.secondaryText,
        ),
        hintStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          height: 24 / 16,
          color: AppColors.secondaryText,
        ),
        enabledBorder: enabledInputBorder,
        disabledBorder: enabledInputBorder,
        focusedBorder: focusedInputBorder,
        errorBorder: enabledInputBorder,
        focusedErrorBorder: focusedInputBorder,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.text,
        disabledColor: AppColors.surface,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: AppTypography.textTheme.labelMedium,
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.onAccent,
        ),
        showCheckmark: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          height: 2,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          height: 2,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: AppColors.background,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.secondaryText,
            size: 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          return TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            height: 2,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.secondaryText,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: AppColors.text, size: 22),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.text,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
