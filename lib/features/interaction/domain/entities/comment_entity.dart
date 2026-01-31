import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final int id;
  final String text;
  final int userId;
  final String username;
  final String? userAvatar; // Optional
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.text,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    text,
    userId,
    username,
    userAvatar,
    createdAt,
  ];
}
