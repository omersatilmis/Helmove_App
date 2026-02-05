import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- PROJE İMPORTLARI ---
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_frosted_button.dart';

import '../../domain/entities/group_ride_data.dart';
import '../widgets/rider_card.dart';

// --- BACKEND BLOC & ENTITY İMPORTLARI ---
import '../../../voice_session/domain/entities/voice_session_entity.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../bloc/group_ride_bloc.dart';
import '../bloc/group_ride_event.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';

class GroupPage extends StatefulWidget {
  final GroupRideData data;

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
    if (widget.data.id != null && widget.data.id! > 0) {
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
      GetVoiceSessionDetailsEvent(widget.data.id!),
    );
    // Grup turlarının üyelerini (DB'deki herkes) yükle
    context.read<GroupRideBloc>().add(
      LoadGroupRideParticipants(widget.data.id!),
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
                KickUserEvent(widget.data.id!, targetUserId),
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
                MuteUserEvent(widget.data.id!, targetUserId),
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
                TransferHostEvent(widget.data.id!, targetUserId),
              );
            },
            child: const Text('Devret'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
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
              if (widget.data.id != null) {
                // Konuşmadan ayrılarak Grup turundan da ayrıl
                context.read<VoiceSessionBloc>().add(
                  LeaveVoiceSessionEvent(widget.data.id!),
                );
                // Backend attendance için ayrılma isteği
                context.read<GroupRideBloc>().add(
                  LeaveGroupRide(widget.data.id!),
                );
              } else {
                context.pop();
              }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Arka Plan Gradyanı
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

    return BlocListener<VoiceSessionBloc, VoiceSessionState>(
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
          context.pop();
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
                // --- SCROLLABLE CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. HEADER (Geri Dönüş ve Grup Bilgileri)
                        _buildHeader(context, colorScheme),

                        const SizedBox(height: 16),

                        // 2. METADATA (Sağa Yaslandı)
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end, // 🔥 SAĞA YASLAMA
                          children: [
                            _buildMetaItem(
                              context,
                              Icons.map,
                              "Rota: ${widget.data.destination}",
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              Icons.bolt,
                              widget.data.ridingStyle,
                            ),
                            _buildDivider(context),
                            _buildMetaItem(
                              context,
                              widget.data.privacy == "Public"
                                  ? Icons.public
                                  : Icons.lock,
                              widget.data.privacy,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 3. INTERCOM ACTIVE BANNER
                        _buildIntercomBanner(),

                        const SizedBox(height: 30),

                        // 4. LIST HEADER & ACTIONS
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
                                      extra: widget.data.id,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                AppFrostedButton(
                                  icon: Icons.refresh,
                                  size: 40,
                                  iconSize: 20,
                                  onTap: () {
                                    if (widget.data.id != null) {
                                      _loadSessionDetails();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 5. RIDER LIST
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

                // 6. FOOTER (LEAVE BUTTON)
                _buildFooter(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppFrostedButton(
          icon: Icons.arrow_back,
          size: 44,
          onTap: () => context.pop(),
        ),

        // Grup Bilgileri
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
                  widget.data.sessionDuration,
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
                  "${_sessionDetails?.activeParticipantCount ?? widget.data.currentParticipants} / ${widget.data.maxParticipants}",
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
    // Doğrudan VoiceSession katılımcılarını kullan
    // Bu, odada olan herkesi gösterir (Joined, Accepted, Disconnected)
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

    // Check if I am host
    final isMeHost = _sessionDetails?.hostUserId == _currentUserId;

    return Column(
      children: participants.map((p) {
        // isConnected: Sadece Joined olanlar bağlı sayılır
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
            // Host Controls (Only if I am host AND target is not me)
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
      // 🔥 GÜNCELLEME: Üstten 20px boşluk vererek listeden ayırdım,
      // Alttan sadece 10px boşluk vererek (SafeArea da var) ekranın altına yaklaştırdım.
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

          const SizedBox(height: 12), // Boşluğu biraz açtım
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
