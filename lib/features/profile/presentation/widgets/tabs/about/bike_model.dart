// backend bağlantısında bunun konumu değişecek

// bike_model.dart
class BikeModel {
  String id;
  String makeModel, cc, year, color, plate, description;
  bool isFavorite;

  BikeModel({
    required this.id,
    this.makeModel = "",
    this.cc = "",
    this.year = "",
    this.color = "",
    this.plate = "",
    this.description = "",
    this.isFavorite = false,
  });
}
