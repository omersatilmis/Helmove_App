import 'package:rxdart/rxdart.dart';
import '../../features/auth/domain/entities/auth_entity.dart';

typedef UserEntity = AuthEntity;

class AppSession {
  final BehaviorSubject<int?> _currentUserIdSubject = BehaviorSubject<int?>.seeded(null);
  final BehaviorSubject<UserEntity?> _currentUserSubject =
      BehaviorSubject<UserEntity?>.seeded(null);
  final BehaviorSubject<String?> _tokenSubject =
      BehaviorSubject<String?>.seeded(null);

  int? get currentUserId => _currentUserIdSubject.valueOrNull;
  UserEntity? get currentUser => _currentUserSubject.valueOrNull;
  String? get token => _tokenSubject.valueOrNull;

  Stream<int?> get currentUserIdStream => _currentUserIdSubject.stream;
  Stream<UserEntity?> get currentUserStream => _currentUserSubject.stream;
  Stream<String?> get tokenStream => _tokenSubject.stream;
  Stream<bool> get hasTokenStream =>
      _tokenSubject.stream.map((token) => token != null && token.trim().isNotEmpty).distinct();

  bool get hasValidToken {
    final value = _tokenSubject.valueOrNull;
    return value != null && value.trim().isNotEmpty;
  }

  void updateSession({
    int? currentUserId,
    UserEntity? currentUser,
    String? token,
  }) {
    final resolvedUserId = currentUserId ?? currentUser?.id;
    final resolvedToken = token ?? currentUser?.token;

    _currentUserIdSubject.add(resolvedUserId);
    _currentUserSubject.add(currentUser);
    _tokenSubject.add(resolvedToken);
  }

  void clearSession() {
    _currentUserIdSubject.add(null);
    _currentUserSubject.add(null);
    _tokenSubject.add(null);
  }

  void updateToken(String? token) {
    _tokenSubject.add(token);
  }

  void dispose() {
    _currentUserIdSubject.close();
    _currentUserSubject.close();
    _tokenSubject.close();
  }
}
