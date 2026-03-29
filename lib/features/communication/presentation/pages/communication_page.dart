import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../../../../core/config/app_feature_flags.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../group_ride/data/api/group_ride_api.dart';
import '../../../group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../../group_ride/presentation/bloc/group_ride_event.dart';
import '../../../group_ride/presentation/bloc/group_ride_state.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../widgets/active_session_card.dart';
import '../widgets/nearby_group.dart';

void _noop() {}

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  static const Duration _refreshCooldown = Duration(milliseconds: 1500);
  static const int _sosCountdownSeconds = 3;

  bool _refreshInFlight = false;
  bool _isRefreshDisabled = false;
  bool _initialLoadTriggered = false;
  bool _runtimeBootstrapTriggered = false;
  bool _isSendingSos = false;

  Timer? _refreshCooldownTimer;
  Timer? _sosCountdownTimer;
  int _sosCountdownValue = 0;

  Future<void> _bootstrapCommunicationRuntime() async {
    if (_runtimeBootstrapTriggered) return;
    _runtimeBootstrapTriggered = true;
    try {
      await di.ensureCommunicationRuntimeStarted();
    } catch (_) {
      // Keep UI usable if runtime bootstrap fails.
    }
  }

  Future<void> _refreshCommunicationFast() async {
    if (_refreshInFlight || _isRefreshDisabled) return;

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

    try {
      await bloc.stream
          .firstWhere((state) => state.status != VoiceSessionStatus.loading)
          .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
    } finally {
      _refreshInFlight = false;
    }
  }

  int? _resolveActiveRideId() {
    final voiceRideId = context.read<VoiceSessionBloc>().state.session?.rideId;
    if (voiceRideId != null && voiceRideId > 0) {
      return voiceRideId;
    }

    final rideState = context.read<GroupRideBloc>().state;
    if (rideState is GroupRideSuccess && rideState.ride.id > 0) {
      return rideState.ride.id;
    }
    if (rideState is GroupRidesLoaded && rideState.rides.length == 1) {
      final id = rideState.rides.first.id;
      if (id > 0) {
        return id;
      }
    }
    return null;
  }

  void _showSosSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Position> _getCurrentPosition(AppLocalizations l10n) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(l10n.sos_location_services_disabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(l10n.sos_location_permission_denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(l10n.sos_location_permission_denied_forever);
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 10),
    );
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> _sendSosAlertFlow({required int initialRideId}) async {
    if (_isSendingSos) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    setState(() => _isSendingSos = true);
    try {
      final rideId = _resolveActiveRideId() ?? initialRideId;
      if (rideId <= 0) {
        throw Exception(l10n.sos_no_active_ride);
      }

      final position = await _getCurrentPosition(l10n);
      await di.sl<GroupRideApi>().sendSosAlert(
        rideId: rideId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _showSosSnack(l10n.sos_sent);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String message = l10n.sos_send_failed;
      if (responseData is Map<String, dynamic>) {
        final fromBackend = responseData['message']?.toString().trim();
        if (fromBackend != null && fromBackend.isNotEmpty) {
          message = fromBackend;
        }
      }
      _showSosSnack(message, isError: true);
    } catch (e) {
      _showSosSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingSos = false);
      }
    }
  }

  void _cancelSosCountdown() {
    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = null;
    if (!mounted) return;
    setState(() => _sosCountdownValue = 0);
  }

  void _startSosCountdown() {
    if (_isSendingSos || _sosCountdownValue > 0) return;

    final l10n = AppLocalizations.of(context);
    final rideId = _resolveActiveRideId();
    if (rideId == null || rideId <= 0) {
      _showSosSnack(
        l10n?.sos_no_active_ride ?? 'No active group ride found.',
        isError: true,
      );
      return;
    }

    setState(() => _sosCountdownValue = _sosCountdownSeconds);

    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_sosCountdownValue <= 1) {
        timer.cancel();
        setState(() => _sosCountdownValue = 0);
        unawaited(_sendSosAlertFlow(initialRideId: rideId));
        return;
      }

      setState(() => _sosCountdownValue = _sosCountdownValue - 1);
    });
  }

  Widget _buildSosCountdownWarning() {
    final showPanel = _sosCountdownValue > 0 || _isSendingSos;
    if (!showPanel) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final message = _isSendingSos
        ? (l10n?.sos_sending ?? 'Sending SOS alert...')
        : (l10n?.sos_countdown_warning(_sosCountdownValue) ??
              'SOS will be sent in $_sosCountdownValue s!');

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 110),
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxWidth: double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF6A0000).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF4D4D), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B3B).withValues(alpha: 0.75),
                blurRadius: 22,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
                blurRadius: 36,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (!_isSendingSos)
                TextButton(
                  onPressed: _cancelSosCountdown,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white70, width: 1.2),
                    ),
                  ),
                  child: Text(
                    l10n?.cancel ?? 'Cancel',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_bootstrapCommunicationRuntime());
    });
  }

  void _triggerInitialLoadIfVisible() {
    if (_initialLoadTriggered || !mounted) return;

    final route = ModalRoute.of(context);
    final isCurrentRoute = route?.isCurrent ?? false;
    if (!isCurrentRoute) return;

    _initialLoadTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final voiceBloc = context.read<VoiceSessionBloc>();
      final state = voiceBloc.state;
      final hasSessions = state.mySessions?.isNotEmpty ?? false;
      final activeSessionId = state.session?.id;
      context.read<GroupRideBloc>().add(const LoadActiveGroupRidesEvent());

      if (!hasSessions &&
          state.status != VoiceSessionStatus.loading &&
          state.status != VoiceSessionStatus.mySessionsLoaded) {
        voiceBloc.add(const GetMyVoiceSessionsEvent(immediate: true));
      }

      if (activeSessionId != null &&
          activeSessionId > 0 &&
          state.session?.id != activeSessionId) {
        voiceBloc.add(
          GetVoiceSessionDetailsEvent(activeSessionId, immediate: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _triggerInitialLoadIfVisible();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isSosBusy = _isSendingSos || _sosCountdownValue > 0;

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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (AppFeatureFlags.showSavedSessions) ...[
                              Expanded(
                                child: _buildTopButton(
                                  context,
                                  title: l10n.savedSessions,
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
                            Expanded(
                              child: _buildTopButton(
                                context,
                                title: l10n.createRideGroup,
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
                                  if (voiceSessionBloc.state.session != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.leaveGroupWarning,
                                          style: const TextStyle(
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
                                      l10n.yourActiveGroup,
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
                                  message: l10n.refresh,
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
                                GestureDetector(
                                  onTap: isSosBusy ? null : _startSosCountdown,
                                  child: Container(
                                    width: sosWidth,
                                    height: sosHeight,
                                    decoration: BoxDecoration(
                                      color: colorScheme.error.withValues(
                                        alpha: isSosBusy ? 0.08 : 0.15,
                                      ),
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
                                          isSosBusy
                                              ? (_sosCountdownValue > 0
                                                    ? '$_sosCountdownValue'
                                                    : '...')
                                              : '!SOS',
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
                              color: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
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
                                    l10n.pendingInvitesCount(
                                      pendingInviteCount,
                                    ),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/notifications'),
                                  child: Text(l10n.open),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isCompact ? 12 : 14),
                        ],
                        const ActiveSessionCard(),
                        if (AppFeatureFlags.showNearbyGroups) ...[
                          SizedBox(height: sectionSpacing),
                          Row(
                            children: [
                              Icon(
                                Icons.signal_cellular_alt,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.nearbyGroups,
                                style: AppTextStyles.h3.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: cardSpacing),
                          Column(
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: NearbyGroupCard(
                                  groupName: 'Weekend Riders',
                                  distance: '1.2 km',
                                  currentParticipants: 3,
                                  maxParticipants: 10,
                                  signalStatus: 'Strong',
                                  onJoinPressed: _noop,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: NearbyGroupCard(
                                  groupName: 'Mountain Tour',
                                  distance: '5.4 km',
                                  currentParticipants: 8,
                                  maxParticipants: 12,
                                  signalStatus: 'Good',
                                  onJoinPressed: _noop,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isCompact ? 84 : 100),
                      ],
                    ),
                  ),
                  _buildSosCountdownWarning(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    _sosCountdownTimer?.cancel();
    super.dispose();
  }
}
