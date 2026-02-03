import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

class NearbyGroupCard extends StatelessWidget {
  final String groupName;
  final String distance;
  final int currentParticipants;
  final int maxParticipants;
  final String signalStatus;
  final VoidCallback onJoinPressed;

  const NearbyGroupCard({
    super.key,
    required this.groupName,
    required this.distance,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.signalStatus,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: AppTextStyles.regular.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        distance,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$currentParticipants/$maxParticipants Riders",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        signalStatus,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onJoinPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Text(
              "Join",
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
