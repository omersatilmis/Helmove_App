import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';
import 'package:helmove/features/group_ride/domain/entities/group_ride_summary.dart';

/// [Keşfet] Grup turu özet kartı — search/nearby sonuçları için.
class RideSummaryCard extends StatelessWidget {
  final GroupRideSummary ride;

  /// nearby modunda "X km uzakta" gösterilir.
  final bool showDistance;
  final VoidCallback onTap;

  const RideSummaryCard({
    super.key,
    required this.ride,
    required this.showDistance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(colorScheme),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ride.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyBadge(difficulty: ride.difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _iconLine(
                    colorScheme,
                    Icons.place_outlined,
                    showDistance && ride.distanceKm != null
                        ? '${ride.startLocation} · ${ride.distanceKm!.toStringAsFixed(1)} km uzakta'
                        : ride.startLocation,
                  ),
                  const SizedBox(height: 4),
                  _iconLine(
                    colorScheme,
                    Icons.event_outlined,
                    '${_formatDate(ride.startDateTime)} · ${_styleLabel(ride.ridingStyle)}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildOrganizerAvatar(colorScheme),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.organizerName ?? 'Organizatör',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: ride.isFull
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ride.occupancyLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ride.isFull
                              ? colorScheme.error
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme colorScheme) {
    final url = ride.coverImageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.motorcycle_rounded,
          size: 44,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url.toAbsoluteImageUrl(),
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: 120,
        color: colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (_, _, _) => Container(
        height: 120,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.motorcycle_rounded,
          size: 44,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildOrganizerAvatar(ColorScheme colorScheme) {
    final avatar = ride.organizerAvatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return CircleAvatar(
      radius: 12,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
      backgroundImage: hasAvatar
          ? CachedNetworkImageProvider(avatar.toAbsoluteImageUrl())
          : null,
      child: hasAvatar
          ? null
          : Text(
              _initials(ride.organizerName),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
    );
  }

  Widget _iconLine(ColorScheme colorScheme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]} ${two(local.hour)}:${two(local.minute)}';
  }

  static String _styleLabel(String raw) => switch (raw) {
    'Sakin' => 'Sakin',
    'Tour' => 'Tur',
    'Viraj' => 'Viraj',
    'Sehir' => 'Şehir',
    _ => raw,
  };
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final ({String label, Color color}) v = switch (difficulty) {
      'Beginner' => (label: 'Başlangıç', color: Colors.green),
      'Intermediate' => (label: 'Orta', color: Colors.orange),
      'Advanced' => (label: 'İleri', color: Colors.deepOrange),
      'Expert' => (label: 'Uzman', color: Colors.red),
      _ => (label: difficulty, color: Theme.of(context).colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: v.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        v.label,
        style: TextStyle(
          color: v.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
