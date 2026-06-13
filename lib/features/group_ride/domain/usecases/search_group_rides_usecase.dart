import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_ride_summary.dart';
import '../entities/ride_filters.dart';
import '../repositories/group_ride_repository.dart';

/// Keşfet araması parametreleri. Filtreler enum; usecase apiValue'ya çevirir.
class SearchGroupRidesParams {
  final String? title;
  final String? location;
  final RideDifficulty? difficulty;
  final RideStyle? ridingStyle;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const SearchGroupRidesParams({
    this.title,
    this.location,
    this.difficulty,
    this.ridingStyle,
    this.status,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 20,
  });
}

class SearchGroupRidesUseCase {
  final GroupRideRepository repository;

  SearchGroupRidesUseCase(this.repository);

  Future<Either<Failure, List<GroupRideSummary>>> execute(
    SearchGroupRidesParams params,
  ) async {
    return await repository.searchGroupRides(
      title: params.title,
      location: params.location,
      difficulty: params.difficulty?.apiValue,
      ridingStyle: params.ridingStyle?.apiValue,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
