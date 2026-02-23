import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/connectivity_watcher_service.dart';
import '../../../core/di/injection_container.dart';
import '../../theme/text_styles.dart';

class ConnectionStatusOverlay extends StatelessWidget {
  const ConnectionStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final watcher = sl<ConnectivityWatcherService>();

    return StreamBuilder<ConnectionStatus>(
      stream: watcher.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.none;

        if (status.type == ConnectionStatusType.online) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildToast(context, status)],
          ),
        );
      },
    );
  }

  Widget _buildToast(BuildContext context, ConnectionStatus status) {
    final color = _getStatusColor(status.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  _getIcon(status.type, color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status.message,
                      style: AppTextStyles.medium.copyWith(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (status.type == ConnectionStatusType.reconnecting ||
                      status.type == ConnectionStatusType.connecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ConnectionStatusType type) {
    switch (type) {
      case ConnectionStatusType.disconnected:
        return Colors.redAccent;
      case ConnectionStatusType.reconnecting:
      case ConnectionStatusType.connecting:
        return Colors.orangeAccent;
      case ConnectionStatusType.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getIcon(ConnectionStatusType type, Color color) {
    IconData iconData;
    switch (type) {
      case ConnectionStatusType.disconnected:
        iconData = Icons.wifi_off_rounded;
        break;
      case ConnectionStatusType.reconnecting:
      case ConnectionStatusType.connecting:
        iconData = Icons.sync_rounded;
        break;
      case ConnectionStatusType.failed:
        iconData = Icons.error_outline_rounded;
        break;
      default:
        iconData = Icons.info_outline;
    }
    return Icon(iconData, color: color, size: 20);
  }
}
