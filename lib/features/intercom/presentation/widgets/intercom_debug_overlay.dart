import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/intercom_decision.dart';
import '../../domain/intercom_engine.dart';
import '../../domain/intercom_models.dart';

class IntercomDebugOverlay extends StatefulWidget {
  const IntercomDebugOverlay({super.key});

  @override
  State<IntercomDebugOverlay> createState() => _IntercomDebugOverlayState();
}

class _IntercomDebugOverlayState extends State<IntercomDebugOverlay> {
  static const int _maxEvents = 12;
  final List<IntercomTelemetryEvent> _events = <IntercomTelemetryEvent>[];
  StreamSubscription? _telemetrySub;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    final engine = sl<IntercomEngine>();
    _telemetrySub = engine.telemetry$.listen((event) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, event);
        if (_events.length > _maxEvents) {
          _events.removeRange(_maxEvents, _events.length);
        }
      });
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final engine = sl<IntercomEngine>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(10),
          width: 320,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: StreamBuilder<IntercomState>(
            stream: engine.state$,
            initialData: engine.snapshot,
            builder: (context, snapshot) {
              final state = snapshot.data ?? engine.snapshot;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  if (!_collapsed) ...[
                    const SizedBox(height: 8),
                    _buildEvents(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(IntercomState state) {
    final mode = _resolveMode(state);
    final participants = state.participants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Intercom',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 18,
              color: Colors.white70,
              icon: Icon(
                _collapsed ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _collapsed = !_collapsed;
                });
              },
            ),
          ],
        ),
        if (!_collapsed) ...[
          const SizedBox(height: 4),
          Text(
            'phase=${state.phase.name} transport=${state.transport.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'mode=$mode activeParticipantCount=$participants',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'rtc=${state.rtcStatus.name} mic=${state.micEnabled}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (state.lastDecision != null)
            Text(
              'decision=${_formatDecision(state.lastDecision!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          if (state.lastFailure != null)
            Text(
              'failure=${state.lastFailure!.code.name}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
        ],
      ],
    );
  }

  String _resolveMode(IntercomState state) {
    if (state.phase == IntercomPhase.evaluating &&
        state.transport == IntercomTransport.none) {
      return 'undecided';
    }

    switch (state.transport) {
      case IntercomTransport.none:
        return 'none';
      case IntercomTransport.p2p:
        return 'p2p';
      case IntercomTransport.sfu:
        return 'sfu';
    }
  }

  String _formatDecision(IntercomDecision decision) {
    final delay = decision.delayApplied;
    final delayPart = delay == null ? '' : ' (${delay.inSeconds}s)';

    if (decision.reason == IntercomDecisionReason.idle) {
      return 'idle';
    }
    if (decision.reason == IntercomDecisionReason.awaitingSecondPartyStability) {
      return '2 kişi: bekleme$delayPart';
    }
    if (decision.reason == IntercomDecisionReason.twoParticipantsP2p) {
      return '2 kişi sabit: P2P';
    }
    if (decision.reason == IntercomDecisionReason.threeOrMoreParticipantsSfu) {
      return '3+ kişi: SFU';
    }
    if (decision.reason == IntercomDecisionReason.manual) {
      return 'manuel override';
    }
    if (decision.reason == IntercomDecisionReason.recovery) {
      return 'recovery';
    }
    return decision.reason.name;
  }

  Widget _buildEvents() {
    if (_events.isEmpty) {
      return const Text(
        'telemetry: none',
        style: TextStyle(color: Colors.white54, fontSize: 11),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _events
          .map(
            (event) => Text(
              '${event.level.name} ${event.name}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
    );
  }
}
