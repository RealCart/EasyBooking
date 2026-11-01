import 'package:flutter/material.dart';

/// Content with a 4 px colored bar on its left that spans its full height,
/// such as a role in «Роли» or the current plan.
final class ProfileAccentBlock extends StatelessWidget {
  const ProfileAccentBlock({
    required this.color,
    required this.child,
    this.gap = 12,
    super.key,
  });

  static const double _barWidth = 4;

  final Color color;
  final Widget child;

  /// Space between the bar and [child].
  final double gap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: _barWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(child: child),
        ],
      ),
    );
  }
}
