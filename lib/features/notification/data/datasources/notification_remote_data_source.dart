import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../models/notification_dto.dart';
import '../models/notification_group_dto.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationDto>> getNotifications(int page);
  Future<List<NotificationGroupDto>> getGroupedNotifications(int page);
  Future<int> getUnreadCount();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(int id);
  Future<void> markGroupAsRead({int? actorId, required int type});
  Future<void> deleteGroup({int? actorId, required int type});
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
      }
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<NotificationGroupDto>> getGroupedNotifications(int page) async {
    try {
      final response = await client.get(
        '/api/notifications/grouped',
        queryParameters: {'page': page},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['data'] ?? [];
        return data
            .map((json) => NotificationGroupDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw ServerException();
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
      }
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await client.post('/api/notifications/read/$id');
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await client.post('/api/notifications/read-all');
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteNotification(int id) async {
    try {
      await client.delete('/api/notifications/$id');
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> markGroupAsRead({int? actorId, required int type}) async {
    try {
      await client.post(
        '/api/notifications/read-group',
        data: {'actorId': actorId, 'type': type},
      );
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteGroup({int? actorId, required int type}) async {
    try {
      await client.delete(
        '/api/notifications/group',
        data: {'actorId': actorId, 'type': type},
      );
    } catch (e) {
      throw ServerException();
    }
  }
}
