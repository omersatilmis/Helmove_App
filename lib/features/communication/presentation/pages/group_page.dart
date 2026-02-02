import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/group_ride_data.dart';
import '../widgets/rider_card.dart';

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(
                alpha: 0.1,
              ), // Açık modda hafif turuncu
              colorScheme.surface,
            ],
            stops: const [0.0, 0.4],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- SCROLLABLE CONTENT ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER (Grup İsmi ve Çıkış Butonu)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.groupName,
                                style: AppTextStyles.h2.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
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
                                        .withOpacity(0.4),
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
                          // Çıkış Butonu
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.logout,
                                color: colorScheme.error,
                              ),
                              tooltip: "Leave Ride",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. METADATA (Rota, Stil, Gizlilik)
                      Row(
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

                      // 5. RIDER LIST
                      Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: RiderCard(
                              firstName: "You (Alex)",
                              lastName: "",
                              profileImageUrl:
                                  "https://i.pravatar.cc/150?img=12",
                              batteryLevel: 87,
                              signalLevel: 100,
                              isMicOn: true,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: RiderCard(
                              firstName: "Ahmet",
                              lastName: "Manyas",
                              profileImageUrl:
                                  "https://i.pravatar.cc/150?img=11",
                              batteryLevel: 76,
                              signalLevel: 95,
                              isMicOn: true,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: RiderCard(
                              firstName: "Salih",
                              lastName: "Öztürk",
                              profileImageUrl:
                                  "https://i.pravatar.cc/150?img=3",
                              batteryLevel: 92,
                              signalLevel: 88,
                              isMicOn: true,
                              isSpeaking: true,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: RiderCard(
                              firstName: "Harun",
                              lastName: "Karabacak",
                              profileImageUrl:
                                  "https://i.pravatar.cc/150?img=59",
                              batteryLevel: 65,
                              signalLevel: 72,
                              isMicOn: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 6. FOOTER (WARNING)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
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
