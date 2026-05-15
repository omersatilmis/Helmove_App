import 'package:flutter/foundation.dart';
import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/ride_repository.dart';

class RideHistoryProvider extends ChangeNotifier {
  final RideRepository _repository;

  RideHistoryProvider(this._repository);

  List<RideEntity> _rides = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  static const int _limit = 20;

  List<RideEntity> get rides => _rides;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isEmpty => !_isLoading && _rides.isEmpty && _error == null;

  Future<void> loadRides({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _rides = [];
      _error = null;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getMyRides(page: _page, limit: _limit);
      if (refresh) {
        _rides = result.items;
      } else {
        _rides = [..._rides, ...result.items];
      }
      _hasMore = _rides.length < result.total;
      _page++;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveRide(RideEntity ride) async {
    final saved = await _repository.createRide(ride);
    _rides = [saved, ..._rides];
    notifyListeners();
  }

  Future<void> deleteRide(int id) async {
    await _repository.deleteRide(id);
    _rides = _rides.where((r) => r.id != id).toList();
    notifyListeners();
  }
}
