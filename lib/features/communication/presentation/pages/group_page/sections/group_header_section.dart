import 'package:flutter/material.dart';

import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import 'package:moto_comm_app_1/features/group_ride/domain/entities/group_ride_entity.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/entities/voice_session_entity.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/enums/rtc_state.dart';

class GroupHeaderSection extends StatelessWidget {
  final GroupRideArgs data;
  final GroupRideEntity? rideDetails;
  final VoiceSessionEntity? sessionDetails;
  final bool isLoadingRide;
  final RtcConnectionStatus rtcStatus;
  final VoidCallback onBack;

  const GroupHeaderSection({
    super.key,
    required this.data,
    required this.rideDetails,
    required this.sessionDetails,
    required this.isLoadingRide,
    required this.rtcStatus,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colorScheme),
        if (isLoadingRide && rideDetails == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildMetaItem(
              context,
              Icons.map,
              "Rota: ${rideDetails?.endLocation ?? data.destination ?? 'Bilinmiyor'}",
            ),
            _buildDivider(context),
            _buildMetaItem(
              context,
              Icons.bolt,
              rideDetails?.ridingStyle ?? data.ridingStyle ?? 'Bilinmiyor',
            ),
            _buildDivider(context),
            _buildMetaItem(
              context,
              Icons.bar_chart,
              rideDetails?.difficulty ?? 'Bilinmiyor',
            ),
            _buildDivider(context),
            _buildMetaItem(
              context,
              (rideDetails?.isPrivate ?? (data.privacy == "Private"))
                  ? Icons.lock
                  : Icons.public,
              (rideDetails?.isPrivate ?? (data.privacy == "Private"))
                  ? "Private"
                  : "Public",
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildIntercomBanner(context),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppFrostedButton(icon: Icons.arrow_back, size: 44, onTap: onBack),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              rideDetails?.title ?? sessionDetails?.title ?? data.groupName,
              style: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.sessionDuration ?? "00:00",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.circle,
                  size: 4,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  "${sessionDetails?.activeParticipantCount ?? (data.currentParticipants ?? 0)} / ${rideDetails?.maxParticipants ?? data.maxParticipants ?? 0}",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntercomBanner(BuildContext context) {
    const intercomColor = Color(0xFF22C55E);

    final isP2P =
        rtcStatus == RtcConnectionStatus.p2pConnected ||
        rtcStatus == RtcConnectionStatus.p2pConnecting;
    final isSfu =
        rtcStatus == RtcConnectionStatus.sfuConnected ||
        rtcStatus == RtcConnectionStatus.sfuConnecting;
    final isReconnecting = rtcStatus == RtcConnectionStatus.reconnecting;

    final Color connectionColor;
    final String connectionText;
    final IconData connectionIcon;

    if (isP2P) {
      connectionColor = const Color(0xFF3B82F6);
      connectionText = rtcStatus == RtcConnectionStatus.p2pConnected
          ? 'P2P Bağlantı'
          : 'P2P Bağlanıyor...';
      connectionIcon = Icons.call;
    } else if (isSfu) {
      connectionColor = const Color(0xFF8B5CF6);
      connectionText = rtcStatus == RtcConnectionStatus.sfuConnected
          ? 'SFU Bağlantı'
          : 'SFU Bağlanıyor...';
      connectionIcon = Icons.hub;
    } else if (isReconnecting) {
      connectionColor = Colors.orange;
      connectionText = 'Yeniden Bağlanıyor...';
      connectionIcon = Icons.sync;
    } else {
      connectionColor = Colors.grey;
      connectionText = 'Bekleniyor...';
      connectionIcon = Icons.hourglass_empty;
    }

    final intercomCard = _buildIntercomStatusCard(
      color: intercomColor,
      icon: Icons.wifi_tethering,
      title: 'Intercom Active',
    );
    final connectionCard = _buildIntercomStatusCard(
      color: connectionColor,
      icon: connectionIcon,
      title: connectionText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        if (isCompact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [intercomCard, const SizedBox(height: 8), connectionCard],
          );
        }

        return Row(
          children: [
            Expanded(child: intercomCard),
            const SizedBox(width: 12),
            Expanded(child: connectionCard),
          ],
        );
      },
    );
  }

  Widget _buildIntercomStatusCard({
    required Color color,
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
