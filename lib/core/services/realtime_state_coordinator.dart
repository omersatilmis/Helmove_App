import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'models/communication_realtime_events.dart';
import 'signalr_service.dart';

enum RealtimeConnectionPhase {
  waiting,
  connecting,
  connected,
  reconnecting,
  disconnected,
}

extension RealtimeConnectionPhaseX on RealtimeConnectionPhase {
  int get severity {
    switch (this) {
      case RealtimeConnectionPhase.disconnected:
        return 5;
      case RealtimeConnectionPhase.reconnecting:
        return 4;
      case RealtimeConnectionPhase.connecting:
        return 3;
      case RealtimeConnectionPhase.waiting:
        return 2;
      case RealtimeConnectionPhase.connected:
        return 1;
    }
  }

  String get label {
    switch (this) {
      case RealtimeConnectionPhase.waiting:
        return 'Waiting';
      case RealtimeConnectionPhase.connecting:
        return 'Connecting';
      case RealtimeConnectionPhase.connected:
        return 'Connected';
      case RealtimeConnectionPhase.reconnecting:
        return 'Reconnecting';
      case RealtimeConnectionPhase.disconnected:
        return 'Disconnected';
    }
  }
}

class RealtimeConnectionSnapshot {
  final RealtimeConnectionPhase phase;
  final DateTime updatedAt;
  final String? reason;

  const RealtimeConnectionSnapshot({
    required this.phase,
    required this.updatedAt,
    this.reason,
  });

  factory RealtimeConnectionSnapshot.initial() => RealtimeConnectionSnapshot(
    phase: RealtimeConnectionPhase.waiting,
    updatedAt: DateTime.now(),
  );

  RealtimeConnectionSnapshot copyWith({
    RealtimeConnectionPhase? phase,
    DateTime? updatedAt,
    String? reason,
  }) {
    return RealtimeConnectionSnapshot(
      phase: phase ?? this.phase,
      updatedAt: updatedAt ?? this.updatedAt,
      reason: reason ?? this.reason,
    );
  }
}

enum RealtimeErrorCategory { timeout, network, disconnected, notFound, unknown }

class RealtimeErrorEvent {
  final RealtimeErrorCategory category;
  final String message;
  final String? source;
  final String? dedupKey;
  final DateTime occurredAt;

  const RealtimeErrorEvent({
    required this.category,
    required this.message,
    required this.occurredAt,
    this.source,
    this.dedupKey,
  });

  String get effectiveDedupKey => dedupKey ?? category.name;

  factory RealtimeErrorEvent.fromException(
    Object error, {
    String? source,
    String? dedupKey,
  }) {
    final message = error.toString();
    return RealtimeErrorEvent(
      category: _categorizeError(message),
      message: message,
      source: source,
      dedupKey: dedupKey,
      occurredAt: DateTime.now(),
    );
  }

  static RealtimeErrorCategory _categorizeError(String message) {
    final lowered = message.toLowerCase();
    if (lowered.contains('404') ||
        lowered.contains('not found') ||
        lowered.contains('bulunamad')) {
      return RealtimeErrorCategory.notFound;
    }
    if (lowered.contains('timeout') || lowered.contains('timed out')) {
      return RealtimeErrorCategory.timeout;
    }
    if (lowered.contains('disconnect') || lowered.contains('disconnected')) {
      return RealtimeErrorCategory.disconnected;
    }
    if (lowered.contains('socket') ||
        lowered.contains('network') ||
        lowered.contains('connection')) {
      return RealtimeErrorCategory.network;
    }
    return RealtimeErrorCategory.unknown;
  }
}

enum CommunicationRefreshTarget {
  voiceSessions,
  groupRides,
  voiceSessionDetails,
  reconnectInvalidation,
}

class CommunicationRefreshRequest {
  final CommunicationRefreshTarget target;
  final String reason;
  final bool force;
  final int? sessionId;
  final DateTime requestedAt;

  const CommunicationRefreshRequest({
    required this.target,
    required this.reason,
    required this.force,
    required this.requestedAt,
    this.sessionId,
  });
}

class RealtimeStateCoordinator {
  static const String sourceSignalR = 'signalr';
  static const String sourceGroupRide = 'group_ride';
  static const String sourceVoiceSession = 'voice_session';
  static const String _networkSuppressionKey = 'network_burst';
  static const String _versionScopeGroupRides = 'group_rides';
  static const String _versionScopeVoiceSessions = 'voice_sessions';

  final Duration errorSuppressionWindow;
  final Duration networkErrorSuppressionWindow;
  final Duration refreshCooldown;
  final Duration voiceSessionDetailsRefreshCooldown;
  final ValueNotifier<RealtimeConnectionSnapshot> stateNotifier;
  final ValueNotifier<bool> staleNotifier;
  final InFlightDeduplicator deduplicator;

  final _stateController =
      StreamController<RealtimeConnectionSnapshot>.broadcast();
  final _errorController = StreamController<RealtimeErrorEvent>.broadcast();
  final _realtimeEventsController =
      StreamController<CommunicationRealtimeEvent>.broadcast();
  final _refreshRequestsController =
      StreamController<CommunicationRefreshRequest>.broadcast();

  final Map<String, DateTime> _lastErrorAt = <String, DateTime>{};
  final Map<String, int> _lastAppliedVersionByScope = <String, int>{};
  final Map<String, RealtimeConnectionSnapshot> _sourceStates =
      <String, RealtimeConnectionSnapshot>{};
  final Map<String, DateTime> _lastRefreshDispatchedAt = <String, DateTime>{};
  final Map<String, Timer> _pendingRefreshTimers = <String, Timer>{};
  final Map<String, CommunicationRefreshRequest> _pendingRefreshRequests =
      <String, CommunicationRefreshRequest>{};

  StreamSubscription<HubConnectionState>? _signalRSubscription;
  final List<StreamSubscription<dynamic>> _signalREventSubscriptions = [];
  HubConnectionState? _lastSignalRState;
  bool _hasSeenSignalRConnected = false;
  DateTime? _staleSince;
  String? _staleReason;

  RealtimeStateCoordinator({
    SignalRService? signalRService,
    Duration throttleWindow = const Duration(seconds: 4),
    this.refreshCooldown = const Duration(seconds: 4),
    this.voiceSessionDetailsRefreshCooldown = const Duration(milliseconds: 450),
    this.errorSuppressionWindow = const Duration(seconds: 5),
    this.networkErrorSuppressionWindow = const Duration(seconds: 12),
  }) : stateNotifier = ValueNotifier<RealtimeConnectionSnapshot>(
         RealtimeConnectionSnapshot.initial(),
       ),
       staleNotifier = ValueNotifier<bool>(false),
       deduplicator = InFlightDeduplicator(defaultThrottle: throttleWindow) {
    if (signalRService != null) {
      bindSignalR(signalRService);
    }
  }

  Stream<RealtimeConnectionSnapshot> get stateStream => _stateController.stream;
  Stream<RealtimeErrorEvent> get errorStream => _errorController.stream;
  Stream<CommunicationRealtimeEvent> get realtimeEvents =>
      _realtimeEventsController.stream;
  Stream<CommunicationRefreshRequest> get refreshRequests =>
      _refreshRequestsController.stream;
  bool get isDataStale => staleNotifier.value;
  DateTime? get staleSince => _staleSince;
  String? get staleReason => _staleReason;
  Map<String, RealtimeConnectionSnapshot> get sourceStates =>
      Map.unmodifiable(_sourceStates);

  RealtimeConnectionSnapshot? getSourceSnapshot(String source) =>
      _sourceStates[source];

  void bindSignalR(
    SignalRService signalRService, {
    String source = sourceSignalR,
  }) {
    _signalRSubscription?.cancel();
    _clearSignalREventSubscriptions();
    _bindSignalREvents(signalRService);
    _signalRSubscription = signalRService.connectionStateStream
        .distinct()
        .listen((state) {
          _handleSignalRStateChange(state);
          updateSourcePhase(
            source,
            _mapSignalRState(state),
            reason: 'signalr:${state.toString()}',
          );
        });
  }

  void _bindSignalREvents(SignalRService signalRService) {
    _signalREventSubscriptions.add(
      signalRService.rideTerminatedStream.listen((payload) {
        if (!_acceptVersionOrInvalidate(
          scopeKey: _versionScopeGroupRides,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.groupRides,
          reason: 'ride_terminated',
        )) {
          return;
        }

        _realtimeEventsController.add(
          RideTerminatedRealtimeEvent(
            rideId: payload.rideId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.rideCreatedStream.listen((payload) {
        if (!_acceptVersionOrInvalidate(
          scopeKey: _versionScopeGroupRides,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.groupRides,
          reason: 'ride_created',
        )) {
          return;
        }

        _realtimeEventsController.add(
          RideCreatedRealtimeEvent(
            rideId: payload.rideId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.userJoinedStream.listen((payload) {
        final scopeKey = _versionScopeVoiceSessionDetails(payload.sessionId);
        if (!_acceptVersionOrInvalidate(
          scopeKey: scopeKey,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.voiceSessionDetails,
          sessionId: payload.sessionId,
          reason: 'user_joined',
        )) {
          return;
        }

        _realtimeEventsController.add(
          UserJoinedVoiceSessionRealtimeEvent(
            userId: payload.userId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.userLeftStream.listen((payload) {
        final scopeKey = _versionScopeVoiceSessionDetails(payload.sessionId);
        if (!_acceptVersionOrInvalidate(
          scopeKey: scopeKey,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.voiceSessionDetails,
          sessionId: payload.sessionId,
          reason: 'user_left',
        )) {
          return;
        }

        _realtimeEventsController.add(
          UserLeftVoiceSessionRealtimeEvent(
            userId: payload.userId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.hostChangedStream.listen(
        (data) => _realtimeEventsController.add(HostChangedRealtimeEvent(data)),
      ),
    );

    _signalREventSubscriptions.add(
      signalRService.groupRideUpdatedStream.listen((payload) {
        if (!_acceptVersionOrInvalidate(
          scopeKey: _versionScopeGroupRides,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.groupRides,
          reason: 'group_ride_updated',
        )) {
          return;
        }

        _realtimeEventsController.add(
          GroupRideUpdatedRealtimeEvent(
            rideId: payload.rideId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.voiceSessionRefreshStream.listen((payload) {
        final hasSessionId = payload.sessionId > 0;
        final scopeKey = hasSessionId
            ? _versionScopeVoiceSessionDetails(payload.sessionId)
            : _versionScopeVoiceSessions;

        if (!_acceptVersionOrInvalidate(
          scopeKey: scopeKey,
          incomingVersion: payload.version,
          refreshTarget: hasSessionId
              ? CommunicationRefreshTarget.voiceSessionDetails
              : CommunicationRefreshTarget.voiceSessions,
          sessionId: hasSessionId ? payload.sessionId : null,
          reason: 'voice_session_refresh',
        )) {
          return;
        }

        _realtimeEventsController.add(
          VoiceSessionRefreshRealtimeEvent(
            sessionId: payload.sessionId,
            rideId: payload.rideId,
            version: payload.version,
            reason: payload.reason,
          ),
        );
      }),
    );

    _signalREventSubscriptions.add(
      signalRService.userForceRemovedStream.listen(
        (sessionId) => _realtimeEventsController.add(
          UserForceRemovedRealtimeEvent(sessionId),
        ),
      ),
    );

    _signalREventSubscriptions.add(
      signalRService.participantStatusUpdatedStream.listen(
        (payload) => _realtimeEventsController.add(
          ParticipantStatusUpdatedRealtimeEvent(payload),
        ),
      ),
    );

    _signalREventSubscriptions.add(
      signalRService.userMuteStateStream.listen(
        (payload) => _realtimeEventsController.add(
          UserMuteStateChangedRealtimeEvent(payload),
        ),
      ),
    );

    _signalREventSubscriptions.add(
      signalRService.userDisconnectedStream.listen((payload) {
        final scopeKey = _versionScopeVoiceSessionDetails(payload.sessionId);
        if (!_acceptVersionOrInvalidate(
          scopeKey: scopeKey,
          incomingVersion: payload.version,
          refreshTarget: CommunicationRefreshTarget.voiceSessionDetails,
          sessionId: payload.sessionId,
          reason: 'user_disconnected',
        )) {
          return;
        }

        _realtimeEventsController.add(
          UserDisconnectedVoiceSessionRealtimeEvent(
            userId: payload.userId,
            sessionId: payload.sessionId,
            version: payload.version,
          ),
        );
      }),
    );
  }

  void _clearSignalREventSubscriptions() {
    for (final subscription in _signalREventSubscriptions) {
      subscription.cancel();
    }
    _signalREventSubscriptions.clear();
  }

  void markWaiting({String? reason}) {
    _setPhase(RealtimeConnectionPhase.waiting, reason: reason);
  }

  void setGlobalPhase(RealtimeConnectionPhase phase, {String? reason}) {
    _setPhase(phase, reason: reason);
  }

  void updateSourcePhase(
    String source,
    RealtimeConnectionPhase phase, {
    String? reason,
  }) {
    final current = _sourceStates[source];
    if (current != null && current.phase == phase && current.reason == reason) {
      return;
    }

    _sourceStates[source] = RealtimeConnectionSnapshot(
      phase: phase,
      updatedAt: DateTime.now(),
      reason: reason,
    );
    _recomputeAggregate();
  }

  bool removeSource(String source) {
    final removed = _sourceStates.remove(source);
    if (removed != null) {
      _recomputeAggregate();
      return true;
    }
    return false;
  }

  void clearSources() {
    if (_sourceStates.isEmpty) {
      return;
    }
    _sourceStates.clear();
    _recomputeAggregate();
  }

  void requestVoiceSessionsRefresh({
    required String reason,
    bool force = false,
  }) {
    _enqueueRefresh(
      CommunicationRefreshRequest(
        target: CommunicationRefreshTarget.voiceSessions,
        reason: reason,
        force: force,
        requestedAt: DateTime.now(),
      ),
    );
  }

  void requestGroupRidesRefresh({required String reason, bool force = false}) {
    _enqueueRefresh(
      CommunicationRefreshRequest(
        target: CommunicationRefreshTarget.groupRides,
        reason: reason,
        force: force,
        requestedAt: DateTime.now(),
      ),
    );
  }

  void requestVoiceSessionDetailsRefresh(
    int sessionId, {
    required String reason,
    bool force = false,
  }) {
    if (sessionId <= 0) return;
    _enqueueRefresh(
      CommunicationRefreshRequest(
        target: CommunicationRefreshTarget.voiceSessionDetails,
        sessionId: sessionId,
        reason: reason,
        force: force,
        requestedAt: DateTime.now(),
      ),
    );
  }

  void _handleSignalRStateChange(HubConnectionState state) {
    final previous = _lastSignalRState;
    final isReconnectTransition =
        state == HubConnectionState.Connected &&
        _hasSeenSignalRConnected &&
        (previous == HubConnectionState.Reconnecting ||
            previous == HubConnectionState.Disconnected);

    if (state == HubConnectionState.Connected) {
      _hasSeenSignalRConnected = true;
    }
    _lastSignalRState = state;

    if (!isReconnectTransition) {
      return;
    }

    _markDataStale('signalr_reconnected');
    _lastAppliedVersionByScope.clear();
    deduplicator.invalidateAll();
    _requestReconnectInvalidation(reason: 'signalr_reconnected', force: true);
  }

  void _requestReconnectInvalidation({
    required String reason,
    required bool force,
  }) {
    requestVoiceSessionsRefresh(reason: reason, force: force);
    requestGroupRidesRefresh(reason: reason, force: force);
    _dispatchRefresh(
      CommunicationRefreshRequest(
        target: CommunicationRefreshTarget.reconnectInvalidation,
        reason: reason,
        force: force,
        requestedAt: DateTime.now(),
      ),
    );
  }

  bool _acceptVersionOrInvalidate({
    required String scopeKey,
    required int? incomingVersion,
    required CommunicationRefreshTarget refreshTarget,
    required String reason,
    int? sessionId,
  }) {
    if (incomingVersion == null || incomingVersion <= 0) {
      return true;
    }

    final currentVersion = _lastAppliedVersionByScope[scopeKey];
    if (currentVersion == null) {
      _lastAppliedVersionByScope[scopeKey] = incomingVersion;
      return true;
    }

    final expected = currentVersion + 1;
    if (incomingVersion == expected) {
      _lastAppliedVersionByScope[scopeKey] = incomingVersion;
      return true;
    }

    _onVersionGapDetected(
      scopeKey: scopeKey,
      currentVersion: currentVersion,
      incomingVersion: incomingVersion,
      refreshTarget: refreshTarget,
      sessionId: sessionId,
      reason: reason,
    );
    return false;
  }

  void _onVersionGapDetected({
    required String scopeKey,
    required int currentVersion,
    required int incomingVersion,
    required CommunicationRefreshTarget refreshTarget,
    required String reason,
    int? sessionId,
  }) {
    final gapReason =
        'version_gap:$reason:$scopeKey:$currentVersion->$incomingVersion';
    _markDataStale(gapReason);
    deduplicator.invalidate(scopeKey);
    _lastAppliedVersionByScope.remove(scopeKey);

    switch (refreshTarget) {
      case CommunicationRefreshTarget.voiceSessions:
        requestVoiceSessionsRefresh(reason: gapReason, force: true);
        break;
      case CommunicationRefreshTarget.groupRides:
        requestGroupRidesRefresh(reason: gapReason, force: true);
        break;
      case CommunicationRefreshTarget.voiceSessionDetails:
        if (sessionId != null && sessionId > 0) {
          requestVoiceSessionDetailsRefresh(
            sessionId,
            reason: gapReason,
            force: true,
          );
        } else {
          requestVoiceSessionsRefresh(reason: gapReason, force: true);
        }
        break;
      case CommunicationRefreshTarget.reconnectInvalidation:
        _requestReconnectInvalidation(reason: gapReason, force: true);
        break;
    }
  }

  String _versionScopeVoiceSessionDetails(int sessionId) {
    return 'voice_session_details:$sessionId';
  }

  void _markDataStale(String reason) {
    _staleReason = reason;
    _staleSince = DateTime.now();
    if (!staleNotifier.value) {
      staleNotifier.value = true;
    }
  }

  void markDataFresh({String? reason}) {
    _staleReason = reason;
    _staleSince = null;
    if (staleNotifier.value) {
      staleNotifier.value = false;
    }
  }

  void _enqueueRefresh(CommunicationRefreshRequest request) {
    final key = _refreshRequestKey(request);
    final cooldown = _resolveRefreshCooldown(request);

    if (request.force) {
      _pendingRefreshTimers.remove(key)?.cancel();
      _pendingRefreshRequests.remove(key);
      _dispatchRefresh(request);
      return;
    }

    final now = DateTime.now();
    final last = _lastRefreshDispatchedAt[key];
    if (last == null || now.difference(last) >= cooldown) {
      _dispatchRefresh(request);
      return;
    }

    _pendingRefreshRequests[key] = request;
    if (_pendingRefreshTimers[key]?.isActive ?? false) {
      return;
    }

    final remaining = cooldown - now.difference(last);
    _pendingRefreshTimers[key] = Timer(remaining, () {
      final pending = _pendingRefreshRequests.remove(key);
      _pendingRefreshTimers.remove(key);
      if (pending == null) return;
      _dispatchRefresh(
        CommunicationRefreshRequest(
          target: pending.target,
          sessionId: pending.sessionId,
          reason: pending.reason,
          force: false,
          requestedAt: DateTime.now(),
        ),
      );
    });
  }

  Duration _resolveRefreshCooldown(CommunicationRefreshRequest request) {
    if (request.target == CommunicationRefreshTarget.voiceSessionDetails) {
      return voiceSessionDetailsRefreshCooldown;
    }
    return refreshCooldown;
  }

  void _dispatchRefresh(CommunicationRefreshRequest request) {
    _lastRefreshDispatchedAt[_refreshRequestKey(request)] = DateTime.now();
    _refreshRequestsController.add(request);
  }

  String _refreshRequestKey(CommunicationRefreshRequest request) {
    switch (request.target) {
      case CommunicationRefreshTarget.voiceSessions:
        return 'voice_sessions';
      case CommunicationRefreshTarget.groupRides:
        return 'group_rides';
      case CommunicationRefreshTarget.voiceSessionDetails:
        return 'voice_session_details:${request.sessionId ?? 0}';
      case CommunicationRefreshTarget.reconnectInvalidation:
        return 'reconnect_invalidation';
    }
  }

  RealtimeConnectionPhase _mapSignalRState(HubConnectionState state) {
    switch (state) {
      case HubConnectionState.Connecting:
        return RealtimeConnectionPhase.connecting;
      case HubConnectionState.Connected:
        return RealtimeConnectionPhase.connected;
      case HubConnectionState.Reconnecting:
        return RealtimeConnectionPhase.reconnecting;
      case HubConnectionState.Disconnecting:
        return RealtimeConnectionPhase.disconnected;
      case HubConnectionState.Disconnected:
        return RealtimeConnectionPhase.disconnected;
    }
  }

  void _recomputeAggregate() {
    if (_sourceStates.isEmpty) {
      _setPhase(RealtimeConnectionPhase.waiting, reason: 'no_sources');
      return;
    }

    final worst = _sourceStates.entries.reduce((a, b) {
      final aSeverity = a.value.phase.severity;
      final bSeverity = b.value.phase.severity;
      if (aSeverity != bSeverity) {
        return aSeverity > bSeverity ? a : b;
      }
      return a.value.updatedAt.isAfter(b.value.updatedAt) ? a : b;
    });

    final reason = worst.value.reason;
    final combinedReason = reason == null || reason.isEmpty
        ? 'source:${worst.key}'
        : 'source:${worst.key}:$reason';
    _setPhase(worst.value.phase, reason: combinedReason);
  }

  void _setPhase(RealtimeConnectionPhase phase, {String? reason}) {
    final current = stateNotifier.value;
    if (current.phase == phase && current.reason == reason) {
      return;
    }

    final snapshot = current.copyWith(
      phase: phase,
      reason: reason,
      updatedAt: DateTime.now(),
    );
    stateNotifier.value = snapshot;
    _stateController.add(snapshot);
  }

  bool reportError(
    RealtimeErrorEvent event, {
    bool updateConnectionState = true,
    Duration? suppressionWindow,
  }) {
    final key = _errorSuppressionKey(event);
    final lastAt = _lastErrorAt[key];
    final window = _errorSuppressionWindowFor(event, suppressionWindow);
    if (lastAt != null && event.occurredAt.difference(lastAt) < window) {
      return false;
    }

    _lastErrorAt[key] = event.occurredAt;
    final shouldUpdateConnectionState =
        updateConnectionState &&
        event.category != RealtimeErrorCategory.notFound;
    if (shouldUpdateConnectionState) {
      if (event.source != null) {
        _promoteSourceToReconnecting(event.source!, event.category);
      } else {
        _promoteGlobalToReconnecting(event.category);
      }
    }

    _errorController.add(event);
    return true;
  }

  String _errorSuppressionKey(RealtimeErrorEvent event) {
    if (_isNetworkCategory(event.category)) {
      return _networkSuppressionKey;
    }
    return event.effectiveDedupKey;
  }

  Duration _errorSuppressionWindowFor(
    RealtimeErrorEvent event,
    Duration? override,
  ) {
    final baseWindow = override ?? errorSuppressionWindow;
    if (_isNetworkCategory(event.category)) {
      return baseWindow >= networkErrorSuppressionWindow
          ? baseWindow
          : networkErrorSuppressionWindow;
    }
    return baseWindow;
  }

  bool _isNetworkCategory(RealtimeErrorCategory category) {
    return category == RealtimeErrorCategory.network ||
        category == RealtimeErrorCategory.timeout ||
        category == RealtimeErrorCategory.disconnected;
  }

  bool reportErrorFromException(
    Object error, {
    String? source,
    bool updateConnectionState = true,
    String? dedupKey,
  }) {
    return reportError(
      RealtimeErrorEvent.fromException(
        error,
        source: source,
        dedupKey: dedupKey,
      ),
      updateConnectionState: updateConnectionState,
    );
  }

  bool reportNotFound({
    required String message,
    String? source,
    String? dedupKey,
  }) {
    return reportError(
      RealtimeErrorEvent(
        category: RealtimeErrorCategory.notFound,
        message: message,
        source: source,
        dedupKey: dedupKey,
        occurredAt: DateTime.now(),
      ),
      updateConnectionState: false,
    );
  }

  void _promoteSourceToReconnecting(
    String source,
    RealtimeErrorCategory category,
  ) {
    final current = _sourceStates[source]?.phase ?? stateNotifier.value.phase;
    if (current == RealtimeConnectionPhase.reconnecting ||
        current == RealtimeConnectionPhase.disconnected) {
      return;
    }
    updateSourcePhase(
      source,
      RealtimeConnectionPhase.reconnecting,
      reason: 'error:${category.name}',
    );
  }

  void _promoteGlobalToReconnecting(RealtimeErrorCategory category) {
    final current = stateNotifier.value.phase;
    if (current == RealtimeConnectionPhase.reconnecting ||
        current == RealtimeConnectionPhase.disconnected) {
      return;
    }
    _setPhase(
      RealtimeConnectionPhase.reconnecting,
      reason: 'error:${category.name}',
    );
  }

  Future<T> runWithDedup<T>(
    String key,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return deduplicator.run<T>(
      key,
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<T> runVoiceSessions<T>(
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return runWithDedup<T>(
      'voice_sessions',
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<T> runGroupRides<T>(
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return runWithDedup<T>(
      'group_rides',
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<T> runVoiceSessionDetails<T>(
    int sessionId,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return runWithDedup<T>(
      'voice_session_details:$sessionId',
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<void> dispose() async {
    for (final timer in _pendingRefreshTimers.values) {
      timer.cancel();
    }
    _pendingRefreshTimers.clear();
    _pendingRefreshRequests.clear();
    _clearSignalREventSubscriptions();
    await _signalRSubscription?.cancel();
    await _stateController.close();
    await _errorController.close();
    await _realtimeEventsController.close();
    await _refreshRequestsController.close();
    staleNotifier.dispose();
    stateNotifier.dispose();
  }
}

class InFlightDeduplicator {
  final Duration defaultThrottle;
  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};
  final Map<String, _CachedResult> _cache = <String, _CachedResult>{};

  InFlightDeduplicator({this.defaultThrottle = const Duration(seconds: 4)});

  bool isInFlight(String key) => _inFlight.containsKey(key);

  Future<T> run<T>(
    String key,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return inFlight.then((value) => value as T);
    }

    if (!force) {
      final cached = _cache[key];
      if (cached != null) {
        final window = throttleWindow ?? defaultThrottle;
        if (DateTime.now().difference(cached.completedAt) < window) {
          if (cached.error != null) {
            return Future<T>.error(cached.error!, cached.stackTrace);
          }
          return Future<T>.value(cached.value as T);
        }
      }
    }

    final future = Future<T>.sync(action);
    _inFlight[key] = future;
    future
        .then((value) {
          _cache[key] = _CachedResult.success(value);
          return value;
        })
        .catchError((error, stackTrace) {
          _cache[key] = _CachedResult.error(error, stackTrace);
          throw error;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });

    return future;
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidateAll() {
    _cache.clear();
  }

  void clearAll() {
    _cache.clear();
    _inFlight.clear();
  }
}

class _CachedResult {
  final Object? value;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime completedAt;

  _CachedResult.success(this.value)
    : error = null,
      stackTrace = null,
      completedAt = DateTime.now();

  _CachedResult.error(this.error, this.stackTrace)
    : value = null,
      completedAt = DateTime.now();
}
