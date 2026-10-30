import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

Widget appWidgetPreviewWrapper(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: child),
    ),
  );
}

void showPreviewMessage(BuildContext context, String message) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class AppPreviewGallery extends StatelessWidget {
  const AppPreviewGallery({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: <Widget>[
        Text(title, style: AppTypography.screenTitle),
        if (description case final String description) ...<Widget>[
          const SizedBox(height: AppSpacing.small),
          Text(
            description,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xLarge),
        for (int index = 0; index < children.length; index++) ...<Widget>[
          children[index],
          if (index != children.length - 1)
            const SizedBox(height: AppSpacing.large),
        ],
      ],
    );
  }
}

class AppPreviewSection extends StatelessWidget {
  const AppPreviewSection({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: AppTypography.sectionTitle),
            if (description case final String description) ...<Widget>[
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.large),
            child,
          ],
        ),
      ),
    );
  }
}

class AppPreviewImage extends StatelessWidget {
  const AppPreviewImage({
    this.height = 140,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppAssets.icons.building,
        width: 40,
        height: 40,
        colorFilter: const ColorFilter.mode(
          AppColors.secondaryText,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
