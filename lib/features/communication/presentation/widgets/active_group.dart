import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

class ActiveGroupCard extends StatelessWidget {
  final String groupName;
  final int currentParticipants;
  final int maxParticipants;
  final bool isActive;
  final VoidCallback onOpenPressed;
  final List<Widget> riderCards;

  const ActiveGroupCard({
    super.key,
    required this.groupName,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.isActive,
    required this.onOpenPressed,
    required this.riderCards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Grup Üst Bilgisi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: AppTextStyles.h3.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$currentParticipants / $maxParticipants Participants",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onOpenPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Open",
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sürücü Kartları Listesi
          if (riderCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: riderCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: card,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
