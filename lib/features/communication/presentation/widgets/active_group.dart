import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
// 🔥 Merkezi butonu import ediyoruz
import '../../../../core/widgets/app_frosted_button.dart';

class ActiveGroupCard extends StatelessWidget {
  final String groupName;
  final int currentParticipants;
  final int maxParticipants;
  final String? destination;
  final String? ridingStyle;
  final String? difficulty;
  final bool isActive;
  final VoidCallback onOpenPressed;
  final List<Widget> riderCards;

  const ActiveGroupCard({
    super.key,
    required this.groupName,
    required this.currentParticipants,
    required this.maxParticipants,
    this.destination,
    this.ridingStyle,
    this.difficulty,
    required this.isActive,
    required this.onOpenPressed,
    required this.riderCards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // Arka plan: Dropdown ve Inputlar ile uyumlu cam efekti
            color: colorScheme.surfaceContainerLow.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha:0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- GRUP ÜST BİLGİSİ ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: AppTextStyles.h3.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$currentParticipants / $maxParticipants Participants",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (destination != null ||
                              ridingStyle != null ||
                              difficulty != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (destination != null)
                                  _buildSmallBadge(
                                    context,
                                    Icons.map,
                                    destination!,
                                  ),
                                if (ridingStyle != null)
                                  _buildSmallBadge(
                                    context,
                                    Icons.bolt,
                                    ridingStyle!,
                                  ),
                                if (difficulty != null)
                                  _buildSmallBadge(
                                    context,
                                    Icons.bar_chart,
                                    difficulty!,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    AppFrostedTextButton(
                      text: "Open",
                      height: 36,
                      width: 80,
                      fontSize: 16,
                      padding: EdgeInsets.zero,
                      borderRadius: 12,
                      onPressed: onOpenPressed,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      textColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),

              // --- SÜRÜCÜ KARTLARI LİSTESİ ---
              if (riderCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: riderCards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => riderCards[index],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha:0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
