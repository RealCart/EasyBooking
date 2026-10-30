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

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
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
