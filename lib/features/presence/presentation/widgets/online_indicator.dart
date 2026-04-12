import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/models/user_presence_model.dart';
import '../../services/presence_controller.dart';

/// Yeşil çevrimiçi noktası veya "son görülme" yazısı gösterir.
///
/// Kullanım:
/// ```dart
/// // Avatar üzerinde overlay dot:
/// Stack(
///   children: [
///     AppAvatar(userId: userId),
///     Positioned(
///       right: 0, bottom: 0,
///       child: OnlineStatusDot(userId: userId),
///     ),
///   ],
/// )
///
/// // Profil sayfasında metin:
/// OnlineStatusText(userId: userId)
/// ```

// ── Dot Widget ─────────────────────────────────────────────────────────────

class OnlineStatusDot extends StatelessWidget {
  final int userId;
  final double size;
  final Color onlineColor;
  final Color borderColor;

  const OnlineStatusDot({
    super.key,
    required this.userId,
    this.size = 12,
    this.onlineColor = const Color(0xFF4CAF50),
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.instance<PresenceController>();

    return StreamBuilder<Map<int, UserPresenceModel>>(
      stream: controller.presenceStream,
      initialData: controller.currentPresence,
      builder: (context, snapshot) {
        final presence = snapshot.data?[userId];
        final isOnline = presence?.isOnline ?? false;

        if (!isOnline) return const SizedBox.shrink();

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onlineColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
        );
      },
    );
  }
}

// ── Text Widget ─────────────────────────────────────────────────────────────

class OnlineStatusText extends StatelessWidget {
  final int userId;
  final TextStyle? onlineStyle;
  final TextStyle? offlineStyle;

  const OnlineStatusText({
    super.key,
    required this.userId,
    this.onlineStyle,
    this.offlineStyle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.instance<PresenceController>();

    return StreamBuilder<Map<int, UserPresenceModel>>(
      stream: controller.presenceStream,
      initialData: controller.currentPresence,
      builder: (context, snapshot) {
        final presence = snapshot.data?[userId];
        return _buildText(context, presence);
      },
    );
  }

  Widget _buildText(BuildContext context, UserPresenceModel? presence) {
    final defaultOnlineStyle = onlineStyle ??
        const TextStyle(
          fontSize: 12,
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.w500,
        );
    final defaultOfflineStyle = offlineStyle ??
        const TextStyle(fontSize: 12, color: Colors.grey);

    if (presence == null) {
      return Text('Bilinmiyor', style: defaultOfflineStyle);
    }

    if (presence.isOnline) {
      return Text('Şu an çevrimiçi', style: defaultOnlineStyle);
    }

    final lastSeen = presence.lastSeen;
    if (lastSeen == null) {
      return Text('Çevrimdışı', style: defaultOfflineStyle);
    }

    // timeago paketi ile Türkçe görece zaman
    final relative = timeago.format(lastSeen, locale: 'tr');
    return Text('Son görülme: $relative', style: defaultOfflineStyle);
  }
}

// ── Composite: Avatar + Dot ─────────────────────────────────────────────────

/// Avatar üstüne online dot overlay'i ekler.
/// [child] parametre olarak herhangi bir avatar widget'ı alır.
class OnlineAvatarWrapper extends StatelessWidget {
  final int userId;
  final Widget child;
  final double dotSize;
  final Alignment dotAlignment;

  const OnlineAvatarWrapper({
    super.key,
    required this.userId,
    required this.child,
    this.dotSize = 12,
    this.dotAlignment = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: OnlineStatusDot(userId: userId, size: dotSize),
        ),
      ],
    );
  }
}
