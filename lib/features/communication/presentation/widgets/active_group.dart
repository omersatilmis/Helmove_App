import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
// 🔥 Merkezi butonu import ediyoruz
import '../../../../core/widgets/app_frosted_button.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            // Arka plan: Dropdown ve Inputlar ile uyumlu cam efekti
            color: colorScheme.surfaceContainerLow.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
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
        ),
      ),
    );
  }
}
