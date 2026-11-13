import 'package:flutter/material.dart';

import 'krezio_components.dart';

/// A single selection across equally sized options.
class KrezioSegmentedControl<T> extends StatelessWidget {
  const KrezioSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = KrezioPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final option in options.entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    selected: option.key == selected,
                    inMutuallyExclusiveGroup: true,
                    child: TextButton(
                      onPressed: () => onChanged(option.key),
                      style: TextButton.styleFrom(
                        backgroundColor: option.key == selected
                            ? palette.accentSoft
                            : Colors.transparent,
                        foregroundColor: option.key == selected
                            ? palette.accentText
                            : palette.secondaryText,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: option.key == selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      child: Text(option.value, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
