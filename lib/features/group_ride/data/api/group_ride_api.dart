import 'package:dio/dio.dart';
import '../datasources/group_ride_remote_data_source.dart';
import '../models/group_ride_model.dart';
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
