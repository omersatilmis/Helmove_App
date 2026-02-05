import 'package:dio/dio.dart';
import '../models/group_ride_model.dart';
import '../models/group_ride_participant_model.dart';

/// GroupRide API istemcisi
class GroupRideApi {
  final Dio _dio;

  GroupRideApi(this._dio);

  /// Yeni grup turu oluşturur
  Future<GroupRideModel> createGroupRide(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/GroupRide', data: data);
      final responseData = response.data['data'] ?? response.data;
      return GroupRideModel.fromJson(responseData);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turu detaylarını getirir
  Future<GroupRideModel> getGroupRideById(int id) async {
    try {
      final response = await _dio.get('/api/GroupRide/$id');
      final responseData = response.data['data'] ?? response.data;
      return GroupRideModel.fromJson(responseData);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Aktif grup turlarını getirir
  Future<List<GroupRideModel>> getActiveGroupRides() async {
    try {
      final response = await _dio.get('/api/GroupRide');
      final responseData = response.data['data'] ?? response.data;
      return (responseData as List)
          .map((json) => GroupRideModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Kullanıcının tüm turlarını getirir
  Future<List<GroupRideModel>> getMyRides() async {
    try {
      final response = await _dio.get('/api/GroupRide/my-rides');
      final responseData = response.data['data'] ?? response.data;
      return (responseData as List)
          .map((json) => GroupRideModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Yakındaki grup turlarını getirir
  Future<List<GroupRideModel>> getNearbyGroupRides(
    double latitude,
    double longitude, {
    double radiusKm = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/GroupRide/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
        },
      );
      final responseData = response.data['data'] ?? response.data;
      return (responseData as List)
          .map((json) => GroupRideModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turuna katılır
  Future<void> joinGroupRide(int rideId, {String? joinMessage}) async {
    try {
      await _dio.post(
        '/api/GroupRide/$rideId/join',
        data: joinMessage != null ? {'joinMessage': joinMessage} : null,
      );
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turundan ayrılır
  Future<void> leaveGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turu katılımcılarını getirir
  Future<List<GroupRideParticipantModel>> getParticipants(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId/participants');
      final responseData = response.data['data'] ?? response.data;
      return (responseData as List)
          .map((json) => GroupRideParticipantModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turunu başlatır
  Future<void> startGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/start');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turunu tamamlar
  Future<void> completeGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/complete');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  /// Grup turunu siler
  Future<void> deleteGroupRide(int rideId) async {
    try {
      await _dio.delete('/api/GroupRide/$rideId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  String _parseErrorMessage(dynamic data) {
    if (data == null) return 'Bir hata oluştu';
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['title'] ?? 'Bir hata oluştu';
    }
    return data.toString();
  }
}
