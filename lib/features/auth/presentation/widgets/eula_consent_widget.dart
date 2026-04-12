import 'package:flutter/material.dart';

class EulaConsentWidget extends StatelessWidget {
  final bool value;
  final bool showWarning;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapEula;

  const EulaConsentWidget({
    super.key,
    required this.value,
    required this.showWarning,
    required this.onChanged,
    required this.onTapEula,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldHighlight = showWarning && !value;
    final baseTextStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            side: BorderSide(
              color: shouldHighlight
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline,
              width: shouldHighlight ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I have read and agree to the ',
                  style: baseTextStyle,
                ),
                GestureDetector(
                  onTap: onTapEula,
                  child: Text(
                    'EULA',
                    style: baseTextStyle?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text('.', style: baseTextStyle),
              ],
            ),
          ),
        ),
        if (shouldHighlight)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
