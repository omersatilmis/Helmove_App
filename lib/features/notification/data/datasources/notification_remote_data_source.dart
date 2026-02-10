import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../models/notification_dto.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationDto>> getNotifications(int page);
  Future<int> getUnreadCount();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio client;

  NotificationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationDto>> getNotifications(int page) async {
    try {
      final response = await client.get(
        '/api/notifications',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['data'] ?? [];
        return data.map((json) => NotificationDto.fromJson(json)).toList();
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await client.get('/api/notifications/unread-count');
      if (response.statusCode == 200) {
        return response.data is int
            ? response.data
            : (response.data['count'] ?? 0);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      final response = await client.post('/api/notifications/read/$id');
      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await client.post('/api/notifications/read-all');
      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteNotification(int id) async {
    try {
      final response = await client.delete('/api/notifications/$id');
      if (response.statusCode != 200) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}
