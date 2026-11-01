import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_tabs.dart';

/// The tabs of one property: «Обзор», «Брони», «Настройки».
enum PropertySection {
  overview('Обзор'),
  bookings('Брони'),
  settings('Настройки');

  const PropertySection(this.label);

  final String label;
}

/// [AppTabs] under the header of the property's «Брони» and «Настройки»
/// screens.
final class PropertySectionTabs extends StatelessWidget {
  const PropertySectionTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final PropertySection selected;
  final ValueChanged<PropertySection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: AppTabs(
        labels: <String>[
          for (final PropertySection section in PropertySection.values)
            section.label,
        ],
        selectedIndex: selected.index,
        onSelected: (int index) => onSelected(PropertySection.values[index]),
      ),
    );
  }
}

/// Moves from the tab [from] to [to] of [propertyId]. «Обзор» returns to the
/// property screen beneath; the other tabs replace the current one, so the
/// back button still leads to the property.
void openPropertySection(
  BuildContext context, {
  required String propertyId,
  required PropertySection from,
  required PropertySection to,
}) {
  if (from == to) {
    return;
  }
  final Map<String, String> pathParameters = <String, String>{
    AppRoutes.propertyIdParam: propertyId,
  };
  switch (to) {
    case PropertySection.overview:
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(
          AppRoutes.property.name,
          pathParameters: pathParameters,
        );
      }
    case PropertySection.bookings:
      context.pushReplacementNamed(
        AppRoutes.propertyBookings.name,
        pathParameters: pathParameters,
      );
    case PropertySection.settings:
      context.pushReplacementNamed(
        AppRoutes.propertySettings.name,
        pathParameters: pathParameters,
      );
  }
}
