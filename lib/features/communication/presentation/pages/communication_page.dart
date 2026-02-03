import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../widgets/rider_card.dart';
import '../widgets/active_group.dart';
import '../widgets/nearby_group.dart';

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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.08),
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
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. ÜST BUTONLAR (Saved Sessions & Create Ride) ---
                Row(
                  children: [
                    // --- SAVED SESSIONS (Nötr Cam) ---
                    Expanded(
                      child: _buildTopButton(
                        context,
                        title: "Saved\nSessions",
                        icon: Icons.bookmark_border,
                        // Camın tonu: Beyaz/Gri (Temaya göre)
                        glassTint: colorScheme.onSurface,
                        // İkon ve Yazı Rengi
                        iconColor: colorScheme.primary,
                        textColor: colorScheme.onSurface,
                        onTap: () {},
                      ),
                    ),

                    const SizedBox(width: 16),

                    // --- CREATE RIDE GROUP (Renkli Cam) ---
                    Expanded(
                      child: _buildTopButton(
                        context,
                        title: "Create Ride\nGroup",
                        icon: Icons.add,
                        // Camın tonu: Turuncu (Primary)
                        glassTint: colorScheme.primary,
                        // İkon ve Yazı Rengi
                        iconColor: isDark
                            ? colorScheme.primary
                            : colorScheme.onPrimary,
                        textColor: isDark
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                        onTap: () {
                          context.push('/communication/create-group-ride');
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
                          color: colorScheme.error.withOpacity(0.15),
                          // Yuvarlatılmış dikdörtgen formu (borderRadius)
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.error,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.error.withOpacity(0.3),
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
                    context.push('/communication/group-page');
                    //context.push('/deneme'); // gradient koyulaşıyor
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
                // --- 6. BOTTOM PADDING (for extendBody: true) ---
                const SizedBox(height: 100),
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
    required Color
    glassTint, // Artık 'color' değil 'glassTint' (Cam tonu) diyoruz
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Köşeleri biraz daha yumuşattım
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Buzlu cam efekti
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              // Camın rengi (Tint) - Opaklığı düşük tutuyoruz ki arkası görünsün
              color: glassTint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              // İnce, şık bir çerçeve
              border: Border.all(color: glassTint.withOpacity(0.3), width: 1),
              // Hafif bir gölge (Depth)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
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
        ),
      ),
    );
  }
}
