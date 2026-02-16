import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'group_page/dialogs/group_page_actions.dart';
import 'group_page/sections/group_footer_section.dart';
import 'group_page/sections/group_header_section.dart';
import 'group_page/sections/group_participants_section.dart';

// --- BACKEND BLOC & ENTITY İMPORTLARI ---
import '../../../voice_session/domain/entities/voice_session_entity.dart';

import '../../../voice_session/domain/enums/rtc_state.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../../../group_ride/domain/entities/group_ride_entity.dart';
import '../../../group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../../group_ride/presentation/bloc/group_ride_event.dart';
import '../../../group_ride/presentation/bloc/group_ride_state.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';

class GroupPage extends StatefulWidget {
  final GroupRideArgs data;

  const GroupPage({super.key, required this.data});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  // --- BACKEND STATE ---
  VoiceSessionEntity? _sessionDetails;
  GroupRideEntity? _rideDetails;
  bool _isLoadingSession = false;
  bool _isLoadingRide = false;
  // --- RTC & LIVEKIT STATE (Bloc'tan aynalanan) ---
  RtcConnectionStatus _rtcStatus = RtcConnectionStatus.disconnected;
  bool _isMicOn = true;
  Set<String> _activeSpeakers = {};
  Timer? _disconnectGuardTimer;
  int _disconnectCountdown = 60;
  bool _disconnectGuardActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.data.rideId > 0) {
      context.read<GroupRideBloc>().add(
        JoinSignalRGroupEvent(widget.data.rideId),
      );
      _loadRideDetails();
      _loadSessionDetails();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hata: Geçersiz Grup ID')));
        context.pop();
      });
    }
  }

  void _loadSessionDetails() {
    if (!mounted) return;
    final sessionId = widget.data.sessionId;
    if (sessionId == null || sessionId <= 0) {
      setState(() => _isLoadingSession = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli ses oturumu bulunamadı.')),
      );
      return;
    }

    setState(() => _isLoadingSession = true);
    final voiceBloc = context.read<VoiceSessionBloc>();
    if (voiceBloc.isClosed) return;
    voiceBloc.add(GetVoiceSessionDetailsEvent(sessionId));
  }

  void _loadRideDetails() {
    if (!mounted) return;
    setState(() => _isLoadingRide = true);
    final rideBloc = context.read<GroupRideBloc>();
    if (rideBloc.isClosed) return;
    rideBloc.add(LoadGroupRideDetailsEvent(widget.data.rideId));
  }

  void _handleInvite() {
    final sessionId = widget.data.sessionId;
    if (sessionId == null || sessionId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet için geçerli ses oturumu bulunamadı.'),
        ),
      );
      return;
    }

    context.push('/communication/invite', extra: sessionId);
  }

  void _handleOpenSettings() {
    context.push('/communication/group-settings', extra: widget.data);
  }

  void _handleBack() {
    context.pop();
  }

  void _handleRefresh() {
    _loadRideDetails();
    _loadSessionDetails();
  }

  int? _validatedSessionId({bool showMessage = false}) {
    final sessionId = widget.data.sessionId;
    final isValid = sessionId != null && sessionId > 0;
    if (!isValid && showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli ses oturumu bulunamadı.')),
      );
    }
    return isValid ? sessionId : null;
  }

  void _cancelDisconnectGuard({bool resetCounter = true}) {
    _disconnectGuardTimer?.cancel();
    _disconnectGuardTimer = null;
    if (resetCounter) {
      setState(() {
        _disconnectGuardActive = false;
        _disconnectCountdown = 60;
      });
    } else {
      setState(() => _disconnectGuardActive = false);
    }
  }

  bool _shouldStartDisconnectGuard(VoiceSessionState state) {
    final activeParticipants =
        _sessionDetails?.participants
            .where(
              (participant) =>
                  participant.status == 'Joined' ||
                  participant.status == 'Accepted' ||
                  participant.status == 'Disconnected',
            )
            .length ??
        0;

    if (activeParticipants <= 1) {
      return false;
    }

    return state.rtcStatus == RtcConnectionStatus.reconnecting ||
        state.rtcStatus == RtcConnectionStatus.disconnected;
  }

  void _startDisconnectGuard() {
    if (_disconnectGuardActive) return;

    setState(() {
      _disconnectGuardActive = true;
      _disconnectCountdown = 60;
    });

    _disconnectGuardTimer?.cancel();
    _disconnectGuardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_disconnectCountdown <= 1) {
        timer.cancel();
        _cancelDisconnectGuard();

        final sessionId = _validatedSessionId();
        if (sessionId == null) return;
        final voiceBloc = context.read<VoiceSessionBloc>();
        if (voiceBloc.isClosed) return;

        voiceBloc.add(LeaveVoiceSessionEvent(sessionId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bağlantı uzun süre kesildi. Oturumdan çıkarıldınız.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _disconnectCountdown -= 1);
    });
  }

  void _syncDisconnectGuard(VoiceSessionState state) {
    if (_shouldStartDisconnectGuard(state)) {
      _startDisconnectGuard();
      return;
    }

    if (_disconnectGuardActive) {
      _cancelDisconnectGuard();
    }
  }

  void _handleToggleMic() {
    context.read<VoiceSessionBloc>().add(const ToggleMicrophoneEvent());
  }

  bool _isCurrentUserHost(int? currentUserId) {
    return currentUserId != null &&
        _sessionDetails?.hostUserId == currentUserId;
  }

  // --- UI ACTIONS ---
  void _kickUser(int targetUserId, String userName) {
    final sessionId = _validatedSessionId(showMessage: true);
    if (sessionId == null) return;

    GroupPageActions.kickUser(
      context: context,
      sessionId: sessionId,
      targetUserId: targetUserId,
      userName: userName,
    );
  }

  void _muteUser(int targetUserId, String userName) {
    final sessionId = _validatedSessionId(showMessage: true);
    if (sessionId == null) return;

    GroupPageActions.muteUser(
      context: context,
      sessionId: sessionId,
      targetUserId: targetUserId,
      userName: userName,
    );
  }

  void _transferHost(int targetUserId, String userName) {
    final sessionId = _validatedSessionId(showMessage: true);
    if (sessionId == null) return;

    GroupPageActions.transferHost(
      context: context,
      sessionId: sessionId,
      targetUserId: targetUserId,
      userName: userName,
    );
  }

  void _showLeaveDialog() {
    GroupPageActions.showLeaveDialog(
      context: context,
      sessionDetails: _sessionDetails,
      rideId: widget.data.rideId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = context.select<VoiceSessionBloc, int?>(
      (bloc) => bloc.state.currentUserId,
    );
    final showSettingsButton = _isCurrentUserHost(currentUserId);

    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A100A), Color(0xFF12100E)],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          );

    return MultiBlocListener(
      listeners: [
        BlocListener<VoiceSessionBloc, VoiceSessionState>(
          listenWhen: (previous, current) {
            // Rebuild/Listen only when relevant parts change
            return previous.status != current.status ||
                previous.message != current.message ||
                previous.session != current.session ||
                previous.rtcStatus != current.rtcStatus ||
                previous.isLiveKitConnected != current.isLiveKitConnected ||
                previous.isMicOn != current.isMicOn ||
                previous.activeSpeakers != current.activeSpeakers ||
                previous.liveKitError != current.liveKitError;
          },
          listener: (context, state) {
            // 1. Session Details Loaded
            if (state.status == VoiceSessionStatus.detailsLoaded &&
                state.session != null) {
              setState(() {
                _sessionDetails = state.session;
                _isLoadingSession = false;
              });
              _syncDisconnectGuard(state);
            }

            // 2. Error handling
            if (state.status == VoiceSessionStatus.error &&
                state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: ${state.message}'),
                  backgroundColor: colorScheme.error,
                ),
              );
              setState(() => _isLoadingSession = false);
            }

            // 3. Left Session
            if (state.status == VoiceSessionStatus.left) {
              _cancelDisconnectGuard();
              if (context.mounted) {
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
            }

            // 4. Action Success (Transient Message)
            // Note: Since we don't have a distinct ActionSuccess status for all actions,
            // we check if message is present and status is NOT error/loading/initial.
            // Also excluding 'joined' message if handled elsewhere.
            if (state.message != null &&
                state.status != VoiceSessionStatus.error &&
                state.status != VoiceSessionStatus.loading) {
              // Optional: Show snackbar for messages like "Kullanıcı atıldı"
              // Filter out "Odaya başarıyla katılındı" if you want, or show it.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() => _isLoadingSession = false);
            }

            // 5. RTC & LiveKit State Updates
            // Always mirror Bloc state into local variables for UI
            setState(() {
              _rtcStatus = state.rtcStatus;
              _isMicOn = state.isMicOn;
              _activeSpeakers = state.activeSpeakers.toSet();
            });
            _syncDisconnectGuard(state);

            // 6. LiveKit Error
            if (state.liveKitError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('LiveKit Hatası: ${state.liveKitError}'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
        ),
        BlocListener<GroupRideBloc, GroupRideState>(
          listener: (context, state) {
            if (state is GroupRideSuccess) {
              if (state.ride.id == widget.data.rideId) {
                setState(() {
                  _rideDetails = state.ride;
                  _isLoadingRide = false;
                });
              }
            } else if (state is GroupRideLeft) {
              // 1. Leave Voice Session (Sequentially)
              if (widget.data.sessionId != null && widget.data.sessionId! > 0) {
                context.read<VoiceSessionBloc>().add(
                  LeaveVoiceSessionEvent(widget.data.sessionId!),
                );
                // DO NOT POP HERE - Wait for VoiceSessionLeft
              } else {
                // 2. No Voice Session -> Navigate Back Immediately
                if (!context.mounted) return;
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
            } else if (state is GroupRideTerminated) {
              // 1. Leave Voice Session
              if (widget.data.sessionId != null && widget.data.sessionId! > 0) {
                final voiceBloc = context.read<VoiceSessionBloc>();
                if (!voiceBloc.isClosed) {
                  voiceBloc.add(LeaveVoiceSessionEvent(widget.data.sessionId!));
                }
              } else {
                if (!context.mounted) return;
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
              // 2. Show Info
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Grup turu organizatör tarafından sonlandırıldı.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (state is GroupRideDeleted) {
              // 1. Leave Voice Session
              if (widget.data.sessionId != null && widget.data.sessionId! > 0) {
                final voiceBloc = context.read<VoiceSessionBloc>();
                if (!voiceBloc.isClosed) {
                  voiceBloc.add(LeaveVoiceSessionEvent(widget.data.sessionId!));
                }
              } else {
                if (!context.mounted) return;
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
              // 2. Show Info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Grup turu başarıyla silindi ve sonlandırıldı.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (state is GroupRideFailure) {
              setState(() => _isLoadingRide = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: ${state.message}'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: backgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                if (_disconnectGuardActive)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 18,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bağlantı zayıf, tekrar bağlanılıyor... ($_disconnectCountdown)',
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GroupHeaderSection(
                          data: widget.data,
                          rideDetails: _rideDetails,
                          sessionDetails: _sessionDetails,
                          isLoadingRide: _isLoadingRide,
                          rtcStatus: _rtcStatus,
                          isMicOn: _isMicOn,
                          onBack: _handleBack,
                          onToggleMic: _handleToggleMic,
                        ),
                        GroupParticipantsSection(
                          data: widget.data,
                          organizerId: _rideDetails?.organizerId,
                          sessionDetails: _sessionDetails,
                          isLoadingSession: _isLoadingSession,
                          currentUserId: currentUserId,
                          showSettingsButton: showSettingsButton,
                          activeSpeakers: _activeSpeakers,
                          onRefresh: _handleRefresh,
                          onInvite: _handleInvite,
                          onSettings: _handleOpenSettings,
                          onKickUser: _kickUser,
                          onMuteUser: _muteUser,
                          onTransferHost: _transferHost,
                        ),
                      ],
                    ),
                  ),
                ),
                GroupFooterSection(
                  colorScheme: colorScheme,
                  onLeave: _showLeaveDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disconnectGuardTimer?.cancel();
    super.dispose();
  }
}
