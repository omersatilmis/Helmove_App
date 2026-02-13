import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../call/presentation/bloc/call_event.dart';
import '../../../call/presentation/bloc/call_state.dart';

/// P2P Arama Sayfası — WhatsApp tarzı tam ekran
///
/// [CallBloc] state'lerine göre 4 görünüm sunar:
/// 1. Outgoing — Arıyor (pulse animasyon)
/// 2. Incoming — Gelen arama (kabul/red)
/// 3. Active — Konuşma (süre, mute, kapatma)
/// 4. Ended — Sonuç mesajı (otomatik geri dönüş)
class CallPage extends StatelessWidget {
  final int targetUserId;
  final String? targetDisplayName;
  final String? targetProfileImageUrl;
  final bool isOutgoing;
  final bool autoAcceptIncoming;
  final int? callId;

  const CallPage({
    super.key,
    required this.targetUserId,
    this.targetDisplayName,
    this.targetProfileImageUrl,
    this.isOutgoing = true,
    this.autoAcceptIncoming = false,
    this.callId,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = sl<CallBloc>();

    return BlocProvider.value(
      value: bloc,
      child: _CallInitializer(
        isOutgoing: isOutgoing,
        autoAcceptIncoming: autoAcceptIncoming,
        targetUserId: targetUserId,
        targetDisplayName: targetDisplayName,
        callId: callId,
        child: _CallView(
          targetUserId: targetUserId,
          targetDisplayName: targetDisplayName,
          targetProfileImageUrl: targetProfileImageUrl,
        ),
      ),
    );
  }
}

class _CallInitializer extends StatefulWidget {
  final bool isOutgoing;
  final bool autoAcceptIncoming;
  final int targetUserId;
  final String? targetDisplayName;
  final int? callId;
  final Widget child;

  const _CallInitializer({
    required this.isOutgoing,
    required this.autoAcceptIncoming,
    required this.targetUserId,
    required this.targetDisplayName,
    required this.callId,
    required this.child,
  });

  @override
  State<_CallInitializer> createState() => _CallInitializerState();
}

class _CallInitializerState extends State<_CallInitializer> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<CallBloc>();
    if (widget.isOutgoing) {
      bloc.add(
        CallRequested(
          targetUserId: widget.targetUserId,
          targetDisplayName: widget.targetDisplayName,
        ),
      );
    } else {
      bloc.add(
        CallIncomingReceived(
          callerId: widget.targetUserId,
          callerDisplayName: widget.targetDisplayName,
          callId: widget.callId,
        ),
      );
      if (widget.autoAcceptIncoming) {
        bloc.add(const CallAccepted());
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CallView extends StatefulWidget {
  final int targetUserId;
  final String? targetDisplayName;
  final String? targetProfileImageUrl;

  const _CallView({
    required this.targetUserId,
    this.targetDisplayName,
    this.targetProfileImageUrl,
  });

  @override
  State<_CallView> createState() => _CallViewState();
}

class _CallViewState extends State<_CallView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    // Pulse animasyonu (arama sırasında)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Fade-in animasyonu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEnded) {
          // 2 saniye bekle, sonra geri dön
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      },
      builder: (context, state) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: _buildBackground(state),
              child: SafeArea(child: _buildContent(context, state)),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildBackground(CallState state) {
    if (state is CallActive) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A2A), Color(0xFF0D1B14)],
        ),
      );
    }
    if (state is CallEnded || state is CallError) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1A1A), Color(0xFF1B0D0D)],
        ),
      );
    }
    // Outgoing / Incoming / Connecting
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B2838), Color(0xFF0D1117)],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CallState state) {
    if (state is CallOutgoing) {
      return _buildOutgoingView(context, state);
    }
    if (state is CallIncoming) {
      return _buildIncomingView(context, state);
    }
    if (state is CallConnecting) {
      return _buildConnectingView(context, state);
    }
    if (state is CallActive) {
      return _buildActiveView(context, state);
    }
    if (state is CallEnded) {
      return _buildEndedView(context, state);
    }
    if (state is CallError) {
      return _buildErrorView(context, state);
    }
    // Initial — loading
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  // ============================================================
  // OUTGOING — Arıyor
  // ============================================================
  Widget _buildOutgoingView(BuildContext context, CallOutgoing state) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildAvatar(
            displayName: state.targetDisplayName ?? widget.targetDisplayName,
          ),
          const SizedBox(height: 24),
          Text(
            state.targetDisplayName ?? widget.targetDisplayName ?? 'Kullanıcı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arıyor...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 3),
          _buildHangUpButton(context),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ============================================================
  // INCOMING — Gelen Arama
  // ============================================================
  Widget _buildIncomingView(BuildContext context, CallIncoming state) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildAvatar(
            displayName: state.callerDisplayName ?? widget.targetDisplayName,
          ),
          const SizedBox(height: 24),
          Text(
            state.callerDisplayName ?? widget.targetDisplayName ?? 'Kullanıcı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gelen Arama',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 3),
          _buildIncomingActions(context),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTING — Bağlanıyor
  // ============================================================
  Widget _buildConnectingView(BuildContext context, CallConnecting state) {
    return Column(
      children: [
        const Spacer(flex: 2),
        _buildAvatar(displayName: widget.targetDisplayName),
        const SizedBox(height: 24),
        Text(
          widget.targetDisplayName ?? 'Kullanıcı',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bağlanıyor...',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(flex: 3),
        _buildHangUpButton(context),
        const SizedBox(height: 60),
      ],
    );
  }

  // ============================================================
  // ACTIVE — Konuşma
  // ============================================================
  Widget _buildActiveView(BuildContext context, CallActive state) {
    return Column(
      children: [
        const Spacer(flex: 2),
        _buildAvatar(displayName: widget.targetDisplayName, isActive: true),
        const SizedBox(height: 24),
        Text(
          widget.targetDisplayName ?? 'Kullanıcı',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(state.callDuration),
          style: const TextStyle(
            color: Color(0xFF4ADE80),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(flex: 3),
        _buildActiveActions(context, state),
        const SizedBox(height: 60),
      ],
    );
  }

  // ============================================================
  // ENDED — Bitti
  // ============================================================
  Widget _buildEndedView(BuildContext context, CallEnded state) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.15),
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.red,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Arama Sonlandı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (state.reason != null) ...[
          const SizedBox(height: 8),
          Text(
            state.reason!,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
        if (state.callDuration != null &&
            state.callDuration! > Duration.zero) ...[
          const SizedBox(height: 12),
          Text(
            'Süre: ${_formatDuration(state.callDuration!)}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const Spacer(flex: 3),
      ],
    );
  }

  // ============================================================
  // ERROR — Hata
  // ============================================================
  Widget _buildErrorView(BuildContext context, CallError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.15),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          state.message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Geri Dön',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  /// Animasyonlu avatar (pulse efekti)
  Widget _buildAvatar({String? displayName, bool isActive = false}) {
    final initial = (displayName?.isNotEmpty == true)
        ? displayName![0].toUpperCase()
        : '?';

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isActive
            ? 1.0
            : (1.0 + sin(_pulseController.value * 2 * pi) * 0.05);
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring 1
              if (!isActive)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        0.1 * (1 - _pulseController.value),
                      ),
                      width: 2,
                    ),
                  ),
                ),
              // Pulse ring 2
              if (!isActive)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
              // Main avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                        : [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isActive
                                  ? const Color(0xFF22C55E)
                                  : AppColors.primary)
                              .withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: widget.targetProfileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          widget.targetProfileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              // Active indicator
              if (isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D1B14),
                        width: 3,
                      ),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Kırmızı kapatma butonu
  Widget _buildHangUpButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        context.read<CallBloc>().add(const CallHangUp());
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  /// Gelen arama butonları (Kabul / Red)
  Widget _buildIncomingActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Red
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            context.read<CallBloc>().add(const CallRejected());
            Navigator.of(context).pop();
          },
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reddet',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        // Kabul
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.read<CallBloc>().add(const CallAccepted());
          },
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kabul Et',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Aktif arama butonları (Mute + HangUp)
  Widget _buildActiveActions(BuildContext context, CallActive state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<CallBloc>().add(const CallToggleMicrophone());
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isMicrophoneOn
                      ? Colors.white.withOpacity(0.1)
                      : Colors.red.withOpacity(0.3),
                  border: Border.all(
                    color: state.isMicrophoneOn
                        ? Colors.white24
                        : Colors.red.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  state.isMicrophoneOn
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.isMicrophoneOn ? 'Sessiz' : 'Sessiz',
                style: TextStyle(
                  color: state.isMicrophoneOn ? Colors.white60 : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // HangUp
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            context.read<CallBloc>().add(const CallHangUp());
          },
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bitir',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        // Speaker (placeholder)
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hoparlör',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
