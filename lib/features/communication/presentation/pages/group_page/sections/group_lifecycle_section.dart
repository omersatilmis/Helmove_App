import 'package:flutter/material.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/group_ride/domain/entities/group_ride_entity.dart';
import 'package:helmove/features/group_ride/domain/entities/group_ride_status.dart';
import '../dialogs/group_page_actions.dart';

/// [Yaşam döngüsü] Grup sürüşü durum rozeti + organizatör kontrolleri.
///
/// - Tüm kullanıcılar: durum rozeti (Planlanıyor/Hazır/Canlı/Tamamlandı/...).
/// - Terminal durumlarda (Tamamlandı/İptal): bilgilendirici banner.
/// - Yalnızca organizatör (`ride.adminId == currentUserId`) ve terminal değilse:
///   duruma göre Başlat / Ertele / İptal / Bitir aksiyonları.
class GroupLifecycleSection extends StatelessWidget {
  final GroupRideEntity? rideDetails;
  final int? currentUserId;

  const GroupLifecycleSection({
    super.key,
    required this.rideDetails,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final ride = rideDetails;
    if (ride == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final status = parseGroupRideStatus(ride.status);
    final isOrganizer = currentUserId != null && ride.adminId == currentUserId;
    final visual = _statusVisual(status, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBadge(visual, ride, status),
        if (status.isTerminal) ...[
          const SizedBox(height: 12),
          _buildTerminalBanner(visual, status),
        ],
        if (isOrganizer && !status.isTerminal) ...[
          const SizedBox(height: 12),
          _buildOrganizerControls(context, ride, status, colorScheme),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusBadge(
    _StatusVisual visual,
    GroupRideEntity ride,
    GroupRideStatus status,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, color: visual.color, size: 18),
          const SizedBox(width: 8),
          Text(
            visual.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: visual.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (status.isStartable) ...[
            const SizedBox(width: 8),
            Text(
              _formatDateTime(ride.startDateTime),
              style: AppTextStyles.bodySmall.copyWith(
                color: visual.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminalBanner(_StatusVisual visual, GroupRideStatus status) {
    final message = status == GroupRideStatus.completed
        ? 'Bu tur tamamlandı.'
        : 'Bu tur iptal edildi.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(visual.icon, color: visual.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: visual.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerControls(
    BuildContext context,
    GroupRideEntity ride,
    GroupRideStatus status,
    ColorScheme colorScheme,
  ) {
    if (status.isLive) {
      // InProgress → Turu Bitir
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: () =>
              GroupPageActions.completeRide(context: context, rideId: ride.id),
          icon: const Icon(Icons.flag_rounded, size: 22),
          label: const Text(
            'Turu Bitir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    // Planning / Active / Postponed → Başlat + Ertele + İptal
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () =>
                GroupPageActions.startRide(context: context, rideId: ride.id),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Turu Başlat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => GroupPageActions.postponeRide(
                    context: context,
                    rideId: ride.id,
                  ),
                  icon: const Icon(Icons.schedule_rounded, size: 20),
                  label: const Text('Ertele'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => GroupPageActions.cancelRide(
                    context: context,
                    rideId: ride.id,
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text('İptal Et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _StatusVisual _statusVisual(GroupRideStatus status, ColorScheme colorScheme) {
    switch (status) {
      case GroupRideStatus.planning:
        return _StatusVisual(
          'Planlanıyor',
          colorScheme.onSurfaceVariant,
          Icons.event_note_rounded,
        );
      case GroupRideStatus.active:
        return _StatusVisual('Hazır', Colors.blue, Icons.check_circle_outline);
      case GroupRideStatus.inProgress:
        return _StatusVisual(
          'Canlı',
          Colors.green,
          Icons.sensors_rounded,
        );
      case GroupRideStatus.completed:
        return _StatusVisual(
          'Tamamlandı',
          colorScheme.onSurfaceVariant,
          Icons.flag_rounded,
        );
      case GroupRideStatus.cancelled:
        return _StatusVisual(
          'İptal edildi',
          colorScheme.error,
          Icons.cancel_rounded,
        );
      case GroupRideStatus.postponed:
        return _StatusVisual(
          'Ertelendi',
          Colors.orange,
          Icons.schedule_rounded,
        );
      case GroupRideStatus.unknown:
        return _StatusVisual(
          'Bilinmiyor',
          colorScheme.onSurfaceVariant,
          Icons.help_outline_rounded,
        );
    }
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _StatusVisual {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusVisual(this.label, this.color, this.icon);
}
