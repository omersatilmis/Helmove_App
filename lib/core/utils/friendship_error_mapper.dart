import 'package:helmove/l10n/app_localizations.dart';

class FriendshipErrorMapper {
  const FriendshipErrorMapper._();

  static String mapForUi({
    required String rawMessage,
    required AppLocalizations l10n,
    String? fallback,
  }) {
    final normalized = _sanitize(rawMessage);

    if (_isFriendshipRestriction(normalized)) {
      return l10n.chatFriendshipRequiredMessage;
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return fallback ?? l10n.errorOccurred;
  }

  static String _sanitize(String message) {
    return message.replaceFirst(RegExp(r'^Exception:\\s*'), '').trim();
  }

  static bool _isFriendshipRestriction(String rawMessage) {
    final raw = rawMessage.toLowerCase();

    return raw.contains('arkadas') ||
        raw.contains('arkadaş') ||
        raw.contains('friend') ||
        raw.contains('not friends') ||
        raw.contains('friendship') ||
        raw.contains('forbidden') ||
        raw.contains('403');
  }
}
