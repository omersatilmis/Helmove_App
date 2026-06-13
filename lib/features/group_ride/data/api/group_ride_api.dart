import 'package:dio/dio.dart';
import '../datasources/group_ride_remote_data_source.dart';
import '../models/group_ride_model.dart';
import '../models/group_ride_summary_model.dart';
import '../dto/create_group_ride_request_dto.dart';

class GroupRideApi implements GroupRideRemoteDataSource {
  final Dio _dio;

  GroupRideApi(this._dio);

  @override
  Future<GroupRideModel> createGroupRide(
    CreateGroupRideRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/GroupRide',
        data: request.toJson(),
      );
      return GroupRideModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<List<GroupRideModel>> getActiveGroupRides() async {
    try {
      final response = await _dio.get('/api/GroupRide');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => GroupRideModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<GroupRideModel> getGroupRideById(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId');
      return GroupRideModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<GroupRideModel> updateGroupRide(
    int rideId,
    GroupRideModel ride,
  ) async {
    try {
      final response = await _dio.put(
        '/api/GroupRide/$rideId',
        data: ride.toJson(),
      );
      return GroupRideModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<bool> deleteGroupRide(int rideId) async {
    try {
      final response = await _dio.delete('/api/GroupRide/$rideId');
      final body = response.data;
      if (body is Map<String, dynamic>) {
        if (body['success'] == true) return true;
        // Backend returned success=false with a message
        throw Exception(body['message'] ?? 'Grup turu silinemedi');
      }
      return false;
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  Future<void> sendSosAlert({
    required int rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post(
        '/api/GroupRide/$rideId/sos',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  /// Keşfet araması (çoklu kriter). Tüm parametreler opsiyonel; sadece dolu
  /// olanlar gönderilir. lat/lng/radius search'te yok sayıldığı için gönderilmez.
  @override
  Future<List<GroupRideSummaryModel>> searchGroupRides({
    String? title,
    String? location,
    String? difficulty,
    String? ridingStyle,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.post(
        '/api/GroupRide/search',
        data: {
          if (title != null && title.isNotEmpty) 'title': title,
          if (location != null && location.isNotEmpty) 'location': location,
          if (difficulty != null) 'difficulty': difficulty,
          if (ridingStyle != null) 'ridingStyle': ridingStyle,
          if (status != null) 'status': status,
          if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
          if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      return _parseSummaryList(response.data);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  /// Yakındaki turlar. response item'larında `distanceKm` dolu döner.
  @override
  Future<List<GroupRideSummaryModel>> getNearbyGroupRides({
    required double latitude,
    required double longitude,
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
      return _parseSummaryList(response.data);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  /// `{success, message, data[]}` zarfını açar; data[] → GroupRideSummaryModel.
  List<GroupRideSummaryModel> _parseSummaryList(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) {
        throw Exception(body['message'] ?? 'Grup turları yüklenemedi');
      }
      final List<dynamic> data = body['data'] as List? ?? const [];
      return data
          .map((e) => GroupRideSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  String _parseErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Bağlantı zaman aşımına uğradı.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map<String, dynamic>) {
            return data['message'] ??
                data['title'] ??
                'Sunucu hatası (${error.response?.statusCode})';
          }
          return 'Sunucu hatası (${error.response?.statusCode})';
        case DioExceptionType.connectionError:
          return 'İnternet bağlantısı yok.';
        default:
          return 'Bir ağ hatası oluştu.';
      }
    }
    if (error is Map<String, dynamic>) {
      return error['message'] ?? error['title'] ?? 'Bir hata oluştu';
    }
    return error?.toString() ?? 'Bilinmeyen bir hata oluştu';
  }
}
