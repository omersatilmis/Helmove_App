/// Keşfet filtreleri için zorluk seviyesi. apiValue backend canonical değerleri
/// (`create_group_ride` ile birebir): Beginner | Intermediate | Advanced | Expert.
enum RideDifficulty { beginner, intermediate, advanced, expert }

/// Keşfet filtreleri için sürüş tarzı. apiValue: Sakin | Tour | Viraj | Sehir.
enum RideStyle { sakin, tour, viraj, sehir }

extension RideDifficultyX on RideDifficulty {
  String get apiValue => switch (this) {
    RideDifficulty.beginner => 'Beginner',
    RideDifficulty.intermediate => 'Intermediate',
    RideDifficulty.advanced => 'Advanced',
    RideDifficulty.expert => 'Expert',
  };
}

extension RideStyleX on RideStyle {
  String get apiValue => switch (this) {
    RideStyle.sakin => 'Sakin',
    RideStyle.tour => 'Tour',
    RideStyle.viraj => 'Viraj',
    RideStyle.sehir => 'Sehir',
  };
}
