import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  bool _isLoadingSession = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.data.rideId > 0) {
      context.read<GroupRideBloc>().add(
        JoinSignalRGroupEvent(widget.data.rideId),
      );
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
          listener: (context, state) {
            if (state is VoiceSessionDetailsLoaded) {
              setState(() {
                _sessionDetails = state.session;
                _isLoadingSession = false;
              });
            } else if (state is VoiceSessionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: ${state.message}'),
                  backgroundColor: colorScheme.error,
                ),
              );
              setState(() => _isLoadingSession = false);
            } else if (state is VoiceSessionLeft) {
              if (context.mounted) {
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
            } else if (state is VoiceSessionActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() => _isLoadingSession = false);
            }
          },
        ),
        BlocListener<GroupRideBloc, GroupRideState>(
          listener: (context, state) {
            if (state is GroupRideLeft) {
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
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
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
                if (Navigator.of(context).canPop()) {
                  context.pop(true);
                } else {
                  context.go('/communication');
                }
              }
            } else if (state is GroupRideFailure) {
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, colorScheme),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildMetaItem(
                              context,
                              Icons.map,
                              "Rota: ${widget.data.destination ?? 'Bilinmiyor'}",
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              Icons.bolt,
                              widget.data.ridingStyle ?? 'Bilinmiyor',
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              (widget.data.privacy ?? "Public") == "Public"
                                  ? Icons.public
                                  : Icons.lock,
                              widget.data.privacy ?? "Public",
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
              _sessionDetails?.title ?? widget.data.groupName,
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
                  "${_sessionDetails?.activeParticipantCount ?? (widget.data.currentParticipants ?? 0)} / ${widget.data.maxParticipants ?? 0}",
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering, color: Color(0xFF22C55E)),
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

    final isMeHost = _sessionDetails?.hostUserId == _currentUserId;

    return Column(
      children: participants.map((p) {
        final isConnected = p.status == 'Joined';
        final isMe = p.userId == _currentUserId;

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
            isSpeaking: isConnected,
            isConnected: isConnected,
            onKickUser: (isMeHost && !isMe)
                ? () => _kickUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onMuteUser: (isMeHost && !isMe)
                ? () => _muteUser(p.userId, p.firstName ?? 'Kullanıcı')
                : null,
            onTransferHost: (isMeHost && !isMe)
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
