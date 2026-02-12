import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- P2P CALL İMPORTLARI ---
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../call/presentation/bloc/call_event.dart';
import '../../../call/presentation/bloc/call_state.dart';

// --- PROJE İMPORTLARI ---
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../widgets/rider_card.dart';

// --- BACKEND BLOC & ENTITY İMPORTLARI ---
import '../../../voice_session/domain/entities/voice_session_entity.dart';

import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../../../group_ride/domain/entities/group_ride_entity.dart';
import '../../../group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../../group_ride/presentation/bloc/group_ride_event.dart';
import '../../../group_ride/presentation/bloc/group_ride_state.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';

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
  int? _currentUserId;
  Timer? _p2pDebounceTimer;

  /// P2P modunda mı? (2 kişi odada)
  /// P2P modunda mı? (2 kişi odada)
  bool _isP2PMode = false;

  // --- LIVEKIT STATE ---
  bool _isLiveKitConnected = false;
  bool _isMicOn = true;
  Set<String> _activeSpeakers = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  Future<void> _loadCurrentUser() async {
    final authLocal = sl<AuthLocalDataSource>();
    final userId = await authLocal.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _loadSessionDetails() {
    setState(() => _isLoadingSession = true);
    context.read<VoiceSessionBloc>().add(
      GetVoiceSessionDetailsEvent(
        widget.data.voiceSessionId ?? widget.data.rideId,
      ),
    );
  }

  void _loadRideDetails() {
    setState(() => _isLoadingRide = true);
    context.read<GroupRideBloc>().add(
      LoadGroupRideDetailsEvent(widget.data.rideId),
    );
  }

  // --- UI ACTIONS ---
  void _kickUser(int targetUserId, String userName) {
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
                KickUserEvent(
                  widget.data.voiceSessionId ?? widget.data.rideId,
                  targetUserId,
                ),
              );
            },
            child: const Text('At', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _muteUser(int targetUserId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Sustur'),
        content: Text('$userName adlı kullanıcıyı susturmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoiceSessionBloc>().add(
                MuteUserEvent(
                  widget.data.voiceSessionId ?? widget.data.rideId,
                  targetUserId,
                ),
              );
            },
            child: const Text('Sustur'),
          ),
        ],
      ),
    );
  }

  void _transferHost(int targetUserId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Host Yetkisini Devret'),
        content: Text(
          'Host yetkisini $userName adlı kullanıcıya devretmek istiyor musunuz?',
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
                TransferHostEvent(
                  widget.data.voiceSessionId ?? widget.data.rideId,
                  targetUserId,
                ),
              );
            },
            child: const Text('Devret'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    // 1. Host Check
    final isHost = _sessionDetails?.hostUserId == _currentUserId;

    // 2. Participant Check (Count > 1 means Host + Others)
    final participants = _sessionDetails?.participants ?? [];
    final activeCount = participants
        .where((p) => p.status == 'Joined' || p.status == 'Accepted')
        .length;
    final hasOthers = activeCount > 1;

    // 3. Decision
    if (isHost && hasOthers) {
      _showSmartLeaveDialog();
    } else {
      _showStandardLeaveDialog();
    }
  }

  void _showStandardLeaveDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text('Odadan Ayrıl', style: AppTextStyles.h3),
        content: Text(
          'Bu sürüş grubundan ayrılmak istediğinize emin misiniz?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave();
            },
            child: Text(
              'Ayrıl',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSmartLeaveDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text('Gruptan Ayrılıyor musunuz?', style: AppTextStyles.h3),
        content: Text('Ne yapmak istersiniz?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Cancel
            child: Text(
              'İptal',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          // Option 1: Leave & Transfer (Orange)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLeave(); // Backend handles transfer automatically
            },
            child: Text(
              'Ayrıl & Devret',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Option 2: Terminate (Red)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performTerminate();
            },
            child: Text(
              'Grubu Sonlandır',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performLeave() {
    final id = widget.data.rideId;
    if (id > 0) {
      context.read<GroupRideBloc>().add(LeaveGroupRideEvent(id));
    } else {
      context.pop();
    }
  }

  void _performTerminate() {
    final id = widget.data.rideId;
    if (id > 0) {
      context.read<GroupRideBloc>().add(DeleteGroupRideEvent(id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
              colorScheme.primary.withOpacity(0.05),
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

              // --- AUTO JOIN LOGIC (SAFE) ---
              if (_currentUserId != null) {
                final matchingParticipants = state.session!.participants.where(
                  (p) => p.userId == _currentUserId,
                );

                if (matchingParticipants.isNotEmpty) {
                  final myParticipant = matchingParticipants.first;
                  if (myParticipant.status == 'Accepted' ||
                      myParticipant.status == 'Joined') {
                    // Check active participant count (Joined/Accepted/Disconnected)
                    final activeParticipantsCount = state.session!.participants
                        .where(
                          (p) =>
                              p.status == 'Joined' ||
                              p.status == 'Accepted' ||
                              p.status == 'Disconnected',
                        )
                        .length;

                    // Condition 1: Not already connected
                    // Condition 2: Not in P2P mode (implicitly covered by count check, but safe to keep)
                    // Condition 3: Ride ID exists
                    // Condition 4: Room name is valid
                    // Condition 5: More than 2 participants (LiveKit Threshold)
                    if (!state.isLiveKitConnected &&
                        !_isP2PMode &&
                        widget.data.rideId > 0 &&
                        state.session!.roomName.isNotEmpty &&
                        state.liveKitError ==
                            null && // Stop infinite loop on error
                        activeParticipantsCount > 2) {
                      debugPrint(
                        "🚀 [GroupPage] Auto-Connecting to LiveKit: ${state.session!.id} | Room: '${state.session!.roomName}' | Count: $activeParticipantsCount",
                      );
                      context.read<VoiceSessionBloc>().add(
                        ConnectToLiveKitEvent(
                          state.session!.roomName,
                          displayName:
                              '${myParticipant.firstName} ${myParticipant.lastName}',
                        ),
                      );
                    } else if (activeParticipantsCount <= 2) {
                      debugPrint(
                        "ℹ️ [GroupPage] Waiting for more participants or P2P logic (Count: $activeParticipantsCount)",
                      );
                    }
                  }
                }

                // --- P2P AUTO-SWITCH DETECTION ---
                final activeParticipants = state.session!.participants
                    .where(
                      (p) =>
                          p.status == 'Joined' ||
                          p.status == 'Accepted' ||
                          p.status == 'Disconnected',
                    )
                    .toList();

                final shouldBeP2P = activeParticipants.length == 2;

                if (shouldBeP2P && !_isP2PMode) {
                  // DEBOUNCE LOGIC (5 Seconds Delay)
                  if (_p2pDebounceTimer != null &&
                      _p2pDebounceTimer!.isActive) {
                    // Timer zaten çalışıyor, bekle...
                    debugPrint("⏳ [GroupPage] P2P Debounce active, waiting...");
                  } else {
                    debugPrint(
                      "⏳ [GroupPage] Starting 5s Timer for P2P Switch...",
                    );
                    _p2pDebounceTimer = Timer(const Duration(seconds: 5), () {
                      if (!mounted) return;

                      // 5 saniye sonra hala 2 kişi miyiz kontrol et:
                      final currentSession =
                          _sessionDetails; // State'den güncel al
                      if (currentSession == null) return;

                      final currentActive = currentSession.participants
                          .where(
                            (p) =>
                                p.status == 'Joined' ||
                                p.status == 'Accepted' ||
                                p.status == 'Disconnected',
                          )
                          .toList();

                      if (currentActive.length == 2) {
                        setState(() => _isP2PMode = true);
                        final otherParticipant = currentActive.firstWhere(
                          (p) => p.userId != _currentUserId,
                        );
                        debugPrint(
                          "📞 [GroupPage] P2P Mode Activated (After Delay) → with: ${otherParticipant.userId}",
                        );

                        // Polite Caller Strategy
                        if (_currentUserId != null &&
                            _currentUserId! < otherParticipant.userId) {
                          debugPrint(
                            "📞 [GroupPage] I am the CALLER (My ID: $_currentUserId < Other ID: ${otherParticipant.userId})",
                          );
                          try {
                            context.read<CallBloc>().add(
                              CallRequested(
                                targetUserId: otherParticipant.userId,
                                targetDisplayName: otherParticipant.displayName,
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                              '⚠️ [GroupPage] CallBloc not available: $e',
                            );
                          }
                        } else {
                          debugPrint(
                            "⏳ [GroupPage] I am the CALLEE (My ID: $_currentUserId > Other ID: ${otherParticipant.userId}). Waiting for call...",
                          );
                        }
                      } else {
                        debugPrint(
                          "🚫 [GroupPage] P2P Switch Aborted: Participant count changed to ${currentActive.length}",
                        );
                      }
                    });
                  }
                } else if (!shouldBeP2P && _isP2PMode) {
                  _p2pDebounceTimer
                      ?.cancel(); // Mod değiştiyse timer'ı iptal et
                  setState(() => _isP2PMode = false);
                  debugPrint(
                    "📞 [GroupPage] P2P Mode Deactivated → switching to SFU",
                  );
                  // P2P Arama Sonlandır
                  context.read<CallBloc>().add(const CallHangUp());

                  if (!state.isLiveKitConnected) {
                    final myParticipant = state.session!.participants
                        .firstWhere(
                          (p) => p.userId == _currentUserId,
                          orElse: () => state.session!.participants.first,
                        );
                    context.read<VoiceSessionBloc>().add(
                      ConnectToLiveKitEvent(
                        state.session!.roomName,
                        displayName:
                            '${myParticipant.firstName} ${myParticipant.lastName}',
                      ),
                    );
                  }
                }

                if (_isP2PMode && state.isLiveKitConnected) {
                  debugPrint(
                    "📞 [GroupPage] Disconnecting LiveKit due to P2P Mode",
                  );
                  context.read<VoiceSessionBloc>().add(
                    const DisconnectFromLiveKitEvent(),
                  );
                }
              }
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

            // 5. LiveKit State Updates
            // Always update local state from Bloc state
            setState(() {
              _isLiveKitConnected = state.isLiveKitConnected;
              _isMicOn = state.isMicOn;
              _activeSpeakers = state.activeSpeakers.toSet();
            });

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
              if (widget.data.voiceSessionId != null &&
                  widget.data.voiceSessionId! > 0) {
                context.read<VoiceSessionBloc>().add(
                  LeaveVoiceSessionEvent(widget.data.voiceSessionId!),
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
              if (widget.data.voiceSessionId != null &&
                  widget.data.voiceSessionId! > 0) {
                context.read<VoiceSessionBloc>().add(
                  LeaveVoiceSessionEvent(widget.data.voiceSessionId!),
                );
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

              if (context.mounted) {
                // Navigate to Homepage to ensure clean state
                context.go('/homepage');
              }
            } else if (state is GroupRideDeleted) {
              // 1. Leave Voice Session
              if (widget.data.voiceSessionId != null &&
                  widget.data.voiceSessionId! > 0) {
                context.read<VoiceSessionBloc>().add(
                  LeaveVoiceSessionEvent(widget.data.voiceSessionId!),
                );
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
              // 3. Navigate Away
              if (context.mounted) {
                // Navigate to Homepage to ensure clean state
                context.go('/homepage');
              }
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
        BlocListener<CallBloc, CallState>(
          listener: (context, state) {
            if (state is CallIncoming) {
              debugPrint(
                "📞 [GroupPage] Incoming P2P Call -> Auto Accepting...",
              );
              context.read<CallBloc>().add(const CallAccepted());
            } else if (state is CallEnded) {
              debugPrint("📞 [GroupPage] Call Ended: ${state.reason}");
            } else if (state is CallError) {
              debugPrint("❌ [GroupPage] Call Error: ${state.message}");
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, colorScheme),
                        if (_isLoadingRide && _rideDetails == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildMetaItem(
                              context,
                              Icons.map,
                              "Rota: ${_rideDetails?.endLocation ?? widget.data.destination ?? 'Bilinmiyor'}",
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              Icons.bolt,
                              _rideDetails?.ridingStyle ??
                                  widget.data.ridingStyle ??
                                  'Bilinmiyor',
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              Icons.bar_chart,
                              _rideDetails?.difficulty ?? 'Bilinmiyor',
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              (_rideDetails?.isPrivate ??
                                      (widget.data.privacy == "Private"))
                                  ? Icons.lock
                                  : Icons.public,
                              (_rideDetails?.isPrivate ??
                                      (widget.data.privacy == "Private"))
                                  ? "Private"
                                  : "Public",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildIntercomBanner(),
                        const SizedBox(height: 30),
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
                                AppFrostedButton(
                                  icon: Icons.person_add,
                                  size: 40,
                                  iconSize: 20,
                                  onTap: () {
                                    context.push(
                                      '/communication/invite',
                                      extra: widget.data.rideId,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                AppFrostedButton(
                                  icon: Icons.refresh,
                                  size: 40,
                                  iconSize: 20,
                                  onTap: () {
                                    if (widget.data.rideId > 0) {
                                      _loadSessionDetails();
                                    }
                                  },
                                ),
                                if (_currentUserId != null &&
                                    _sessionDetails?.hostUserId ==
                                        _currentUserId) ...[
                                  const SizedBox(width: 12),
                                  AppFrostedButton(
                                    icon: Icons.settings,
                                    size: 40,
                                    iconSize: 20,
                                    onTap: () {
                                      context.push(
                                        '/communication/group-settings',
                                        extra: widget.data,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoadingSession
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _buildParticipantList(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppFrostedButton(
          icon: Icons.arrow_back,
          size: 44,
          onTap: () => context.pop(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _rideDetails?.title ??
                  _sessionDetails?.title ??
                  widget.data.groupName,
              style: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.data.sessionDuration ?? "00:00",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.circle,
                  size: 4,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_sessionDetails?.activeParticipantCount ?? (widget.data.currentParticipants ?? 0)} / ${_rideDetails?.maxParticipants ?? widget.data.maxParticipants ?? 0}",
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
    );
  }

  Widget _buildIntercomBanner() {
    // Sol Taraf: Intercom Active (Sabit Yeşil)
    const intercomColor = Color(0xFF22C55E);

    // Sağ Taraf: Bağlantı Tipi (P2P veya SFU)
    final connectionColor = _isP2PMode
        ? const Color(0xFF3B82F6) // Mavi: P2P
        : const Color(0xFF8B5CF6); // Mor: SFU / LiveKit

    final connectionText = _isP2PMode
        ? 'P2P Bağlantı'
        : (_isLiveKitConnected ? 'SFU Bağlantı' : 'Bağlanıyor...');

    final connectionIcon = _isP2PMode ? Icons.call : Icons.hub;

    return Row(
      children: [
        // SOL: Intercom Active
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: intercomColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: intercomColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_tethering,
                  color: intercomColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Intercom Active",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: intercomColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // SAĞ: P2P / SFU Durumu
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: connectionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: connectionColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(connectionIcon, color: connectionColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectionText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: connectionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Mic Toggle (Sadece SFU'da ve bağlıysa gösterelim, P2P call ekranında zaten var)
                if (!_isP2PMode && _isLiveKitConnected) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      context.read<VoiceSessionBloc>().add(
                        const ToggleMicrophoneEvent(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isMicOn ? Colors.white : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMicOn ? Icons.mic : Icons.mic_off,
                        color: _isMicOn ? connectionColor : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantList() {
    final participants =
        _sessionDetails?.participants
            .where(
              (p) =>
                  p.status == 'Joined' ||
                  p.status == 'Accepted' ||
                  p.status == 'Disconnected',
            )
            .toList() ??
        [];

    if (participants.isEmpty) return _buildEmptyState();

    final hostId = _sessionDetails?.hostUserId;
    final currentUserId = _currentUserId;

    // Viewer Role Determination
    RiderRole viewerRole = RiderRole.participant;
    if (currentUserId != null && hostId == currentUserId) {
      viewerRole = RiderRole.organizer; // Host, Organizer yetkilerine sahip
    }

    return Column(
      children: participants.map((p) {
        final isConnected = p.status == 'Joined' || p.status == 'Accepted';
        final isMe = p.userId == currentUserId;

        // Target Role Determination
        RiderRole role = RiderRole.participant;
        if (hostId != null && p.userId == hostId) {
          role = RiderRole.organizer; // Host'a Taç veriyoruz (Lider)
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RiderCard(
            firstName: p.firstName ?? '',
            lastName: p.lastName ?? '',
            profileImageUrl:
                p.profileImage ?? 'https://i.pravatar.cc/150?u=${p.userId}',
            batteryLevel: isConnected ? 90 : 0,
            signalLevel: isConnected ? 100 : 0,
            isMicOn: isConnected,
            isSpeaking: _activeSpeakers.contains(
              p.userId.toString(),
            ), // LiveKit durumu
            isConnected: isConnected,
            isMe: isMe,
            role: role,
            viewerRole: viewerRole,
            // Callbackler: RiderCard içindeki yetki kontrolüne güveniyoruz ama yine de sadece yetkiliye dolu göndermek mantıklı.
            // Fakat yeni tasarımda RiderCard viewerRole'e göre karar veriyor.
            // Bu yüzden callbackleri her zaman gönderip, RiderCard'ın kısıtlamasına güvenebiliriz
            // VEYA burada null geçebiliriz. RiderCard logic'i: "callback null ise gösterme".
            // O yüzden yetkili değilsem null göndermeliyim.
            onKickUser: (viewerRole == RiderRole.organizer && !isMe)
                ? () => _kickUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onMuteUser: (viewerRole == RiderRole.organizer && !isMe)
                ? () => _muteUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onTransferHost: (viewerRole == RiderRole.organizer && !isMe)
                ? () => _transferHost(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          AppFrostedTextButton(
            text: "Leave Ride",
            onPressed: _showLeaveDialog,
            height: 52,
            backgroundColor: colorScheme.error.withOpacity(0.1),
            textColor: colorScheme.error,
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              "Henüz kimse katılmadı.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _p2pDebounceTimer?.cancel();
    super.dispose();
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
