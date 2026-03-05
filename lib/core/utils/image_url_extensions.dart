extension ImageUrlOptimization on String? {
  String toAvatarThumbnail() {
    return _withImageQuery(const {'w': '80', 'q': '70'});
  }

  String toFeedThumbnail() {
    return _withImageQuery(const {'w': '400', 'q': '80'});
  }

  String _withImageQuery(Map<String, String> params) {
    final raw = (this ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(raw);
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return raw;
      }

      final query = Map<String, String>.from(uri.queryParameters);
      query.addAll(params);
      return uri.replace(queryParameters: query).toString();
    } catch (_) {
      return raw;
    }
  }
}
