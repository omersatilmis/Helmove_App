import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/route_entity.dart';

class AlternateRouteCards extends StatelessWidget {
  final List<RouteEntity> routes;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final String? title;

  const AlternateRouteCards({
    super.key,
    required this.routes,
    required this.selectedIndex,
    this.onSelected,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title ?? l10n.map_alternative_routes_title,
              style: AppTextStyles.h3.copyWith(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              l10n.map_route_count(routes.length),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: routes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final route = routes[index];
              final isSelected = index == selectedIndex;
              final isFree = route.category == RouteCategory.free;
              final badgeText = isFree ? 'Ücretsiz Yollar' : 'En Hızlı';
              final badgeIcon =
                  isFree ? Icons.money_off_rounded : Icons.bolt_rounded;
              final badgeColor =
                  isFree ? const Color(0xFF2E7D32) : colorScheme.primary;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onSelected == null ? null : () => onSelected!(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.08)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              badgeIcon,
                              size: 16,
                              color: isSelected
                                  ? badgeColor
                                  : badgeColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                badgeText,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isSelected
                                      ? badgeColor
                                      : badgeColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Paralı yol göstergesi (sadece En Hızlı'da toll varsa)
                            if (route.hasToll)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.attach_money_rounded,
                                  size: 16,
                                  color: const Color(0xFFF9A825),
                                ),
                              ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                        Text(
                          FormatUtils.formatDuration(route.durationSeconds),
                          style: AppTextStyles.h2.copyWith(
                            color: isSelected
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${FormatUtils.formatDistance(route.distanceMeters)} - ${l10n.map_eta_label} ${FormatUtils.formatEta(route.durationSeconds)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
