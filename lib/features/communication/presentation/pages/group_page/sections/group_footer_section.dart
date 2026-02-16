import 'package:flutter/material.dart';

import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';

class GroupFooterSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onLeave;

  const GroupFooterSection({
    super.key,
    required this.colorScheme,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          AppFrostedTextButton(
            text: "Leave Ride",
            onPressed: onLeave,
            height: 52,
            backgroundColor: colorScheme.error.withValues(alpha: 0.1),
            textColor: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Keep your eyes on the road. Ride safe!",
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
