import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterFooterWidget extends StatelessWidget {
  const RegisterFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Zaten hesabınız var mı?", style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            "Giriş Yap",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
