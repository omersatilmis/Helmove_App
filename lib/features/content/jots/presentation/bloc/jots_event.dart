import 'package:equatable/equatable.dart';
import '../../domain/entities/jot_entity.dart';

abstract class JotsEvent extends Equatable {
  const JotsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserJotsEvent extends JotsEvent {
  final int userId;
  final bool isRefresh;

  const FetchUserJotsEvent({required this.userId, this.isRefresh = false});

  @override
  List<Object?> get props => [userId, isRefresh];
}

class FetchMoreUserJotsEvent extends JotsEvent {
  final int userId;

  const FetchMoreUserJotsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class CreateJotEvent extends JotsEvent {
  final String text;
  final JotType type;
  final String? mediaUrl;
  final JotVisibility visibility;

  const CreateJotEvent({
    required this.text,
    this.type = JotType.text,
    this.mediaUrl,
    this.visibility = JotVisibility.public,
  });

  @override
  List<Object?> get props => [text, type, mediaUrl, visibility];
}

class DeleteJotEvent extends JotsEvent {
  final int jotId;

  const DeleteJotEvent({required this.jotId});

  @override
  List<Object?> get props => [jotId];
}

class LikeJotEvent extends JotsEvent {
  final int jotId;

  const LikeJotEvent({required this.jotId});

  @override
  List<Object?> get props => [jotId];
}
