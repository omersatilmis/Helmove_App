/// Motosiklet DTO
class MotorcycleDto {
  final int? id;
  final String brand;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? color;
  final int? engineSize;
  final String? description;
  final bool isPrimary;

  MotorcycleDto({
    this.id,
    required this.brand,
    required this.model,
    this.year,
    this.licensePlate,
    this.color,
    this.engineSize,
    this.description,
    this.isPrimary = false,
  });

  factory MotorcycleDto.fromJson(Map<String, dynamic> json) {
    return MotorcycleDto(
      id: json['id'],
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'],
      licensePlate: json['licensePlate'],
      color: json['color'],
      engineSize: json['engineSize'],
      description: json['description'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (color != null) 'color': color,
      if (engineSize != null) 'engineSize': engineSize,
      if (description != null) 'description': description,
      'isPrimary': isPrimary,
    };
  }
}

/// Motosiklet listesi response DTO
class MotorcyclesResponseDto {
  final bool success;
  final String? message;
  final List<MotorcycleDto>? data;

  MotorcyclesResponseDto({required this.success, this.message, this.data});

  factory MotorcyclesResponseDto.fromJson(Map<String, dynamic> json) {
    return MotorcyclesResponseDto(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
                .map((e) => MotorcycleDto.fromJson(e))
                .toList()
          : null,
    );
  }
}
