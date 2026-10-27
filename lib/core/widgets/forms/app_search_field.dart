import 'package:flutter/material.dart';

import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/widgets/forms/app_text_field.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _setController(widget.controller);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      hint: widget.hint,
      enabled: widget.enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      leading: const Icon(Icons.search, size: 20),
      trailing: _controller.text.isEmpty
          ? null
          : AppIconButton(
              icon: const Icon(Icons.close, size: 18),
              semanticLabel: 'Clear search',
              onPressed: widget.enabled ? _clear : null,
            ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }
}
