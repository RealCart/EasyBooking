import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/theme/app_theme.dart';

final class EasyBookingApp extends StatelessWidget {
  const EasyBookingApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EasyBooking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: .light,
      routerConfig: router,
    );
  }
}
