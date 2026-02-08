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
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<List<GroupRideModel>> getActiveGroupRides() async {
    try {
      final response = await _dio.get('/api/GroupRide');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => GroupRideModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<GroupRideModel> getGroupRideById(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId');
      return GroupRideModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
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
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<bool> deleteGroupRide(int rideId) async {
    try {
      final response = await _dio.delete('/api/GroupRide/$rideId');
      return response.data['data'] == true;
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
