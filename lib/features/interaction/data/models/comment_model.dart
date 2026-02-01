import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.text,
    required super.userId,
    required super.username,
    super.userAvatar,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // JSON logunda "user" objesi var, onu alıyoruz.
    final userObj = json['user'];

    // Güvenli Map dönüşümü
    final userData = userObj is Map<String, dynamic>
        ? userObj
        : <String, dynamic>{};

    // Helper: Gelen sayı int mi String mi dert etmeden int'e çevirir
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return CommentModel(
      id: toInt(json['id']), // Ana id (Örn: 13)
      text: json['text'] as String? ?? '',

      // --- KRİTİK NOKTA BURASI ---
      // Logda id: 2 olarak user'ın içinde geliyor.
      userId: toInt(userData['id']),

      username: userData['username'] as String? ?? 'Misafir',
      userAvatar: userData['profilePictureUrl'] as String?, // Logda null gelmiş
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}
