import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/text_styles.dart';
import '../../../group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../../group_ride/presentation/bloc/group_ride_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../widgets/active_session_card.dart';
import '../widgets/nearby_group.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/config/app_feature_flags.dart';

void _noop() {}

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  static const Duration _refreshCooldown = Duration(milliseconds: 1500);
  bool _refreshInFlight = false;
  bool _isRefreshDisabled = false;
  bool _initialLoadTriggered = false;
  Timer? _refreshCooldownTimer;
  bool _runtimeBootstrapTriggered = false;

  Future<void> _bootstrapCommunicationRuntime() async {
    if (_runtimeBootstrapTriggered) {
      return;
    }
    _runtimeBootstrapTriggered = true;
    try {
      await di.ensureCommunicationRuntimeStarted();
    } catch (_) {
      // Best-effort. Communication UI must stay usable even if runtime fails.
    }
  }

  Future<void> _refreshCommunicationFast() async {
    if (_refreshInFlight || _isRefreshDisabled) {
      return;
    }

    if (mounted) {
      setState(() => _isRefreshDisabled = true);
    }
    _refreshCooldownTimer?.cancel();
    _refreshCooldownTimer = Timer(_refreshCooldown, () {
      if (mounted) {
        setState(() => _isRefreshDisabled = false);
      }
    });

    _refreshInFlight = true;

    final bloc = context.read<VoiceSessionBloc>();

    final activeSessionId = bloc.state.session?.id;

    bloc.add(const GetMyVoiceSessionsEvent(force: true, immediate: true));

    if (activeSessionId != null && activeSessionId > 0) {
      bloc.add(
        GetVoiceSessionDetailsEvent(
          activeSessionId,
          force: true,
          immediate: true,
        ),
      );
    }

    // Pull-to-refresh UX: sabit delay yerine state tabanlÄ± kÄ±sa bekleme.
    try {
      await bloc.stream
          .firstWhere((state) => state.status != VoiceSessionStatus.loading)
          .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_bootstrapCommunicationRuntime());
    });
  }

  void _triggerInitialLoadIfVisible() {
    if (_initialLoadTriggered || !mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    final isCurrentRoute = route?.isCurrent ?? false;
    if (!isCurrentRoute) {
      return;
    }

    _initialLoadTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final bloc = context.read<VoiceSessionBloc>();
      final state = bloc.state;
      final hasSessions = state.mySessions?.isNotEmpty ?? false;
      final activeSessionId = state.session?.id;
      context.read<GroupRideBloc>().add(const LoadActiveGroupRidesEvent());

      if (!hasSessions &&
          state.status != VoiceSessionStatus.loading &&
          state.status != VoiceSessionStatus.mySessionsLoaded) {
        bloc.add(const GetMyVoiceSessionsEvent(immediate: true));
      }

      if (activeSessionId != null &&
          activeSessionId > 0 &&
          state.session?.id != activeSessionId) {
        bloc.add(GetVoiceSessionDetailsEvent(activeSessionId, immediate: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _triggerInitialLoadIfVisible();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    final horizontalPadding = isCompact ? 16.0 : 20.0;
    final sectionSpacing = isCompact ? 22.0 : 30.0;
    final cardSpacing = isCompact ? 12.0 : 16.0;
    final topButtonHeight = isCompact ? 78.0 : 85.0;
    final topButtonIconSize = isCompact ? 24.0 : 28.0;
    final topButtonFontSize = isCompact ? 12.0 : 13.0;
    final sosWidth = isCompact ? 52.0 : 60.0;
    final sosHeight = isCompact ? 36.0 : 40.0;
    final pendingInviteCount = context.select<VoiceSessionBloc, int>(
      (bloc) => bloc.state.pendingInvitesCount,
    );


    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: BlocListener<VoiceSessionBloc, VoiceSessionState>(
            listenWhen: (prev, curr) {
              final prevActiveId = prev.session?.id;
              final currActiveId = curr.session?.id;
              if (prevActiveId != currActiveId) {
                return true;
              }

              final prevNeedsDetails =
                  prevActiveId != null && prev.session?.id != prevActiveId;
              final currNeedsDetails =
                  currActiveId != null && curr.session?.id != currActiveId;

              // Fire only on transition to "details missing" to avoid repeated requests.
              return currNeedsDetails && !prevNeedsDetails;
            },
            listener: (context, state) {
              final activeSession = state.session;
              if (activeSession != null &&
                  state.session?.id != activeSession.id &&
                  state.status != VoiceSessionStatus.loading) {
                context.read<VoiceSessionBloc>().add(
                  GetVoiceSessionDetailsEvent(
                    activeSession.id,
                    immediate: true,
                  ),
                );
              }
            },
            child: RefreshIndicator(
              onRefresh: () {
                if (_isRefreshDisabled || _refreshInFlight) {
                  return Future.value();
                }
                return _refreshCommunicationFast();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: horizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. ÃœST BUTONLAR (Saved Sessions & Create Ride) ---
                    Row(
                      children: [
                        // --- SAVED SESSIONS (Nötr Cam) ---
                        if (AppFeatureFlags.showSavedSessions) ...[
                          Expanded(
                            child: _buildTopButton(
                              context,
                              title: "Saved\nSessions",
                              icon: Icons.bookmark_border,
                              glassTint: colorScheme.onSurface,
                              iconColor: colorScheme.primary,
                              textColor: colorScheme.onSurface,
                              height: topButtonHeight,
                              iconSize: topButtonIconSize,
                              fontSize: topButtonFontSize,
                              onTap: () {},
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                        ],

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
                            height: topButtonHeight,
                            iconSize: topButtonIconSize,
                            fontSize: topButtonFontSize,
                            onTap: () async {
                              final voiceSessionBloc = context
                                  .read<VoiceSessionBloc>();
                              if (voiceSessionBloc.state.session !=
                                  null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'LÃ¼tfen yeni bir grup oluÅŸturmadan Ã¶nce mevcut sÃ¼rÃ¼ÅŸten ayrÄ±lÄ±n.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              await context.push(
                                '/communication/create-group-ride',
                              );
                              if (!mounted) return;
                              voiceSessionBloc.add(
                                const GetMyVoiceSessionsEvent(force: true),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),

                    // --- 2. YOUR ACTIVE GROUP BAŞLIĞI & SOS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: colorScheme.onSurface,
                                size: isCompact ? 22 : 24,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Your Active Group",
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.h3.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Refresh',
                              child: AppFrostedTextButton(
                                text: '',
                                onPressed: _isRefreshDisabled
                                    ? null
                                    : _refreshCommunicationFast,
                                width: sosHeight,
                                height: sosHeight,
                                borderRadius: 12,
                                padding: EdgeInsets.zero,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // --- SOS Acil Durum Butonu ---
                            GestureDetector(
                              onTap: () {
                                debugPrint("SOS Gönderildi!");
                              },
                              child: Container(
                                width: sosWidth,
                                height: sosHeight,
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
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "!SOS",
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: cardSpacing),

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
                      SizedBox(height: isCompact ? 12 : 14),
                    ],

                    // --- 3. ACTIVE GROUP KARTI (VoiceSession'dan yÃ¼klenir) ---
                    const ActiveSessionCard(),

                    if (AppFeatureFlags.showNearbyGroups) ...[
                      SizedBox(height: sectionSpacing),

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

                      SizedBox(height: cardSpacing),

                      // --- 5. NEARBY GROUPS LİSTESİ (Dummy UI) ---
                      Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: NearbyGroupCard(
                              groupName: "Weekend Riders",
                              distance: "1.2 km",
                              currentParticipants: 3,
                              maxParticipants: 10,
                              signalStatus: "Strong",
                              onJoinPressed: _noop,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: NearbyGroupCard(
                              groupName: "Mountain Tour",
                              distance: "5.4 km",
                              currentParticipants: 8,
                              maxParticipants: 12,
                              signalStatus: "Good",
                              onJoinPressed: _noop,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // --- 6. BOTTOM PADDING (for extendBody: true) ---
                    SizedBox(height: isCompact ? 84 : 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Ãœst Buton YardÄ±mcÄ± Fonksiyon ---
  Widget _buildTopButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color glassTint,
    required Color iconColor,
    required Color textColor,
    required double height,
    required double iconSize,
    required double fontSize,
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
            constraints: BoxConstraints(minHeight: height),
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
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
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

  @override
  void dispose() {
    _refreshCooldownTimer?.cancel();
    super.dispose();
  }
}
