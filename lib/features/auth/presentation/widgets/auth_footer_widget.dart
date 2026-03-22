import 'package:flutter/material.dart';

class AuthFooterWidget extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onPressed;

  const AuthFooterWidget({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Biraz aşağı alındı (Eskisi 32.0 idi)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            questionText, 
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(
              actionText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
