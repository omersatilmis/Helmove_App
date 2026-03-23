import 'dart:async';

import 'package:moto_comm_app_1/features/intercom/domain/intercom_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:moto_comm_app_1/core/widgets/app_background.dart';

import 'group_page/dialogs/group_page_actions.dart';
import 'group_page/sections/group_footer_section.dart';
import 'group_page/sections/group_header_section.dart';
import 'group_page/sections/group_participants_section.dart';
import '../../../../core/services/connectivity_watcher_service.dart';

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
import '../../../../core/navigation/base_navigation_args.dart';
import '../../../../core/mixins/navigation_guard_mixin.dart';
import '../../../attendance_management/domain/entities/group_role.dart';

class GroupPage extends StatefulWidget {
  final GroupRideArgs data;

  const GroupPage({super.key, required this.data});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage>
    with NavigationGuardMixin<GroupPage> {
  static const Duration _refreshCooldown = Duration(milliseconds: 1500);
  @override
  BaseNavigationArgs? get args => widget.data;

  // --- BACKEND STATE ---
  VoiceSessionEntity? _sessionDetails;
  GroupRideEntity? _rideDetails;
  int? _resolvedRideId;
  bool _isLoadingSession = false;
  bool _isLoadingRide = false;
  bool _isResolvingRideId = false;
  // --- RTC & LIVEKIT STATE (Bloc'tan aynalanan) ---
  RtcConnectionStatus _rtcStatus = RtcConnectionStatus.disconnected;
  bool _isMicOn = true;
  Set<String> _activeSpeakers = {};
  Map<int, IntercomConnectionQuality> _participantQualities = {};
  StreamSubscription<ConnectionStatus>? _connectivityWatcherSub;
  Timer? _refreshCooldownTimer;
  bool _isRefreshDisabled = false;
  String? _lastVoiceErrorMessage;
  String? _lastVoiceInfoMessage;
  bool _didNavigateAway = false;

  @override
  void initState() {
    super.initState();
    unawaited(di.ensureCommunicationRuntimeStarted());

    final hasRideId = widget.data.rideId > 0;
    final hasSessionId = (widget.data.sessionId ?? 0) > 0;
    if (!hasRideId && !hasSessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hata: Geçersiz Grup ID')));
        context.pop();
      });
      return;
    }

    _isResolvingRideId = !hasRideId && hasSessionId;
    _isLoadingRide = true;

    context.read<GroupRideBloc>().add(
      InitializeGroupRideEvent(
        rideId: widget.data.rideId,
        sessionId: widget.data.sessionId,
      ),
    );

    if (hasSessionId) {
      _loadSessionDetails();
    }
    _initConnectivityWatcher();
  }

  int get _effectiveRideId =>
      _resolvedRideId ?? _rideDetails?.id ?? widget.data.rideId;

  void _loadSessionDetails() {
    if (!mounted) return;
    final sessionId = _sessionDetails?.id ?? widget.data.sessionId;
    if (sessionId == null || sessionId <= 0) {
      setState(() => _isLoadingSession = false);
      // Valid case: there may be no session yet, just a ride.
      return;
    }

    setState(() => _isLoadingSession = true);
    final voiceBloc = context.read<VoiceSessionBloc>();
    if (voiceBloc.isClosed) return;
    voiceBloc.add(
      GetVoiceSessionDetailsEvent(sessionId, force: true, immediate: true),
    );
  }

  void _loadRideDetails() {
    if (!mounted) return;
    final rideId = _effectiveRideId;
    if (rideId <= 0) {
      return;
    }
    setState(() => _isLoadingRide = true);
    final rideBloc = context.read<GroupRideBloc>();
    if (rideBloc.isClosed) return;
    rideBloc.add(LoadGroupRideDetailsEvent(rideId, force: true));
  }

  void _handleInvite() {
    // _sessionDetails varsa önce onu kullan (oda yeni kurulduysa widget.data henüz güncel olmayabilir)
    final sessionId = _sessionDetails?.id ?? widget.data.sessionId;
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

  Future<void> _handleOpenSettings() async {
    await context.push('/communication/group-settings', extra: widget.data);
  }

  void _handleBack() {
    if (widget.data.forceBackToCommunication) {
      context.go('/communication');
      return;
    }
    context.pop();
  }

  void _handleRefresh() {
    if (_isRefreshDisabled) {
      return;
    }

    setState(() => _isRefreshDisabled = true);
    _refreshCooldownTimer?.cancel();
    _refreshCooldownTimer = Timer(_refreshCooldown, () {
      if (mounted) {
        setState(() => _isRefreshDisabled = false);
      }
    });

    _loadRideDetails();
    _loadSessionDetails();
  }

  int? _validatedSessionId({bool showMessage = false}) {
    // _sessionDetails varsa önce onu kullan, fallback olarak widget.data
    final sessionId = _sessionDetails?.id ?? widget.data.sessionId;
    final isValid = sessionId != null && sessionId > 0;
    if (!isValid && showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesli oturuma ulaşılamıyor. Sadece sürüş detayları aktif.',
          ),
        ),
      );
    }
    return isValid ? sessionId : null;
  }

  void _initConnectivityWatcher() {
    // ConnectivityWatcher generic "disconnected" state emits for internet loss.
    // However, IntercomEngine has its own robustness (60s TTL).
    // We let IntercomEngine handle the reconnection logic instead of
    // effectively kicking the user out immediately via the UI.
    //
    // _connectivityWatcherSub = sl<ConnectivityWatcherService>().statusStream
    //     .listen((status) {
    //       if (status.type == ConnectionStatusType.failed) {
    //         _handleSessionTimeout();
    //       }
    //     });
  }

  void _handleToggleMic() {
    context.read<VoiceSessionBloc>().add(const ToggleMicrophoneEvent());
  }

  bool _canAccessSettings(int? currentUserId) {
    if (currentUserId == null || _sessionDetails == null) return false;

    // Admin her zaman erişebilir
    if (_sessionDetails!.adminId == currentUserId) return true;

    // Participant listesinden current user'ı bul ve role'ünü kontrol et
    final currentParticipant = _sessionDetails!.participants
        .where((p) => p.userId == currentUserId)
        .firstOrNull;

    if (currentParticipant == null) return false;

    // Admin veya Captain ise erişebilir
    return currentParticipant.role == GroupRole.admin ||
        currentParticipant.role == GroupRole.captain;
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

  // Transfer Captain (oturum liderliği)
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

  void _promoteUser(int targetUserId, String userName) {
    final sessionId = _validatedSessionId(showMessage: true);
    if (sessionId == null) return;
    GroupPageActions.promoteUser(
      context: context,
      sessionId: sessionId,
      targetUserId: targetUserId,
      userName: userName,
    );
  }

  void _demoteUser(int targetUserId, String userName) {
    final sessionId = _validatedSessionId(showMessage: true);
    if (sessionId == null) return;
    GroupPageActions.demoteUser(
      context: context,
      sessionId: sessionId,
      targetUserId: targetUserId,
      userName: userName,
    );
  }

  void _showLeaveDialog() {
    final rideId = _effectiveRideId;
    if (rideId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sürüş bilgisi hazırlanıyor...')),
      );
      return;
    }
    final sessionId = _sessionDetails?.id ?? widget.data.sessionId;
    GroupPageActions.showLeaveDialog(
      context: context,
      sessionDetails: _sessionDetails,
      rideId: rideId,
      sessionId: sessionId,
    );
  }

  void _exitGroupPage({String? message, Color? backgroundColor}) {
    if (!mounted || _didNavigateAway) return;
    _didNavigateAway = true;

    final trimmedMessage = message?.trim();
    if (trimmedMessage != null && trimmedMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trimmedMessage),
          backgroundColor: backgroundColor,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.data.forceBackToCommunication) {
        context.go('/communication');
        return;
      }
      if (Navigator.of(context).canPop()) {
        context.pop(true);
      } else {
        context.go('/communication');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.select<VoiceSessionBloc, int?>(
      (bloc) => bloc.state.currentUserId,
    );
    final showSettingsButton = _canAccessSettings(currentUserId);


    final isHydrated = _effectiveRideId > 0 && _rideDetails != null;
    final showResolvingLoader = _isResolvingRideId || !isHydrated;

    return PopScope(
      canPop: !widget.data.forceBackToCommunication,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.data.forceBackToCommunication && mounted) {
          context.go('/communication');
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<VoiceSessionBloc, VoiceSessionState>(
            listenWhen: (previous, current) {
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
              if (state.status == VoiceSessionStatus.detailsLoaded &&
                  state.session != null) {
                setState(() {
                  _sessionDetails = state.session;
                  _isLoadingSession = false;
                });
              }

              if (state.status == VoiceSessionStatus.error &&
                  state.message != null) {
                final errorMessage = state.message!.trim();
                if (errorMessage.isNotEmpty &&
                    _lastVoiceErrorMessage != errorMessage) {
                  _lastVoiceErrorMessage = errorMessage;
                  if (!_didNavigateAway) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $errorMessage'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
                setState(() => _isLoadingSession = false);
              }

              if (state.status == VoiceSessionStatus.left) {
                _exitGroupPage();
              }

              if (state.message != null &&
                  state.status != VoiceSessionStatus.error &&
                  state.status != VoiceSessionStatus.loading) {
                final infoMessage = state.message!.trim();
                final shouldShowInfoMessage =
                    infoMessage.isNotEmpty &&
                    _lastVoiceInfoMessage != infoMessage;
                if (shouldShowInfoMessage) {
                  _lastVoiceInfoMessage = infoMessage;
                  if (!_didNavigateAway) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(infoMessage),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
                setState(() => _isLoadingSession = false);
              } else if (state.status == VoiceSessionStatus.loading ||
                  state.status == VoiceSessionStatus.error) {
                _lastVoiceInfoMessage = null;
              }

              setState(() {
                _rtcStatus = state.rtcStatus;
                _isMicOn = state.isMicOn;
                _activeSpeakers = state.activeSpeakers.toSet();
                _participantQualities = state.participantQualities;
              });

              if (state.liveKitError != null && !_didNavigateAway) {
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
              if (_didNavigateAway) return;

              if (state is GroupRideResolvingId) {
                if (state.sessionId == widget.data.sessionId) {
                  setState(() {
                    _isResolvingRideId = true;
                    _isLoadingRide = true;
                  });
                }
              } else if (state is GroupRideSuccess) {
                setState(() {
                  _rideDetails = state.ride;
                  _resolvedRideId = state.ride.id;
                  _isResolvingRideId = false;
                  _isLoadingRide = false;
                });
              } else if (state is GroupRideDeleted) {
                final rideId = _effectiveRideId;
                if (state.rideId == null || state.rideId == rideId) {
                  context.read<VoiceSessionBloc>().add(
                    const TeardownVoiceSessionLocalEvent(),
                  );
                  _exitGroupPage(
                    message: 'Grup sürüşü sonlandırıldı.',
                    backgroundColor: Colors.green,
                  );
                }
              } else if (state is GroupRideTerminated) {
                final rideId = _effectiveRideId;
                if (state.rideId == null || state.rideId == rideId) {
                  context.read<VoiceSessionBloc>().add(
                    const TeardownVoiceSessionLocalEvent(),
                  );
                  setState(() => _isLoadingRide = false);
                  _exitGroupPage(
                    message: 'Sürüş organizatör tarafından sonlandırıldı.',
                    backgroundColor: colorScheme.error,
                  );
                }
              } else if (state is GroupRideLeft) {
                final rideId = _effectiveRideId;
                if (state.rideId == null || state.rideId == rideId) {
                  context.read<VoiceSessionBloc>().add(
                    const TeardownVoiceSessionLocalEvent(),
                  );

                  setState(() => _isLoadingRide = false);
                  _exitGroupPage(message: 'Gruptan ayrıldınız.');
                }
              } else if (state is GroupRideFailure) {
                setState(() {
                  _isResolvingRideId = false;
                  _isLoadingRide = false;
                });
                if (!_didNavigateAway) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: ${state.message}'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
        child: AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  // Redundant local banner removed (it's now in ConnectionStatusOverlay)
                  Expanded(
                    child: Stack(
                      children: [
                        AnimatedOpacity(
                          opacity: showResolvingLoader ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 280),
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
                                  onBack: _handleBack,
                                ),
                                GroupParticipantsSection(
                                  data: widget.data,
                                  sessionDetails: _sessionDetails,
                                  isLoadingSession: _isLoadingSession,
                                  currentUserId: currentUserId,
                                  showSettingsButton: showSettingsButton,
                                  activeSpeakers: _activeSpeakers,
                                  participantQualities: _participantQualities,
                                  isCurrentUserMicOn: _isMicOn,
                                  onToggleMic: _handleToggleMic,
                                  onRefresh: _isRefreshDisabled
                                      ? null
                                      : _handleRefresh,
                                  onInvite: _handleInvite,
                                  onSettings: _handleOpenSettings,
                                  onKickUser: _kickUser,
                                  onMuteUser: _muteUser,
                                  onTransferHost: _transferHost,
                                  onPromote: _promoteUser,
                                  onDemote: _demoteUser,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showResolvingLoader)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Grup bilgileri hazırlanıyor...',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
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
      ),
    );
  }

  @override
  void dispose() {
    _connectivityWatcherSub?.cancel();
    _refreshCooldownTimer?.cancel();
    super.dispose();
  }
}
