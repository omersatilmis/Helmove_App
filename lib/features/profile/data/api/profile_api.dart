import 'package:dio/dio.dart';
import 'profile_endpoints.dart';
import '../dto/profile_response_dto.dart';
import '../dto/update_profile_request_dto.dart';
import '../dto/motorcycle_dto.dart';
import '../../../../core/utils/app_logger.dart';

class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  /// GET /api/Profile/me - Kullanıcının kendi profilini getirir
  Future<ProfileResponseDto> getMyProfile() async {
    try {
      final response = await _dio.get(ProfileEndpoints.me);
      return ProfileResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Profil getirme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me - Kullanıcının profilini günceller
  Future<ProfileResponseDto> updateProfile(
    UpdateProfileRequestDto request,
  ) async {
    try {
      final response = await _dio.put(
        ProfileEndpoints.me,
        data: request.toJson(),
      );
      return ProfileResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Profil güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// GET /api/Profile/{userId} - Başka bir kullanıcının profilini getirir
  Future<ProfileResponseDto> getUserProfile(int userId) async {
    try {
      final response = await _dio.get(ProfileEndpoints.userProfile(userId));
      return ProfileResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Kullanıcı profili getirme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/picture - Profil resmini günceller
  Future<ProfileResponseDto> updateProfilePicture(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'ProfilePicture': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.put(ProfileEndpoints.picture, data: formData);
      return ProfileResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Profil resmi güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/cover - Kapak resmini günceller
  Future<ProfileResponseDto> updateCoverPhoto(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'CoverPicture': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.put('/Profile/me/cover', data: formData);
      return ProfileResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Kapak resmi güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/location - Konumu günceller
  Future<void> updateLocation(UpdateLocationRequestDto request) async {
    try {
      await _dio.put(ProfileEndpoints.location, data: request.toJson());
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Konum güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// GET /api/Profile/me/motorcycles - Motosikletleri getirir
  Future<MotorcyclesResponseDto> getMotorcycles() async {
    try {
      final response = await _dio.get(ProfileEndpoints.motorcycles);
      return MotorcyclesResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Motosikletler getirme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// POST /api/Profile/me/motorcycles - Yeni motosiklet ekler
  Future<MotorcycleDto> addMotorcycle(MotorcycleDto motorcycle) async {
    try {
      final response = await _dio.post(
        ProfileEndpoints.motorcycles,
        data: motorcycle.toJson(),
      );
      if (response.data['data'] != null) {
        return MotorcycleDto.fromJson(response.data['data']);
      }
      return motorcycle;
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Motosiklet ekleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/motorcycles/{motorcycleId} - Motosikleti günceller
  Future<MotorcycleDto> updateMotorcycle(
    int motorcycleId,
    MotorcycleDto motorcycle,
  ) async {
    try {
      final response = await _dio.put(
        ProfileEndpoints.motorcycle(motorcycleId),
        data: motorcycle.toJson(),
      );
      if (response.data['data'] != null) {
        return MotorcycleDto.fromJson(response.data['data']);
      }
      return motorcycle;
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Motosiklet güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// DELETE /api/Profile/me/motorcycles/{motorcycleId} - Motosikleti siler
  Future<void> deleteMotorcycle(int motorcycleId) async {
    try {
      await _dio.delete(ProfileEndpoints.motorcycle(motorcycleId));
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Motosiklet silme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/motorcycles/{motorcycleId}/primary - Ana motosikleti ayarlar
  Future<void> setPrimaryMotorcycle(int motorcycleId) async {
    try {
      await _dio.put(ProfileEndpoints.primaryMotorcycle(motorcycleId));
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Ana motosiklet ayarlama başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// PUT /api/Profile/me/online-status - Online durumunu değiştirir
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      await _dio.put(ProfileEndpoints.onlineStatus, data: isOnline);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Online durum güncelleme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// GET /api/Profile/isOnline/{userId} - Kullanıcının online durumunu kontrol eder
  Future<bool> isUserOnline(int userId) async {
    try {
      final response = await _dio.get(ProfileEndpoints.isOnline(userId));
      return response.data['data'] ?? false;
    } on DioException catch (e) {
      AppLogger.warning("Online durum kontrolü hatası: ${e.message}");
      return false;
    } catch (e) {
      AppLogger.warning("Beklenmedik hata: $e");
      return false;
    }
  }

  /// Hata mesajını response body'den güvenli bir şekilde çıkarır
  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['detail'] ??
          data['error'] ??
          data['description'];
    }

    if (data is String) {
      return data;
    }

    return data.toString();
  }
}
