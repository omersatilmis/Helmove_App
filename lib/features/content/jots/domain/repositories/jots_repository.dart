import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/jot_entity.dart';
import '../../../../../core/models/conditional_fetch_result.dart';
import '../../../../../core/models/paged_result.dart';

abstract class JotsRepository {
  /// Creates a new jot
  Future<Either<Failure, JotEntity>> createJot({
    required JotType type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    required JotVisibility visibility,
  });

  /// Gets the jot feed with pagination and ETag support
  Future<Either<Failure, ConditionalFetchResult<PagedResult<JotEntity>>>>
  getFeed({int page = 1, int limit = 10, String? ifNoneMatch});

  /// Gets jots for a specific user with pagination
  Future<Either<Failure, PagedResult<JotEntity>>> getUserJots(
    int userId, {
    int page = 1,
    int limit = 10,
  });

  /// Deletes a jot by ID
  Future<Either<Failure, void>> deleteJot(int id);

  /// Likes a jot by ID
  Future<Either<Failure, void>> likeJot(int id);

  /// Unlikes a jot by ID
  Future<Either<Failure, void>> unlikeJot(int id);
}
