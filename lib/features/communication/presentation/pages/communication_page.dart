import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../voice_session/domain/entities/voice_session_entity.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
// import '../../domain/entities/group_ride_data.dart';
// import '../bloc/group_ride_bloc.dart';
// import '../bloc/group_ride_event.dart';
// import '../bloc/group_ride_state.dart';
import '../widgets/active_group.dart';
import '../widgets/nearby_group.dart';
import '../widgets/rider_card.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  List<VoiceSessionEntity> _mySessions = [];
  bool _isLoadingSessions = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMySessions();
  }

  Future<void> _loadCurrentUser() async {
    final authLocal = sl<AuthLocalDataSource>();
    final userId = await authLocal.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _loadMySessions() {
    context.read<VoiceSessionBloc>().add(const GetMyVoiceSessionsEvent());
  }

  // --- MODERATION ACTIONS ---
  void _kickUser(int targetUserId, String userName, int sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı At'),
        content: Text('$userName adlı kullanıcıyı atmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                KickUserEvent(sessionId, targetUserId),
              );
            },
            child: const Text('At', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _muteUser(int targetUserId, String userName, int sessionId) {
    context.read<VoiceSessionBloc>().add(
      MuteUserEvent(sessionId, targetUserId),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$userName susturuldu')));
  }

  void _transferHost(int targetUserId, String userName, int sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liderlik Devret'),
        content: Text(
          '$userName adlı kullanıcıya liderliği devretmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                TransferHostEvent(sessionId, targetUserId),
              );
            },
            child: const Text('Devret', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
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
            // Sadece aktif oturumları göster (isActive = true)
            _mySessions = state.sessions
                .cast<VoiceSessionEntity>()
                .where((s) => s.isActive)
                .toList();
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
                            onTap: () async {
                              await context.push(
                                '/communication/create-group-ride',
                              );
                              if (mounted) _loadMySessions();
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

                    // --- 5. NEARBY GROUPS LİSTESİ (Dummy UI) ---
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NearbyGroupCard(
                            groupName: "Weekend Riders",
                            distance: "1.2 km",
                            currentParticipants: 3,
                            maxParticipants: 10,
                            signalStatus: "Strong",
                            onJoinPressed: () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NearbyGroupCard(
                            groupName: "Mountain Tour",
                            distance: "5.4 km",
                            currentParticipants: 8,
                            maxParticipants: 12,
                            signalStatus: "Good",
                            onJoinPressed: () {},
                          ),
                        ),
                      ],
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
        .where(
          (p) =>
              p.status == 'Joined' ||
              p.status == 'Accepted' ||
              p.status == 'Disconnected',
        )
        .toList();

    return ActiveGroupCard(
      groupName: activeSession.title,
      currentParticipants: activeSession.activeParticipantCount,
      maxParticipants: activeSession.maxParticipants,
      destination: activeSession.destination,
      ridingStyle: activeSession.ridingStyle,
      difficulty: activeSession.difficulty,
      isActive: activeSession.isActive,
      onOpenPressed: () async {
        final args = GroupRideArgs(
          rideId: activeSession.groupRideId ?? activeSession.id,
          voiceSessionId: activeSession.id,
          groupName: activeSession.title,
          maxParticipants: activeSession.maxParticipants,
          currentParticipants: activeSession.activeParticipantCount,
          organizerId: activeSession.hostUserId,
        );
        final result = await context.push<bool>(
          '/communication/group-page',
          extra: args,
        );

        if (result == true) {
          // Force clear and reload
          setState(() {
            _mySessions = [];
            _isLoadingSessions = true;
          });
          // Increased delay to ensure backend consistency (1500ms)
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) _loadMySessions();
        } else {
          _loadMySessions();
        }
      },
      riderCards: participants.map((p) {
        final isConnected = p.status == 'Joined';
        final isMe = p.userId == _currentUserId;

        // Viewer Role Determination
        RiderRole viewerRole = RiderRole.participant;
        if (_currentUserId != null &&
            activeSession.hostUserId == _currentUserId) {
          viewerRole = RiderRole.organizer;
        }

        // Target Role Determination
        RiderRole targetRole = RiderRole.participant;
        if (p.userId == activeSession.hostUserId) {
          targetRole = RiderRole.organizer;
        }

        return RiderCard(
          firstName: p.firstName ?? '',
          lastName: p.lastName ?? '',
          profileImageUrl:
              p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
          batteryLevel: isConnected ? 90 : 0,
          signalLevel: isConnected ? 100 : 0,
          isMicOn: isConnected,
          isSpeaking: isConnected,
          isConnected: isConnected,
          isMe: isMe,
          role: targetRole,
          viewerRole: viewerRole,
          onKickUser: (viewerRole == RiderRole.organizer && !isMe)
              ? () => _kickUser(
                  p.userId,
                  p.firstName ?? 'Kullanıcı',
                  activeSession.id,
                )
              : null,
          onMuteUser: (viewerRole == RiderRole.organizer && !isMe)
              ? () => _muteUser(
                  p.userId,
                  p.firstName ?? 'Kullanıcı',
                  activeSession.id,
                )
              : null,
          onTransferHost: (viewerRole == RiderRole.organizer && !isMe)
              ? () => _transferHost(
                  p.userId,
                  p.firstName ?? 'Kullanıcı',
                  activeSession.id,
                )
              : null,
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
