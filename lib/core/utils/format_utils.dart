class FormatUtils {
  static String formatDistance(double meters) {
    if (meters <= 0) return '--';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  static String formatDuration(double seconds) {
    if (seconds <= 0) return '--';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes dk';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '$hours sa $remaining dk';
  }

  static String formatEta(double durationSeconds) {
    if (durationSeconds <= 0) return '--:--';
    final eta = DateTime.now().add(Duration(seconds: durationSeconds.round()));
    final hour = eta.hour.toString().padLeft(2, '0');
    final minute = eta.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
