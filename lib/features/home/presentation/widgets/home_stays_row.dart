import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/presentation/widgets/home_labels.dart';

/// Horizontally scrolling stay cards of one [scope]. Two cards fit the
/// screen width, as in the design; more cards scroll.
final class HomeStaysRow extends StatelessWidget {
  const HomeStaysRow({
    required this.scope,
    required this.stays,
    required this.onStaySelected,
    super.key,
  });

  static const double _cardGap = AppSpacing.large;

  final HomeStayScope scope;
  final List<HomeStayEntity> stays;
  final ValueChanged<HomeStayEntity> onStaySelected;

  @override
  Widget build(BuildContext context) {
    if (stays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
        child: AppEmptyState(
          title: scope.emptyTitle,
          message: 'Новые брони появятся здесь автоматически',
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            (constraints.maxWidth - AppSizes.pageGutter * 2 - _cardGap) / 2;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pageGutter,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < stays.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: _cardGap),
                SizedBox(
                  width: cardWidth,
                  child: AppArrivalCard(
                    time: stays[index].badgeFor(scope),
                    propertyName: stays[index].propertyName,
                    stayDetails: stays[index].stayDetails,
                    imageUrl: stays[index].imageUrl,
                    status: stays[index].status.label,
                    statusIconPath: stays[index].status.iconPath,
                    onTap: () => onStaySelected(stays[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
