import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart'; // Unused import removed
import 'package:shared_preferences/shared_preferences.dart';

import '../network/network_module.dart';
import '../../features/auth/data/api/auth_api.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

// Profile Feature
import '../../features/profile/data/api/profile_api.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

// Friendship Feature
import '../../features/friendship/data/datasources/friendship_remote_datasource.dart';
import '../../features/friendship/data/repositories/friendship_repository_impl.dart';
import '../../features/friendship/domain/repositories/friendship_repository.dart';
import '../../features/friendship/domain/usecases/accept_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/block_user_usecase.dart';
import '../../features/friendship/domain/usecases/check_are_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_friendship_stats_usecase.dart';
import '../../features/friendship/domain/usecases/get_friendship_status_usecase.dart';
import '../../features/friendship/domain/usecases/get_mutual_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_my_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_pending_requests_usecase.dart';
import '../../features/friendship/domain/usecases/get_sent_requests_usecase.dart';
import '../../features/friendship/domain/usecases/reject_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/remove_friend_usecase.dart';
import '../../features/friendship/domain/usecases/search_friends_usecase.dart';
import '../../features/friendship/domain/usecases/send_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/unblock_user_usecase.dart';
import '../../features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import '../../features/friendship/presentation/bloc/list/friendship_list_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  final dio = await NetworkModule.provideDio(sharedPreferences);
  sl.registerLazySingleton(() => dio);

  //! Auth Feature
  // API
  sl.registerLazySingleton(() => AuthApi(sl()));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(api: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  //! Profile Feature
  // API
  sl.registerLazySingleton(() => ProfileApi(sl()));

  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(api: sl()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );

  //! Friendship Feature
  // Data Sources
  sl.registerLazySingleton<FriendshipRemoteDataSource>(
    () => FriendshipRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<FriendshipRepository>(
    () => FriendshipRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => SendFriendRequestUseCase(sl()));
  sl.registerLazySingleton(() => AcceptFriendRequestUseCase(sl()));
  sl.registerLazySingleton(() => RejectFriendRequestUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFriendUseCase(sl()));
  sl.registerLazySingleton(() => BlockUserUseCase(sl()));
  sl.registerLazySingleton(() => UnblockUserUseCase(sl()));
  sl.registerLazySingleton(() => GetMyFriendsUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetSentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetFriendshipStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetMutualFriendsUseCase(sl()));
  sl.registerLazySingleton(() => SearchFriendsUseCase(sl()));
  sl.registerLazySingleton(() => CheckAreFriendsUseCase(sl()));
  sl.registerLazySingleton(() => GetFriendshipStatusUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => FriendshipActionBloc(
      sendFriendRequest: sl(),
      acceptFriendRequest: sl(),
      rejectFriendRequest: sl(),
      removeFriend: sl(),
      blockUser: sl(),
      unblockUser: sl(),
    ),
  );

  sl.registerFactory(
    () => FriendshipListBloc(
      getMyFriends: sl(),
      getPendingRequests: sl(),
      getSentRequests: sl(),
      getStats: sl(),
      getMutualFriends: sl(),
      searchFriends: sl(),
    ),
  );
}
