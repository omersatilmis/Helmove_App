import 'dart:async';
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

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  List<VoiceSessionEntity> _mySessions = [];
  bool _isLoadingSessions = true;

  bool _isPendingInviteForCurrentUser(
    VoiceSessionEntity session,
    int? currentUserId,
  ) {
    if (currentUserId == null) return false;
    return session.participants.any(
      (participant) =>
          participant.userId == currentUserId &&
          participant.status == 'Invited',
    );
  }

  DateTime? _lastLoadTime;
  Timer? _throttleTimer;
  bool _pendingRefresh = false;

  @override
  void initState() {
    super.initState();
    _loadMySessions();
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _loadMySessions() {
    if (!mounted) return;
    final bloc = context.read<VoiceSessionBloc>();
    if (bloc.isClosed) return;

    // 1. Guard: Loading check
    if (bloc.state.status == VoiceSessionStatus.loading) {
      debugPrint(
        "⚠️ [CommunicationPage] Refresh ignored: Bloc is already loading.",
      );
      return;
    }

    final now = DateTime.now();
    const throttleDuration = Duration(seconds: 2);

    // 2. Throttle check
    if (_lastLoadTime != null) {
      final difference = now.difference(_lastLoadTime!);
      if (difference < throttleDuration) {
        // Hysteresis: Mark as pending and schedule if not already scheduled
        debugPrint(
          "⏳ [CommunicationPage] Refresh throttled. Scheduled for later.",
        );
        _pendingRefresh = true;

        if (_throttleTimer == null || !_throttleTimer!.isActive) {
          final remaining = throttleDuration - difference;
          _throttleTimer = Timer(remaining, () {
            if (mounted && _pendingRefresh) {
              _executeLoadSessions();
              _pendingRefresh = false;
            }
          });
        }
        return;
      }
    }

    // 3. Execute
    _executeLoadSessions();
  }

  void _executeLoadSessions() {
    if (!mounted) return;
    final bloc = context.read<VoiceSessionBloc>();
    if (bloc.isClosed) return;

    debugPrint("🚀 [CommunicationPage] Sending GetMyVoiceSessionsEvent...");
    _lastLoadTime = DateTime.now();
    bloc.add(const GetMyVoiceSessionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = context.select<VoiceSessionBloc, int?>(
      (bloc) => bloc.state.currentUserId,
    );
    final pendingInviteCount = _mySessions
        .where(
          (session) => _isPendingInviteForCurrentUser(session, currentUserId),
        )
        .length;

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
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return BlocListener<VoiceSessionBloc, VoiceSessionState>(
      listener: (context, state) {
        if (state.status == VoiceSessionStatus.mySessionsLoaded &&
            state.mySessions != null) {
          setState(() {
            // Sadece aktif oturumları göster (isActive = true)
            _mySessions = state.mySessions!
                .cast<VoiceSessionEntity>()
                .where((s) => s.isActive)
                .toList();
            _isLoadingSessions = false;
          });
        } else if (state.status == VoiceSessionStatus.error) {
          setState(() => _isLoadingSessions = false);
        } else if (state.status == VoiceSessionStatus.loading) {
          if (_mySessions.isEmpty) {
            setState(() => _isLoadingSessions = true);
          }
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
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: colorScheme.onSurface,
                                size: 20,
                              ),
                              tooltip: 'Refresh',
                              onPressed: _loadMySessions,
                            ),
                          ],
                        ),
                        // --- SOS Acil Durum Butonu ---
                        GestureDetector(
                          onTap: () {
                            debugPrint("SOS Gönderildi!");
                          },
                          child: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.error,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
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

                    if (pendingInviteCount > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mark_email_unread_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$pendingInviteCount pending invite${pendingInviteCount > 1 ? 's' : ''}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/notifications'),
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // --- 3. ACTIVE GROUP KARTI (VoiceSession'dan yüklenir) ---
                    _buildActiveSessionCard(colorScheme),

                    const SizedBox(height: 30),

                    // --- 4. NEARBY GROUPS BAŞLIĞI ---
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
    final currentUserId = context.select<VoiceSessionBloc, int?>(
      (bloc) => bloc.state.currentUserId,
    );

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
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
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
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
          rideId: activeSession.rideId ?? activeSession.id,
          sessionId: activeSession.id,
          groupName: activeSession.title,
          maxParticipants: activeSession.maxParticipants,
          currentParticipants: activeSession.activeParticipantCount,
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
          if (mounted) _loadMySessions();
        }
      },
      riderCards: participants.map((p) {
        final isConnected = p.status == 'Joined' || p.status == 'Accepted';
        final isMe = p.userId == currentUserId;

        // Viewer Role Determination
        RiderRole viewerRole = RiderRole.participant;
        if (currentUserId != null &&
            activeSession.hostUserId == currentUserId) {
          viewerRole = RiderRole.host;
        }

        // Target Role Determination
        RiderRole targetRole = RiderRole.participant;
        if (p.userId == activeSession.hostUserId) {
          targetRole = RiderRole.host;
        }

        return RiderCard(
          firstName: p.firstName ?? '',
          lastName: p.lastName ?? '',
          profileImageUrl:
              p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
          phoneBatteryLevel: p.phoneBatteryLevel,
          intercomBatteryLevel: p.intercomBatteryLevel,
          signalStrength: p.signalStrength,
          isMicOn: isConnected,
          isSpeaking: isConnected,
          isConnected: isConnected,
          isMe: isMe,
          role: targetRole,
          viewerRole: viewerRole,
          onKickUser: null,
          onMuteUser: null,
          onTransferHost: null,
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
              color: glassTint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: glassTint.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
