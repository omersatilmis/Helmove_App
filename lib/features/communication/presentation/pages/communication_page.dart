import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
// Aşağıdaki importların kendi proje yapına göre doğru olduğundan emin ol
import '../widgets/rider_card.dart';
import '../widgets/active_group.dart';
import '../widgets/nearby_group.dart';
import 'create_group_ride.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema verilerine erişim
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. ÜST BUTONLAR (Saved Sessions & Create Ride) ---
                Row(
                  children: [
                    // Saved Sessions Butonu
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
                    // Create Ride Group Butonu
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

                // --- 2. YOUR ACTIVE GROUP BAŞLIĞI ---
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
                    // Kırmızı Ünlem Uyarısı
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.error, width: 1),
                      ),
                      child: Icon(
                        Icons.priority_high,
                        color: colorScheme.error,
                        size: 20,
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

  // --- Üst Butonları Oluşturan Yardımcı Fonksiyon (Küçültülmüş Versiyon) ---
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
      borderRadius: BorderRadius.circular(16), // Köşe yuvarlaklığı 16
      child: Container(
        height: 85, // Yükseklik 85'e düşürüldü (Kompakt)
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ), // İç boşluklar azaltıldı
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6, // Gölge yumuşatıldı
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26), // İkon boyutu 26
            const SizedBox(height: 6), // Aradaki boşluk 6
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13, // Yazı boyutu 13
                height: 1.1, // Satır aralığı daraltıldı
              ),
            ),
          ],
        ),
      ),
    );
  }
}
