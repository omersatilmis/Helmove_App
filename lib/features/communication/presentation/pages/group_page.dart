import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/group_ride_data.dart';
import '../widgets/rider_card.dart';

// --- BACKEND-READY MODELS & MOCK DATA ---
class RiderData {
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final int batteryLevel;
  final int signalLevel;
  final bool isMicOn;
  final bool isSpeaking;

  RiderData({
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.batteryLevel,
    required this.signalLevel,
    this.isMicOn = false,
    this.isSpeaking = false,
  });
}

final List<RiderData> mockRiders = [
  RiderData(
    firstName: "You (Alex)",
    lastName: "",
    profileImageUrl: "https://i.pravatar.cc/150?img=12",
    batteryLevel: 87,
    signalLevel: 100,
    isMicOn: true,
    isSpeaking: false,
  ),
  RiderData(
    firstName: "Ahmet",
    lastName: "Manyas",
    profileImageUrl: "https://i.pravatar.cc/150?img=11",
    batteryLevel: 76,
    signalLevel: 95,
    isMicOn: true,
    isSpeaking: false,
  ),
  RiderData(
    firstName: "Salih",
    lastName: "Öztürk",
    profileImageUrl: "https://i.pravatar.cc/150?img=3",
    batteryLevel: 92,
    signalLevel: 88,
    isMicOn: true,
    isSpeaking: true,
  ),
  RiderData(
    firstName: "Harun",
    lastName: "Karabacak",
    profileImageUrl: "https://i.pravatar.cc/150?img=59",
    batteryLevel: 65,
    signalLevel: 72,
    isMicOn: false,
    isSpeaking: false,
  ),
];

class GroupPage extends StatelessWidget {
  final GroupRideData data;

  const GroupPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dinamik arka plan gradyanı
    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A100A), // Koyu modda hafif kırmızımsı üst
              Color(0xFF12100E), // darkBackground
            ],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          //bottom: false,
          child: Column(
            children: [
              // --- SCROLLABLE CONTENT ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER (Geri Dönüş ve Grup Bilgileri)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Geri Dönüş Butonu
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: colorScheme.onSurface,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          // Grup Bilgileri (Sağ tarafa yaslanmış)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                data.groupName,
                                style: AppTextStyles.h2.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data.sessionDuration,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${data.currentParticipants} / ${data.maxParticipants}",
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
                      ),

                      const SizedBox(height: 16),

                      // 2. METADATA (Rota, Stil, Gizlilik)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMetaItem(
                            context,
                            Icons.map,
                            "Rota: ${data.destination}",
                          ),
                          _buildDivider(context),
                          _buildMetaItem(context, Icons.bolt, data.ridingStyle),
                          _buildDivider(context),
                          _buildMetaItem(
                            context,
                            data.privacy == "Public"
                                ? Icons.language
                                : Icons.lock,
                            data.privacy,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. INTERCOM ACTIVE BANNER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF15803D,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF15803D,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_tethering,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Intercom Active",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: const Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 4. LIST HEADER & ACTIONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "CONNECTED RIDERS",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Row(
                            children: [
                              _buildGlassButton(
                                context,
                                Icons.person_add,
                                "Invite",
                              ),
                              const SizedBox(width: 8),
                              _buildGlassButton(
                                context,
                                Icons.settings,
                                "Settings",
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 5. RIDER LIST (Dinamik render edildi)
                      Column(
                        children: mockRiders.map((rider) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RiderCard(
                              firstName: rider.firstName,
                              lastName: rider.lastName,
                              profileImageUrl: rider.profileImageUrl,
                              batteryLevel: rider.batteryLevel,
                              signalLevel: rider.signalLevel,
                              isMicOn: rider.isMicOn,
                              isSpeaking: rider.isSpeaking,
                            ),
                          );
                        }).toList(),
                      ),
                      // --- BOTTOM PADDING (for extendBody: true) ---
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // 6. LEAVE RIDE BUTTON & WARNING
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Leave Ride",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Keep your eyes on the road. Ride safe!",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: colorScheme.onSurface),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
