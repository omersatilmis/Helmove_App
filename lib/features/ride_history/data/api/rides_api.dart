import 'package:dio/dio.dart';
import '../models/ride_model.dart';

class RidesApi {
  final Dio _dio;

  RidesApi(this._dio);

  Future<({List<RideModel> items, int total})> getMyRides({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/rides/me',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = response.data as Map<String, dynamic>;
      final total = body['total'] as int? ?? 0;
      final List<dynamic> raw = body['items'] as List<dynamic>? ?? [];
      final items = raw
          .map((json) => RideModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return (items: items, total: total);
    } on DioException catch (e) {
      throw Exception('Rotalar alınamadı: ${e.response?.statusCode}');
    }
  }

  Future<RideModel> getRideById(int id) async {
    try {
      final response = await _dio.get('/api/rides/$id');
      return RideModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Rota alınamadı: ${e.response?.statusCode}');
    }
  }

  Future<RideModel> createRide(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/api/rides', data: body);
      return RideModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Rota kaydedilemedi: ${e.response?.statusCode}');
    }
  }

  Future<void> deleteRide(int id) async {
    try {
      await _dio.delete('/api/rides/$id');
    } on DioException catch (e) {
      throw Exception('Rota silinemedi: ${e.response?.statusCode}');
    }
  }
}
