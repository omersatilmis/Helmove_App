import 'models/communication_realtime_events.dart';
import 'realtime_state_coordinator.dart';

export 'models/communication_realtime_events.dart';

/// Backward-compatible adapter.
/// Canonical SignalR event ingestion is now owned by [RealtimeStateCoordinator].
class CommunicationRealtimeBus {
  final RealtimeStateCoordinator _realtimeCoordinator;

  CommunicationRealtimeBus(this._realtimeCoordinator);

  Stream<CommunicationRealtimeEvent> get events =>
      _realtimeCoordinator.realtimeEvents;

  Future<void> dispose() async {
    // No-op: lifecycle owned by RealtimeStateCoordinator singleton.
  }
}
