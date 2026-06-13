import 'package:flutter/material.dart';
import 'package:helmove/features/voice_session/domain/enums/rtc_state.dart';

/// [ODA MODELİ] Grup sürüşü ekranının alt ses kontrol barı.
///
/// Grup sürüşü bir "oda" gibidir; sese bağlanmak bilinçli bir aksiyondur.
/// - Sese katılmadan önce: büyük "Sese Katıl" butonu.
/// - Sesteyken: bağlantı durumu çipi + mikrofon toggle (mute başlar) +
///   "Sesten Ayrıl" butonu.
///
/// Motosiklet UX: büyük dokunma hedefleri, yüksek kontrast.
class VoiceControlBar extends StatelessWidget {
  final bool isInVoiceChannel;
  final bool isMicOn;
  final RtcConnectionStatus rtcStatus;
  final int activeSpeakerCount;
  final VoidCallback onJoinVoice;
  final VoidCallback onLeaveVoice;
  final VoidCallback onToggleMic;

  const VoiceControlBar({
    super.key,
    required this.isInVoiceChannel,
    required this.isMicOn,
    required this.rtcStatus,
    required this.activeSpeakerCount,
    required this.onJoinVoice,
    required this.onLeaveVoice,
    required this.onToggleMic,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.fromLTRB(20, 8, 20, 4);

    if (!isInVoiceChannel) {
      // Sese katılmadan önce — Discord "Join Voice Channel" hissi.
      return Padding(
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onJoinVoice,
            icon: const Icon(Icons.headset_mic_rounded, size: 24),
            label: const Text(
              'Sese Katıl',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    // Sesteyken — durum + mikrofon + ayrıl
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: _buildStatusChip(colorScheme)),
          const SizedBox(width: 12),
          _buildMicButton(colorScheme),
          const SizedBox(width: 12),
          _buildLeaveButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme) {
    final ({IconData icon, String label, Color color}) info = switch (rtcStatus) {
      RtcConnectionStatus.p2pConnected => (
        icon: Icons.wifi_tethering_rounded,
        label: activeSpeakerCount > 0 ? '$activeSpeakerCount konuşuyor' : 'Sese bağlı',
        color: Colors.green,
      ),
      RtcConnectionStatus.sfuConnected => (
        icon: Icons.cell_tower_rounded,
        label: activeSpeakerCount > 0 ? '$activeSpeakerCount konuşuyor' : 'Sese bağlı',
        color: Colors.green,
      ),
      RtcConnectionStatus.p2pConnecting ||
      RtcConnectionStatus.sfuConnecting => (
        icon: Icons.sync_rounded,
        label: 'Bağlanıyor...',
        color: Colors.orange,
      ),
      RtcConnectionStatus.reconnecting => (
        icon: Icons.sync_problem_rounded,
        label: 'Yeniden bağlanıyor...',
        color: Colors.orange,
      ),
      RtcConnectionStatus.failed => (
        icon: Icons.error_outline_rounded,
        label: 'Bağlantı hatası',
        color: colorScheme.error,
      ),
      RtcConnectionStatus.disconnected => (
        icon: Icons.hourglass_empty_rounded,
        label: 'Hazırlanıyor...',
        color: colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: info.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              info.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: info.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(ColorScheme colorScheme) {
    final activeColor = isMicOn ? Colors.green : colorScheme.error;
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: activeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggleMic,
          child: Icon(
            isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: activeColor,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveButton(ColorScheme colorScheme) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onLeaveVoice,
          child: Icon(
            Icons.call_end_rounded,
            color: colorScheme.error,
            size: 24,
          ),
        ),
      ),
    );
  }
}
