import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';
import '../../../../features/messages/presentation/pages/call_page.dart';

/// Global Gelen Arama Overlay'i
///
/// App seviyesinde BlocListener ile kullanılır.
/// CallBloc'tan [CallIncoming] state geldiğinde bu overlay'i gösterir.
///
/// Kullanım (örneğin main.dart veya app_router wrapper):
/// ```dart
/// IncomingCallOverlay.show(context, callerId, callerName);
/// ```
class IncomingCallOverlay {
  /// Gelen arama dialog'unu gösterir
  static void show(
    BuildContext context, {
    required int callerId,
    String? callerDisplayName,
    String? callerProfileImageUrl,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _IncomingCallDialog(
          callerId: callerId,
          callerDisplayName: callerDisplayName,
          callerProfileImageUrl: callerProfileImageUrl,
        );
      },
    );
  }
}

class _IncomingCallDialog extends StatefulWidget {
  final int callerId;
  final String? callerDisplayName;
  final String? callerProfileImageUrl;

  const _IncomingCallDialog({
    required this.callerId,
    this.callerDisplayName,
    this.callerProfileImageUrl,
  });

  @override
  State<_IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<_IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.callerDisplayName?.isNotEmpty == true)
        ? widget.callerDisplayName![0].toUpperCase()
        : '?';

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst: "Gelen Arama" label
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Icon(
                            Icons.call_rounded,
                            color: Color.lerp(
                              const Color(0xFF22C55E),
                              const Color(0xFF86EFAC),
                              (sin(_pulseController.value * 2 * pi) + 1) / 2,
                            ),
                            size: 18,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Gelen Arama',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Orta: Avatar + İsim
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                        child: widget.callerProfileImageUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.callerProfileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Center(
                                    child: Text(
                                      widget.callerDisplayName?[0].toUpperCase() ?? '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.callerDisplayName ?? 'Bilinmeyen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Sesli arama',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Alt: Kabul / Red butonları
                  Row(
                    children: [
                      // Reddet
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            // CallBloc üzerinden reject
                            try {
                              context.read<CallBloc>().add(
                                const CallRejected(),
                              );
                            } catch (_) {
                              // Bloc yoksa DI'dan yeni oluştur
                              sl<CallBloc>().add(const CallRejected());
                            }
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.red.withValues(alpha:0.15),
                              border: Border.all(
                                color: Colors.red.withValues(alpha:0.3),
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reddet',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kabul Et
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            // CallPage'e yönlendir (incoming mode)
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CallPage(
                                  targetUserId: widget.callerId,
                                  targetDisplayName: widget.callerDisplayName,
                                  targetProfileImageUrl:
                                      widget.callerProfileImageUrl,
                                  isOutgoing: false,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha:0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kabul Et',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
