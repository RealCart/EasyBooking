import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
  );

  static const TextStyle compactScreenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.65,
  );

  /// Titles of detail and result screens (Paper: 24 / 30, semibold).
  static const TextStyle smallScreenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
  );

  /// Large figures, names and initials (Paper: 22 / 28, semibold).
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Titles of list rows and tiles (Paper: 15 / 18, semibold).
  static const TextStyle rowTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle primaryText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle compactBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 20 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle textAccent = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 20 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle action = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextTheme textTheme = TextTheme(
    displaySmall: screenTitle,
    headlineMedium: screenTitle,
    headlineSmall: compactScreenTitle,
    titleLarge: sectionTitle,
    titleMedium: primaryText,
    titleSmall: action,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: compactBody,
    labelLarge: action,
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      height: 20 / 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelSmall: caption,
  );
}
