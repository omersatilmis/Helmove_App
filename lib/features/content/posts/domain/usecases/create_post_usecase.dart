import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class CreatePostUseCase implements UseCase<PostEntity, CreatePostParams> {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  @override
  Future<Either<Failure, PostEntity>> call(CreatePostParams params) {
    return repository.createPost(
      type: params.type,
      text: params.text,
      mediaUrl: params.mediaUrl,
      thumbnailUrl: params.thumbnailUrl,
      visibility: params.visibility,
    );
  }
}

class CreatePostParams extends Equatable {
  final int type;
  final String text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int visibility;

  const CreatePostParams({
    required this.type,
    required this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
  });

  @override
  List<Object?> get props => [type, text, mediaUrl, thumbnailUrl, visibility];
}
