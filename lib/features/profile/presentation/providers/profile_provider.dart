import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:helmove/features/profile/domain/entities/profile_entity.dart';
import 'package:helmove/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:helmove/features/profile/domain/repositories/profile_repository.dart';
import 'package:helmove/core/utils/app_logger.dart';
import 'package:helmove/core/network/network_service.dart';
import 'package:helmove/core/utils/image_compressor.dart';
import 'package:helmove/core/services/app_session.dart';
import 'package:get_it/get_it.dart';
import 'package:helmove/features/auth/data/datasources/auth_local_data_source.dart';

import '../../../../core/enums/user_tier.dart';

/// ProfileProvider - Profil verilerini yönetir
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final AppSession _appSession;
  StreamSubscription<int?>? _sessionUserIdSubscription;

  ProfileProvider(this._profileRepository, this._appSession) {
    _currentUserId = _appSession.currentUserId;
    _sessionUserIdSubscription = _appSession.currentUserIdStream
        .distinct()
        .listen((userId) {
          if (_currentUserId == userId) {
            return;
          }
          _currentUserId = userId;
          if (userId == null) {
            _profile = null;
            _visitedProfile = null;
            _motorcycles = [];
          }
          notifyListeners();
        });
  }

  // State
  bool _isLoading = false;
  String? _errorMessage;
  ProfileEntity? _profile;
  ProfileEntity? _visitedProfile; // Başkasının profili
  List<MotorcycleEntity> _motorcycles = [];
  int? _currentUserId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfileEntity? get profile => _profile;
  ProfileEntity? get visitedProfile => _visitedProfile;
  List<MotorcycleEntity> get motorcycles => _motorcycles;
  int? get currentUserId => _currentUserId;

  // Helper getters (Sadece kendi profilim için)
  String get firstName => _profile?.firstName ?? '';
  String get lastName => _profile?.lastName ?? '';
  String get username => _profile?.username ?? 'Kullanıcı';
  String get email => _profile?.email ?? '';
  String get fullName => _profile?.fullName ?? username;
  String? get profileImageUrl => _profile?.profileImageUrl;
  String? get bio => _profile?.bio;
  UserTier get userTier => _profile?.tier ?? UserTier.free;
  String? get phoneNumber => _profile?.phoneNumber;
  String? get city => _profile?.city;
  String? get region => _profile?.region;
  bool get isLoggedIn => _profile != null;

  bool isOwnProfileTarget(String? targetUserId) {
    if (targetUserId == null) {
      return _currentUserId != null;
    }

    if (_currentUserId == null) {
      return false;
    }

    return targetUserId == _currentUserId.toString();
  }

  /// Kendi profilimi yükler
  Future<void> loadProfile({bool forceRefresh = false}) async {
    // Eğer profil zaten yüklüyse ve zorunlu yenileme değilse, isteği atma (Oturum boyu cache)
    if (_profile != null && !forceRefresh) {
      return;
    }

    _setLoading(true);
    clearError();
    _visitedProfile = null; // Kendi profilimize geçerken visited'ı temizle

    try {
      // 1. Önce cache'den veriyi çek (Uygulama açılışında hızlı göstermek için)
      if (_profile == null) {
        try {
          final localAuth = GetIt.I<AuthLocalDataSource>();
          final firstName = await localAuth.getFirstName();
          final lastName = await localAuth.getLastName();
          final username = await localAuth.getUsername();
          final email = await localAuth.getEmail();
          final profileImageUrl = await localAuth.getProfileImageUrl();
          final followersCount = await localAuth.getFollowersCount();
          final followingCount = await localAuth.getFollowingCount();
          final friendsCount = await localAuth.getFriendsCount();

          if (firstName != null || lastName != null || username != null) {
            _profile = ProfileEntity(
              id: _currentUserId ?? 0,
              username: username ?? '',
              email: email ?? '',
              tier: UserTier.free, // Local cache fallback
              firstName: firstName,
              lastName: lastName,
              profileImageUrl: profileImageUrl,
              followersCount: followersCount ?? 0,
              followingCount: followingCount ?? 0,
              friendsCount: friendsCount ?? 0,
              isFollowing: false,
            );
            notifyListeners();
          }
        } catch (_) {}
      }

      // 3. Sunucudan veriyi çek
      final newProfile = await _profileRepository.getMyProfile();
      _profile = newProfile;

      // 4. Cache'i güncelle
      try {
        if (_profile != null) {
          final localAuth = GetIt.I<AuthLocalDataSource>();
          await localAuth.saveFirstName(_profile!.firstName);
          await localAuth.saveLastName(_profile!.lastName);
          await localAuth.saveUsername(_profile!.username);
          await localAuth.saveEmail(_profile!.email);
          await localAuth.saveProfileImageUrl(_profile!.profileImageUrl);
          await localAuth.saveFollowersCount(_profile!.followersCount);
          await localAuth.saveFollowingCount(_profile!.followingCount);
          await localAuth.saveFriendsCount(_profile!.friendsCount);
        }
      } catch (_) {
        // Cache yazma hatalarını göz ardı et
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Başkasının profilini yükler
  Future<void> loadUserProfile(int userId, {bool forceRefresh = false}) async {
    // Eğer bu kullanıcının profili zaten yüklüyse ve zorunlu yenileme değilse, isteği atma
    if (_visitedProfile != null &&
        _visitedProfile!.id == userId &&
        !forceRefresh) {
      return;
    }

    debugPrint(
      '🔍 [ProfileProvider] loadUserProfile called with userId: $userId',
    );
    _setLoading(true);
    clearError();
    _visitedProfile = null; // Önce temizle

    try {
      final response = await _profileRepository.getUserProfile(userId);
      _visitedProfile = response;
      debugPrint(
        '🔍 [ProfileProvider] visitedProfile loaded: ${_visitedProfile?.firstName} ${_visitedProfile?.lastName}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ProfileProvider] loadUserProfile error: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Takip durumunu ve sayılarını yerel olarak günceller (Optimistic Update)
  void updateFollowStats({
    required int userId,
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
  }) {
    // 1. Eğer başkasının profilindeysek ve o id ise güncelle
    if (_visitedProfile != null && _visitedProfile!.id == userId) {
      _visitedProfile = _visitedProfile!.copyWith(
        isFollowing: isFollowing ?? _visitedProfile!.isFollowing,
        followersCount: followersCount ??
            (isFollowing == true
                ? _visitedProfile!.followersCount + 1
                : isFollowing == false
                    ? (_visitedProfile!.followersCount - 1).clamp(0, 999999)
                    : _visitedProfile!.followersCount),
      );
      notifyListeners();
    }

    // 2. Kendi profilimizdeki "followingCount"u (takip edilen sayısı) her durumda güncellenmeli.
    if (_profile != null && _profile!.id != userId) {
      final int currentFollowing = _profile!.followingCount;
      final int newFollowing = followingCount ??
          (isFollowing == true
              ? currentFollowing + 1
              : isFollowing == false
                  ? (currentFollowing - 1).clamp(0, 999999)
                  : currentFollowing);

      _profile = _profile!.copyWith(
        followingCount: newFollowing,
      );

      // Cache'i güncelle (Takip edilen sayısı için)
      try {
        final localAuth = GetIt.I<AuthLocalDataSource>();
        localAuth.saveFollowingCount(newFollowing);
      } catch (_) {}

      notifyListeners();
    }
  }

  /// Arkadaş sayısını günceller ve hafızaya kaydeder
  void updateFriendsCount(int count) {
    if (_profile != null) {
      _profile = _profile!.copyWith(friendsCount: count);
      
      try {
        final localAuth = GetIt.I<AuthLocalDataSource>();
        localAuth.saveFriendsCount(count);
      } catch (_) {}

      notifyListeners();
    }
  }

  /// Profili günceller (Optimistic UI ile)
  Future<bool> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    bool? shareLocation,
    bool? showProfileToOthers,
    String? instagramUrl,
    String? youtubeUrl,
    String? twitterUrl,
  }) async {
    // 1. Bağlantı kontrolü
    if (!await NetworkService().checkConnection()) {
      _setError('İnternet bağlantısı yok');
      return false;
    }

    // 2. Eski profili sakla (geri dönüş için)
    final oldProfile = _profile;

    // 3. Optimistic Update: UI'yı hemen güncelle
    if (_profile != null) {
      _profile = _profile!.copyWith(
        firstName: firstName ?? _profile!.firstName,
        lastName: lastName ?? _profile!.lastName,
        bio: bio ?? _profile!.bio,
        phoneNumber: phoneNumber ?? _profile!.phoneNumber,
        address: address ?? _profile!.address,
        city: city ?? _profile!.city,
        region: region ?? _profile!.region,
        shareLocation: shareLocation ?? _profile!.shareLocation,
        showProfileToOthers:
            showProfileToOthers ?? _profile!.showProfileToOthers,
        instagramUrl: instagramUrl ?? _profile!.instagramUrl,
        youtubeUrl: youtubeUrl ?? _profile!.youtubeUrl,
        twitterUrl: twitterUrl ?? _profile!.twitterUrl,
      );
      notifyListeners();
    }

    // 4. Backend'e gönder
    try {
      _profile = await _profileRepository.updateProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        region: region,
        shareLocation: shareLocation,
        showProfileToOthers: showProfileToOthers,
        instagramUrl: instagramUrl,
        youtubeUrl: youtubeUrl,
        twitterUrl: twitterUrl,
      );

      // Cache'i güncelle
      try {
        if (_profile != null) {
          final localAuth = GetIt.I<AuthLocalDataSource>();
          await localAuth.saveFirstName(_profile!.firstName);
          await localAuth.saveLastName(_profile!.lastName);
          await localAuth.saveUsername(_profile!.username);
        }
      } catch (_) {
        // Cache hatalarını yoksay
      }

      notifyListeners();
      return true;
    } catch (e) {
      // 5. Hata durumunda geri al
      _profile = oldProfile;
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Profil resmini günceller (Sıkıştırma ile)
  Future<bool> updateProfilePicture(String imagePath) async {
    // 1. Bağlantı kontrolü
    if (!await NetworkService().checkConnection()) {
      _setError('İnternet bağlantısı yok');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      // 2. Resmi sıkıştır
      final compressedPath = await ImageCompressor.compress(
        imagePath: imagePath,
      );
      AppLogger.info('ProfileProvider: Image compressed, uploading...');

      // 3. Yükle
      await _profileRepository.updateProfilePicture(compressedPath);
      await loadProfile(); // Profili yenile
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Kapak resmini günceller
  Future<bool> updateCoverPhoto(String imagePath) async {
    if (!await NetworkService().checkConnection()) {
      _setError('İnternet bağlantısı yok');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final compressedPath = await ImageCompressor.compress(
        imagePath: imagePath,
      );
      await _profileRepository.updateCoverPhoto(compressedPath);
      await loadProfile(forceRefresh: true);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Konumu günceller
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await _profileRepository.updateLocation(latitude, longitude);
      return true;
    } catch (e) {
      AppLogger.warning("Konum güncelleme hatası: $e");
      return false;
    }
  }

  /// Motosikletleri yükler
  Future<void> loadMotorcycles() async {
    _setLoading(true);
    clearError();

    try {
      _motorcycles = await _profileRepository.getMotorcycles();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Motosiklet ekler
  Future<bool> addMotorcycle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final motorcycle = await _profileRepository.addMotorcycle(
        brand: brand,
        model: model,
        year: year,
        licensePlate: licensePlate,
        color: color,
        engineSize: engineSize,
        description: description,
        isPrimary: isPrimary,
      );
      _motorcycles.add(motorcycle);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Motosikleti siler
  Future<bool> deleteMotorcycle(int motorcycleId) async {
    _setLoading(true);
    clearError();

    try {
      await _profileRepository.deleteMotorcycle(motorcycleId);
      _motorcycles.removeWhere((m) => m.id == motorcycleId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Motosikleti günceller
  Future<bool> updateMotorcycle({
    required int motorcycleId,
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final updatedBike = await _profileRepository.updateMotorcycle(
        motorcycleId: motorcycleId,
        brand: brand,
        model: model,
        year: year,
        licensePlate: licensePlate,
        color: color,
        engineSize: engineSize,
        description: description,
        isPrimary: isPrimary,
      );

      // Listeyi güncelle
      final index = _motorcycles.indexWhere((m) => m.id == motorcycleId);
      if (index != -1) {
        _motorcycles[index] = updatedBike;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Ana motosikleti ayarlar
  Future<bool> setPrimaryMotorcycle(int motorcycleId) async {
    try {
      await _profileRepository.setPrimaryMotorcycle(motorcycleId);
      await loadMotorcycles(); // Listeyi yenile
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Profili temizler (logout)
  void clearProfile() {
    _profile = null;
    _visitedProfile = null;
    _motorcycles = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionUserIdSubscription?.cancel();
    super.dispose();
  }

  // Yardımcı metodlar
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceAll("Exception: ", "");
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
