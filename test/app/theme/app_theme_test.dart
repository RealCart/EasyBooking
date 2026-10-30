import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

void main() {
  group('AppTheme.light', () {
    final ThemeData theme = AppTheme.light;

    test('uses the Paper color palette', () {
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.colorScheme.surface, AppColors.background);
      expect(theme.colorScheme.onSurface, AppColors.text);
      expect(theme.colorScheme.outline, AppColors.border);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.dividerColor, AppColors.border);
    });

    test('uses Inter and the Paper typography scale', () {
      expect(theme.textTheme.headlineMedium?.fontFamily, 'Inter');
      expect(theme.textTheme.headlineMedium?.fontSize, 28);
      expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.titleLarge?.fontSize, 18);
      expect(theme.textTheme.titleMedium?.fontSize, 16);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(AppTypography.caption.fontSize, 12);
    });

    test('suppresses default ripple, highlight, and hover feedback', () {
      final WidgetStateProperty<Color?>? backgroundColor =
          theme.filledButtonTheme.style?.backgroundColor;
      final WidgetStateProperty<Color?>? overlayColor =
          theme.filledButtonTheme.style?.overlayColor;

      expect(theme.splashFactory, same(NoSplash.splashFactory));
      expect(theme.splashColor, Colors.transparent);
      expect(theme.highlightColor, Colors.transparent);
      expect(theme.hoverColor, Colors.transparent);
      expect(backgroundColor?.resolve(<WidgetState>{}), AppColors.accent);
      expect(
        backgroundColor?.resolve(<WidgetState>{WidgetState.hovered}),
        AppColors.accent,
      );
      expect(
        backgroundColor?.resolve(<WidgetState>{WidgetState.pressed}),
        AppColors.accent,
      );
      expect(
        backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        AppColors.border,
      );
      expect(
        overlayColor?.resolve(<WidgetState>{WidgetState.hovered}),
        Colors.transparent,
      );
      expect(
        overlayColor?.resolve(<WidgetState>{WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        theme.textButtonTheme.style?.overlayColor?.resolve(<WidgetState>{
          WidgetState.hovered,
        }),
        Colors.transparent,
      );
      expect(
        theme.iconButtonTheme.style?.overlayColor?.resolve(<WidgetState>{
          WidgetState.pressed,
        }),
        Colors.transparent,
      );
    });

    test('uses the Paper input radius and focus treatment', () {
      final InputBorder? enabledBorder =
          theme.inputDecorationTheme.enabledBorder;
      final InputBorder? focusedBorder =
          theme.inputDecorationTheme.focusedBorder;

      expect(enabledBorder, isA<OutlineInputBorder>());
      expect(focusedBorder, isA<OutlineInputBorder>());
      expect(
        (enabledBorder! as OutlineInputBorder).borderRadius,
        const BorderRadius.all(Radius.circular(8)),
      );
      expect(
        (focusedBorder! as OutlineInputBorder).borderSide,
        const BorderSide(color: AppColors.text, width: 2),
      );
    });
  });
}
