import 'realtime_state_coordinator.dart';

export 'realtime_state_coordinator.dart'
  show
    CommunicationRefreshRequest,
    CommunicationRefreshTarget,
    RealtimeErrorEvent,
    RealtimeErrorCategory,
    RealtimeStateCoordinator;

/// Backward-compatible adapter.
/// Canonical implementation now lives in [RealtimeStateCoordinator].
class CommunicationRefreshCoordinator {
  final RealtimeStateCoordinator _realtimeCoordinator;

  CommunicationRefreshCoordinator(this._realtimeCoordinator);

  Stream<CommunicationRefreshRequest> get requests =>
      _realtimeCoordinator.refreshRequests;
  Stream<RealtimeErrorEvent> get errors => _realtimeCoordinator.errorStream;

  Future<T> runWithDedup<T>(
    String key,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return _realtimeCoordinator.runWithDedup(
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
    return _realtimeCoordinator.runVoiceSessions(
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
    return _realtimeCoordinator.runGroupRides(
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
    return _realtimeCoordinator.runVoiceSessionDetails(
      sessionId,
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<T> runGroupRideDetails<T>(
    int rideId,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return runWithDedup(
      'group_ride_details:$rideId',
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  Future<T> runGroupRideLookup<T>(
    int sessionId,
    Future<T> Function() action, {
    Duration? throttleWindow,
    bool force = false,
  }) {
    return runWithDedup(
      'group_ride_lookup:session:$sessionId',
      action,
      throttleWindow: throttleWindow,
      force: force,
    );
  }

  void requestVoiceSessionsRefresh({
    required String reason,
    bool force = false,
  }) {
    _realtimeCoordinator.requestVoiceSessionsRefresh(
      reason: reason,
      force: force,
    );
  }

  void requestGroupRidesRefresh({required String reason, bool force = false}) {
    _realtimeCoordinator.requestGroupRidesRefresh(reason: reason, force: force);
  }

  void requestVoiceSessionDetailsRefresh(
    int sessionId, {
    required String reason,
    bool force = false,
  }) {
    _realtimeCoordinator.requestVoiceSessionDetailsRefresh(
      sessionId,
      reason: reason,
      force: force,
    );
  }

  bool reportNotFound({
    required String message,
    String? source,
    String? dedupKey,
  }) {
    return _realtimeCoordinator.reportNotFound(
      message: message,
      source: source,
      dedupKey: dedupKey,
    );
  }

  Future<void> dispose() async {
    // No-op: lifecycle owned by RealtimeStateCoordinator singleton.
  }
}
