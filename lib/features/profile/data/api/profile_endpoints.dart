/// Profile API Endpoint sabitleri
class ProfileEndpoints {
  static const String base = '/api/Profile';

  // Kullanıcının kendi profili
  static const String me = '$base/me';

  // Profil resmi
  static const String picture = '$base/me/picture';

  // Konum
  static const String location = '$base/me/location';

  // Motosikletler
  static const String motorcycles = '$base/me/motorcycles';

  // Online durumu
  static const String onlineStatus = '$base/me/online-status';

  // Başka kullanıcının profili
  static String userProfile(int userId) => '$base/$userId';

  // Belirli motosiklet
  static String motorcycle(int motorcycleId) => '$motorcycles/$motorcycleId';

  // Ana motosiklet ayarla
  static String primaryMotorcycle(int motorcycleId) =>
      '$motorcycles/$motorcycleId/primary';

  // Kullanıcının online durumu
  static String isOnline(int userId) => '$base/isOnline/$userId';

  // Arama
  static const String search = '$base/search';
}
