/// Motosiklet Domain Entity
class MotorcycleEntity {
  final int? id;
  final String brand;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? color;
  final int? engineSize;
  final String? description;
  final bool isPrimary;

  const MotorcycleEntity({
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

  /// Motosiklet tam adı (Marka + Model)
  String get fullName => '$brand $model';

  /// Motor hacmi formatı
  String get engineSizeFormatted => engineSize != null ? '${engineSize}cc' : '';

  @override
  String toString() {
    return 'MotorcycleEntity(id: $id, $fullName, year: $year)';
  }
}
