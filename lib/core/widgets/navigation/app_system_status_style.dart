import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppSystemStatusStyle {
  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

final class AppSystemStatusRegion extends StatelessWidget {
  const AppSystemStatusRegion({
    required this.child,
    this.style = AppSystemStatusStyle.dark,
    super.key,
  });

  final Widget child;
  final SystemUiOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: child,
    );
  }
}
