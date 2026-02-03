import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../widgets/rider_card.dart';
import '../widgets/active_group.dart';
import '../widgets/nearby_group.dart';
import 'create_group_ride.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

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
              Color(0xFF12100E),
            ],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary.withOpacity(0.1), colorScheme.surface],
            stops: const [0.0, 0.4],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. ÜST BUTONLAR (Saved Sessions & Create Ride) ---
                Row(
                  children: [
                    Expanded(
                      child: _buildTopButton(
                        context,
                        title: "Saved\nSessions",
                        icon: Icons.bookmark_border,
                        color: colorScheme.surfaceContainerLow,
                        iconColor: colorScheme.primary,
                        textColor: colorScheme.onSurface,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTopButton(
                        context,
                        title: "Create Ride\nGroup",
                        icon: Icons.add,
                        color: colorScheme.primary,
                        iconColor: colorScheme.onPrimary,
                        textColor: colorScheme.onPrimary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateGroupRide(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- 2. YOUR ACTIVE GROUP BAŞLIĞI & SOS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: colorScheme.onSurface,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Your Active Group",
                          style: AppTextStyles.h3.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // --- SOS / Acil Durum Butonu ---
                    // SOS / Acil Durum Butonu (Rounded Dikdörtgen Versiyon)
                    GestureDetector(
                      onTap: () {
                        print("SOS Gönderildi!");
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.15),
                          // Yuvarlatılmış dikdörtgen formu (borderRadius)
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.error,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.error.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "!SOS",
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize:
                                  16, // Form değiştiği için puntoyu biraz büyüttüm
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- 3. ACTIVE GROUP KARTI ---
                ActiveGroupCard(
                  groupName: "Weekend Riders",
                  currentParticipants: 4,
                  maxParticipants: 8,
                  isActive: true,
                  onOpenPressed: () {
                    context.push('/group-page');
                  },
                  riderCards: [
                    RiderCard(
                      firstName: "You (Alex)",
                      lastName: "",
                      profileImageUrl: "https://i.pravatar.cc/150?img=12",
                      batteryLevel: 87,
                      signalLevel: 100,
                      isMicOn: true,
                      isSpeaking: false,
                    ),
                    RiderCard(
                      firstName: "Ahmet",
                      lastName: "Manyas",
                      profileImageUrl: "https://i.pravatar.cc/150?img=11",
                      batteryLevel: 76,
                      signalLevel: 95,
                      isMicOn: true,
                      isSpeaking: false,
                    ),
                    RiderCard(
                      firstName: "Salih",
                      lastName: "Öztürk",
                      profileImageUrl: "https://i.pravatar.cc/150?img=3",
                      batteryLevel: 92,
                      signalLevel: 88,
                      isMicOn: true,
                      isSpeaking: true,
                    ),
                    RiderCard(
                      firstName: "Harun",
                      lastName: "Karabacak",
                      profileImageUrl: "https://i.pravatar.cc/150?img=59",
                      batteryLevel: 65,
                      signalLevel: 72,
                      isMicOn: false,
                      isSpeaking: false,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- 4. NEARBY GROUPS BAŞLIĞI ---
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Nearby Groups",
                      style: AppTextStyles.h3.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- 5. NEARBY GROUPS LİSTESİ ---
                NearbyGroupCard(
                  groupName: "Mountain Tour",
                  distance: "1.2 km",
                  currentParticipants: 2,
                  maxParticipants: 6,
                  signalStatus: "Strong",
                  onJoinPressed: () {},
                ),
                const SizedBox(height: 12),
                NearbyGroupCard(
                  groupName: "City Cruisers",
                  distance: "2.8 km",
                  currentParticipants: 6,
                  maxParticipants: 10,
                  signalStatus: "Strong",
                  onJoinPressed: () {},
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Üst Buton Yardımcı Fonksiyon ---
  Widget _buildTopButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 85,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
