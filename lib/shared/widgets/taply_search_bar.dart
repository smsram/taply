import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';

class TaplySearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const TaplySearchBar({
    super.key,
    this.hintText = 'Search installed apps',
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<TaplySearchBar> createState() => _TaplySearchBarState();
}

class _TaplySearchBarState extends State<TaplySearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: context.colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: context.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: context.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
                widget.onClear?.call();
              },
            ),
        ],
      ),
    );
  }
}
