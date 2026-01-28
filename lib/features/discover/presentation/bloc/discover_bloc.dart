import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_users_usecase.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SearchUsersUseCase searchUsers;

  DiscoverBloc({required this.searchUsers}) : super(DiscoverInitial()) {
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<DiscoverState> emit,
  ) async {
    if (event.query.length < 3) {
      emit(const DiscoverFailure("Lütfen en az 3 karakter giriniz."));
      return;
    }

    emit(DiscoverLoading());

    final result = await searchUsers(
      SearchUsersParams(query: event.query, city: event.city),
    );

    result.fold(
      (failure) => emit(DiscoverFailure(failure.message)),
      (results) => emit(DiscoverLoaded(results)),
    );
  }
}
