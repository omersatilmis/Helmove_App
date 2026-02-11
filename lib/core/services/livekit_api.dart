import 'package:dio/dio.dart';

/// Backend `api/livekit` endpoint'leri ile iletişim.
/// Token, room CRUD ve participant yönetimi.
class LiveKitApi {
  final Dio _dio;

  LiveKitApi(this._dio);

  // ============================================================
  // TOKEN
  // ============================================================

  /// LiveKit JWT token üretimi.
  /// [roomName] — VoiceSession.roomName ile eşleşir.
  /// [displayName] — Kullanıcının görüntülenen adı.
  /// Returns: `{token: String, url: String}`
  Future<Map<String, String>> getToken({
    required String roomName,
    String? displayName,
    int ttlMinutes = 360,
  }) async {
    try {
      final response = await _dio.post(
        '/api/livekit/token',
        data: {
          'roomName': roomName,
          'displayName': displayName,
          'ttlMinutes': ttlMinutes,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return {
          'token': (data['token'] ?? '') as String,
          'url': (data['url'] ?? '') as String,
        };
      }
      throw Exception('Invalid token response format');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ============================================================
  // ROOM CRUD (optional — backend genelde otomatik yapar)
  // ============================================================

  /// Yeni bir LiveKit SFU room oluşturur.
  Future<Map<String, dynamic>> createRoom({
    required String roomName,
    int maxParticipants = 20,
    int emptyTimeout = 300,
  }) async {
    try {
      final response = await _dio.post(
        '/api/livekit/rooms',
        data: {
          'roomName': roomName,
          'maxParticipants': maxParticipants,
          'emptyTimeout': emptyTimeout,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  /// Aktif roomları listeler.
  Future<List<dynamic>> listRooms() async {
    try {
      final response = await _dio.get('/api/livekit/rooms');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['data'] ?? []) as List<dynamic>;
      }
      return data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  /// Bir room'u siler.
  Future<void> deleteRoom(String roomName) async {
    try {
      await _dio.delete('/api/livekit/rooms/$roomName');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ============================================================
  // KATILIMCI YÖNETİMİ (admin/moderatör için)
  // ============================================================

  /// Katılımcıyı room'dan çıkarır.
  Future<void> removeParticipant(String roomName, String identity) async {
    try {
      await _dio.post(
        '/api/livekit/rooms/$roomName/participants/$identity/remove',
      );
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  /// Katılımcının sesini kapatır/açar.
  Future<void> muteParticipant(
    String roomName,
    String identity, {
    bool muted = true,
  }) async {
    try {
      await _dio.post(
        '/api/livekit/rooms/$roomName/participants/$identity/mute',
        queryParameters: {'muted': muted},
      );
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ============================================================
  // ICE SERVERS — P2P için (Mode A)
  // ============================================================

  /// P2P çağrılar için TURN/STUN sunucu bilgilerini alır.
  Future<Map<String, dynamic>> getIceServers() async {
    try {
      final response = await _dio.get('/api/livekit/ice-servers');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data == null) return 'LiveKit API hatası: ${e.message}';
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['title'] ?? 'LiveKit API hatası';
    }
    return data.toString();
  }
}
