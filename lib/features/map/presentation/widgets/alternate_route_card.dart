import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import '../../domain/entities/route_entity.dart';
import '../../../../core/utils/format_utils.dart';

class AlternateRouteCards extends StatelessWidget {
  final List<RouteEntity> routes;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final String title;

  const AlternateRouteCards({
    super.key,
    required this.routes,
    required this.selectedIndex,
    this.onSelected,
    this.title = 'Alternatif Rotalar',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    final shortestIndex = _shortestIndex(routes);
    final fastestIndex = _fastestIndex(routes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- BAŞLIK VE ROTA SAYISI ---
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${routes.length} rota',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.primary, // Vurgulu renk
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // --- YATAY ROTA KARTLARI LİSTESİ ---
        SizedBox(
          height: 115, // Kartların ferah görünmesi için biraz açtık
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: routes.length,
            // İlk ve son kartın kenarlara yapışmaması için padding eklenebilir, şimdilik separator var
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final route = routes[index];
              final isSelected = index == selectedIndex;
              final badgeText = _badgeLabel(index, shortestIndex, fastestIndex);
              final badgeIcon = _badgeIcon(index, shortestIndex, fastestIndex);
              final badgeColor = _badgeColor(
                index,
                shortestIndex,
                fastestIndex,
                colorScheme,
              );

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onSelected == null ? null : () => onSelected!(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width:
                        160, // Ekrana daha rahat sığması için optimize edildi
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Seçiliyken çok hafif bir ana renk dolgusu
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.08)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      // Seçiliyken kalın ve renkli çerçeve, değilse ince ve silik çerçeve
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
                        // --- ÜST SATIR: Rozet (Şimşek/Hızlı vs) ve Seçili İkonu ---
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
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),

                        // --- ORTA SATIR: Süre (Büyük ve Net) ---
                        Text(
                          FormatUtils.formatDuration(route.durationSeconds),
                          style: AppTextStyles.h2.copyWith(
                            color: isSelected
                                ? colorScheme.onSurface
                                : colorScheme
                                      .onSurfaceVariant, // Seçili değilse biraz silik
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),

                        // --- ALT SATIR: Mesafe ve ETA Birleşik ---
                        Text(
                          '${FormatUtils.formatDistance(route.distanceMeters)}  •  ETA ${FormatUtils.formatEta(route.durationSeconds)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
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

  int _shortestIndex(List<RouteEntity> routes) {
    var bestIndex = 0;
    var bestValue = routes.first.distanceMeters;
    for (var i = 1; i < routes.length; i++) {
      final value = routes[i].distanceMeters;
      if (value < bestValue) {
        bestValue = value;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int _fastestIndex(List<RouteEntity> routes) {
    var bestIndex = 0;
    var bestValue = routes.first.durationSeconds;
    for (var i = 1; i < routes.length; i++) {
      final value = routes[i].durationSeconds;
      if (value < bestValue) {
        bestValue = value;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  String _badgeLabel(int index, int shortestIndex, int fastestIndex) {
    if (index == shortestIndex && index == fastestIndex) {
      return 'Kısa ve Hızlı';
    }
    if (index == shortestIndex) return 'En Kısa';
    if (index == fastestIndex) return 'En Hızlı';
    return 'Alternatif';
  }

  // YENİ: Göze hitap etmesi için etiket ikonları
  IconData _badgeIcon(int index, int shortestIndex, int fastestIndex) {
    if (index == shortestIndex && index == fastestIndex) {
      return Icons.offline_bolt_rounded; // Hem kısa hem hızlıysa şimşek
    }
    if (index == shortestIndex) {
      return Icons.straighten_rounded; // Kısaysa cetvel
    }
    if (index == fastestIndex) return Icons.bolt_rounded; // Hızlıysa şimşek
    return Icons.alt_route_rounded; // Alternatif
  }

  Color _badgeColor(
    int index,
    int shortestIndex,
    int fastestIndex,
    ColorScheme colorScheme,
  ) {
    if (index == shortestIndex && index == fastestIndex) {
      return colorScheme.primary; // Genelde yeşil veya mavi/turuncu
    }
    if (index == shortestIndex) {
      return colorScheme.tertiary; // Farklı bir vurgu rengi
    }
    if (index == fastestIndex) return colorScheme.primary;
    return colorScheme.onSurfaceVariant; // Alternatifse sönük gri
  }
}
