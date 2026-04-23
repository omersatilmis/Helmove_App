class NetworkSettingsModel {
  final bool wifiOnlyDownload;

  const NetworkSettingsModel({required this.wifiOnlyDownload});

  factory NetworkSettingsModel.fromJson(Map<String, dynamic> json) {
    return NetworkSettingsModel(
      wifiOnlyDownload: (json['wifiOnlyDownload'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'wifiOnlyDownload': wifiOnlyDownload};
}
