import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../../../../core/services/models/signalr_payloads.dart';

class SosAlertPage extends StatefulWidget {
  final SosAlertPayload alert;

  const SosAlertPage({super.key, required this.alert});

  @override
  State<SosAlertPage> createState() => _SosAlertPageState();
}

class _SosAlertPageState extends State<SosAlertPage> {
  bool _isVibrationRunning = true;

  @override
  void initState() {
    super.initState();
    unawaited(_runSosMorseLoop());
  }

  Future<void> _runSosMorseLoop() async {
    // S O S -> ... --- ... (timing in milliseconds, between pulse starts)
    const pulseDelays = <int>[0, 380, 380, 650, 760, 760, 980, 380, 380];

    while (_isVibrationRunning) {
      for (final delay in pulseDelays) {
        if (!_isVibrationRunning) return;
        if (delay > 0) {
          await Future<void>.delayed(Duration(milliseconds: delay));
        }
        try {
          await HapticFeedback.vibrate();
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
  }

  Future<void> _openInMaps() async {
    final lat = widget.alert.latitude;
    final lng = widget.alert.longitude;
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void dispose() {
    _isVibrationRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final senderLabel = widget.alert.senderFullName.trim().isNotEmpty
        ? widget.alert.senderFullName
        : (widget.alert.senderUsername.trim().isNotEmpty
              ? widget.alert.senderUsername
              : (l10n?.sos_default_sender_name ?? 'A rider'));
    final latitudeLabel = widget.alert.latitude.toStringAsFixed(5);
    final longitudeLabel = widget.alert.longitude.toStringAsFixed(5);

    return Scaffold(
      backgroundColor: const Color(0xFF8B0000),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFB00020), Color(0xFF6E0000)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n?.sos_close_tooltip ?? 'Close',
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      backgroundImage:
                          (widget.alert.senderProfilePictureUrl != null &&
                              widget.alert.senderProfilePictureUrl!.isNotEmpty)
                          ? NetworkImage(widget.alert.senderProfilePictureUrl!)
                          : null,
                      child:
                          (widget.alert.senderProfilePictureUrl == null ||
                              widget.alert.senderProfilePictureUrl!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 42,
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n?.sos_alert_title ?? 'EMERGENCY SOS ALERT',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n?.sos_sender_needs_help(senderLabel) ??
                          '$senderLabel needs help',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.sos_location_label(latitudeLabel, longitudeLabel) ??
                          'Location: $latitudeLabel, $longitudeLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openInMaps,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8B0000),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.directions),
                        label: Text(
                          l10n?.sos_go_help ?? 'Go Help',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
