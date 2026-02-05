import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../voice_session/domain/entities/voice_session_entity.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../../domain/entities/group_ride_data.dart';
import '../bloc/group_ride_bloc.dart';
import '../bloc/group_ride_event.dart';
import '../bloc/group_ride_state.dart';
import '../widgets/active_group.dart';
import '../widgets/nearby_group.dart';
import '../widgets/rider_card.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  List<VoiceSessionEntity> _mySessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadMySessions();
  }

  void _loadMySessions() {
    context.read<VoiceSessionBloc>().add(const GetMyVoiceSessionsEvent());
  }

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

    return BlocListener<VoiceSessionBloc, VoiceSessionState>(
      listener: (context, state) {
        if (state is MyVoiceSessionsLoaded) {
          setState(() {
            _mySessions = state.sessions.cast<VoiceSessionEntity>();
            _isLoadingSessions = false;
          });
        } else if (state is VoiceSessionError) {
          setState(() => _isLoadingSessions = false);
        } else if (state is VoiceSessionLoading) {
          setState(() => _isLoadingSessions = true);
        }
      },
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                _loadMySessions();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            glassTint: colorScheme.onSurface,
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
                            glassTint: colorScheme.primary,
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
                            const SizedBox(width: 8),
                            // Refresh button
                            GestureDetector(
                              onTap: _loadMySessions,
                              child: Icon(
                                Icons.refresh,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        // --- SOS Acil Durum Butonu ---
                        GestureDetector(
                          onTap: () {
                            print("SOS Gönderildi!");
                          },
                          child: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.15),
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
                                  fontSize: 16,
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

                    // --- 3. ACTIVE GROUP KARTI (VoiceSession'dan yüklenir) ---
                    _buildActiveSessionCard(colorScheme),

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

                    // --- 5. NEARBY GROUPS LİSTESİ (Backend'den yüklenir) ---
                    BlocBuilder<GroupRideBloc, GroupRideState>(
                      builder: (context, state) {
                        if (state is NearbyGroupRidesLoaded) {
                          return Column(
                            children: state.rides.map((ride) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NearbyGroupCard(
                                  groupName: ride.title,
                                  distance:
                                      "${(ride.estimatedDistanceKm ?? 0).toStringAsFixed(1)} km",
                                  currentParticipants: ride.currentParticipants,
                                  maxParticipants: ride.maxParticipants,
                                  signalStatus: "Strong",
                                  onJoinPressed: () {
                                    context.read<GroupRideBloc>().add(
                                      JoinGroupRide(ride.id),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        }
                        // Varsayılan durumda bilgi mesajı
                        return Center(
                          child: Text(
                            'Yakında grup bulunamadı',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                    // --- 6. BOTTOM PADDING (for extendBody: true) ---
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard(ColorScheme colorScheme) {
    if (_isLoadingSessions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_mySessions.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aktif odanız yok',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yeni bir oda oluşturun veya davet bekleyin',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Aktif session varsa göster
    final activeSession = _mySessions.first;
    final participants = activeSession.participants
        .where((p) => p.status == 'Joined' || p.status == 'Accepted')
        .toList();

    return ActiveGroupCard(
      groupName: activeSession.title,
      currentParticipants: activeSession.activeParticipantCount,
      maxParticipants: 10, // Varsayılan
      isActive: activeSession.isActive,
      onOpenPressed: () {
        final data = GroupRideData(
          id: activeSession.id,
          groupName: activeSession.title,
          maxParticipants: 10,
          privacy: "Private",
          destination: "Bilinmiyor",
          ridingStyle: "Bilinmiyor",
        );
        context.push('/communication/group-page', extra: data);
      },
      riderCards: participants.take(3).map((p) {
        return RiderCard(
          firstName: p.firstName ?? '',
          lastName: p.lastName ?? '',
          profileImageUrl:
              p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
          batteryLevel: 100,
          signalLevel: 100,
          isSpeaking: p.status == 'Joined',
        );
      }).toList(),
    );
  }

  // --- Üst Buton Yardımcı Fonksiyon ---
  Widget _buildTopButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color glassTint,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: glassTint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassTint.withOpacity(0.3), width: 1),
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
