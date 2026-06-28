import 'package:helmove/features/map/domain/entities/location_entity.dart';

/// [Rota Planlayıcı] giriş argümanları.
///
/// MapPage'i "planlama modunda" açar. Verilen [start]/[end]/[stops] varsa
/// harita açılır açılmaz o rota yüklenir (mevcut plan düzenleniyorsa). Hepsi
/// opsiyonel: boşsa organizatör başlangıç/hedefi haritada kendisi seçer.
class RoutePlannerArgs {
  final LocationEntity? start;
  final LocationEntity? end;
  final List<LocationEntity> stops;

  const RoutePlannerArgs({
    this.start,
    this.end,
    this.stops = const [],
  });
}
