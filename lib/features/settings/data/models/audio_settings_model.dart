class AudioSettingsModel {
  final bool? noiseCancellationEnabled;
  final bool? voiceNavigationEnabled;
  final bool? backgroundMusicEnabled;

  const AudioSettingsModel({
    this.noiseCancellationEnabled,
    this.voiceNavigationEnabled,
    this.backgroundMusicEnabled,
  });

  factory AudioSettingsModel.fromJson(Map<String, dynamic> json) {
    return AudioSettingsModel(
      noiseCancellationEnabled: json['noiseCancellationEnabled'] as bool?,
      voiceNavigationEnabled: json['voiceNavigationEnabled'] as bool?,
      backgroundMusicEnabled: json['backgroundMusicEnabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (noiseCancellationEnabled != null) {
      map['noiseCancellationEnabled'] = noiseCancellationEnabled;
    }
    if (voiceNavigationEnabled != null) {
      map['voiceNavigationEnabled'] = voiceNavigationEnabled;
    }
    if (backgroundMusicEnabled != null) {
      map['backgroundMusicEnabled'] = backgroundMusicEnabled;
    }
    return map;
  }
}
