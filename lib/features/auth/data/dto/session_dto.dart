class SessionDto {
  final int id;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isCurrent;

  SessionDto({
    required this.id,
    this.deviceInfo,
    this.ipAddress,
    this.createdAt,
    this.expiresAt,
    required this.isCurrent,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: json['id'] ?? 0,
      deviceInfo: json['deviceInfo'],
      ipAddress: json['ipAddress'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}
