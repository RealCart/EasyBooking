import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';

/// Swipeable full-width photos with a heart and a `1 / 12` counter.
final class PropertyGallery extends StatefulWidget {
  const PropertyGallery({
    required this.imageUrls,
    required this.isSaved,
    required this.onSavedPressed,
    super.key,
  }) : assert(imageUrls.length > 0);

  final List<String> imageUrls;
  final bool isSaved;
  final VoidCallback onSavedPressed;

  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

final class _PropertyGalleryState extends State<PropertyGallery> {
  late final PageController _controller;
  // Only the counter listens to the page, so a swipe does not rebuild the
  // photos.
  late final ValueNotifier<int> _page;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _page = ValueNotifier<int>(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 430 / 266,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (int page) => _page.value = page,
            itemBuilder: (_, int index) {
              return Image.asset(widget.imageUrls[index], fit: BoxFit.cover);
            },
          ),
          Positioned(
            top: 10,
            right: 14,
            child: AppSavedIconButton(
              isSaved: widget.isSaved,
              onPressed: widget.onSavedPressed,
            ),
          ),
          Positioned(
            right: 24,
            bottom: 16,
            child: _PageCounter(page: _page, pageCount: widget.imageUrls.length),
          ),
        ],
      ),
    );
  }
}

/// The `1 / 12` badge; rebuilds alone when the page changes.
final class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.page, required this.pageCount});

  final ValueListenable<int> page;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ValueListenableBuilder<int>(
          valueListenable: page,
          builder: (BuildContext context, int value, _) {
            return Text(
              '${value + 1} / $pageCount',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onAccent,
              ),
            );
          },
        ),
      ),
    );
  }
}
