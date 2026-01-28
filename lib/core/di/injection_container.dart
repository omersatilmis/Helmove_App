import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
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
import '../../features/friendship/data/api/friendship_api.dart';
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
import '../../features/friendship/presentation/bloc/status/friendship_status_bloc.dart';

// Messages Feature
import '../../features/messages/data/datasources/message_remote_data_source.dart';
import '../../features/messages/data/repositories/message_repository_impl.dart';
import '../../features/messages/domain/repositories/message_repository.dart';
import '../../features/messages/domain/usecases/delete_conversation_usecase.dart';
import '../../features/messages/domain/usecases/delete_message_usecase.dart';
import '../../features/messages/domain/usecases/edit_message_usecase.dart';
import '../../features/messages/domain/usecases/get_conversation_messages_usecase.dart';
import '../../features/messages/domain/usecases/get_conversations_usecase.dart';
import '../../features/messages/domain/usecases/get_unread_count_usecase.dart';
import '../../features/messages/domain/usecases/mark_as_read_usecase.dart';
import '../../features/messages/domain/usecases/mark_conversation_as_read_usecase.dart';

import '../../features/messages/domain/usecases/send_message_usecase.dart';
import '../../features/messages/presentation/bloc/conversations/conversations_bloc.dart';
import '../../features/messages/presentation/bloc/chat/chat_bloc.dart';

// Discover Feature
import '../../features/discover/data/api/discover_api.dart';
import '../../features/discover/data/datasources/discover_remote_datasource.dart';
import '../../features/discover/data/repositories/discover_repository_impl.dart';
import '../../features/discover/domain/repositories/discover_repository.dart';
import '../../features/discover/domain/usecases/search_users_usecase.dart';

import '../../features/discover/presentation/bloc/discover_bloc.dart';

// Jots Feature
import '../../features/content/jots/data/api/jots_api.dart';
import '../../features/content/jots/data/datasources/jots_remote_datasource.dart';
import '../../features/content/jots/data/repositories/jots_repository_impl.dart';
import '../../features/content/jots/domain/repositories/jots_repository.dart';
import '../../features/content/jots/domain/usecases/create_jot_usecase.dart';
import '../../features/content/jots/domain/usecases/delete_jot_usecase.dart';
import '../../features/content/jots/domain/usecases/get_feed_usecase.dart';
import '../../features/content/jots/domain/usecases/get_user_jots_usecase.dart';

final sl = GetIt.instance;

/// Logout sırasında çağrılmalı - singleton önbelleklerini temizler
/// Dio ve SharedPreferences hariç tüm singleton'ları resetler
Future<void> resetOnLogout() async {
  // 1. Clear SharedPreferences (User Data)
  try {
    if (sl.isRegistered<SharedPreferences>()) {
      final sharedPreferences = sl<SharedPreferences>();
      await sharedPreferences.clear();
      print("🧹 SharedPreferences cleared.");
    }
  } catch (e) {
    print("⚠️ Error clearing SharedPreferences: $e");
  }

  // 1. Core & Network Resets
  if (sl.isRegistered<Dio>()) {
    sl.unregister<Dio>();
  }

  // 2. Auth Feature Resets
  if (sl.isRegistered<AuthRemoteDataSource>()) {
    sl.unregister<AuthRemoteDataSource>();
  }
  if (sl.isRegistered<AuthLocalDataSource>()) {
    sl.unregister<AuthLocalDataSource>();
  }
  if (sl.isRegistered<AuthRepository>()) {
    sl.unregister<AuthRepository>();
  }
  if (sl.isRegistered<AuthApi>()) {
    sl.unregister<AuthApi>();
  }

  // 3. Friendship Feature Resets
  if (sl.isRegistered<FriendshipRemoteDataSource>()) {
    sl.unregister<FriendshipRemoteDataSource>();
  }
  if (sl.isRegistered<FriendshipRepository>()) {
    sl.unregister<FriendshipRepository>();
  }
  if (sl.isRegistered<FriendshipApi>()) {
    sl.unregister<FriendshipApi>();
  }

  // 4. Profile Feature Resets
  if (sl.isRegistered<ProfileRemoteDataSource>()) {
    sl.unregister<ProfileRemoteDataSource>();
  }
  if (sl.isRegistered<ProfileRepository>()) {
    sl.unregister<ProfileRepository>();
  }
  if (sl.isRegistered<ProfileApi>()) {
    sl.unregister<ProfileApi>();
  }

  // 5. Messages Feature Resets
  if (sl.isRegistered<MessageRemoteDataSource>()) {
    sl.unregister<MessageRemoteDataSource>();
  }
  if (sl.isRegistered<MessageRepository>()) {
    sl.unregister<MessageRepository>();
  }
  // MessageApi yok, direkt DS kullanıyor olabilir.

  // 6. Discover Feature Resets
  if (sl.isRegistered<DiscoverRemoteDataSource>()) {
    sl.unregister<DiscoverRemoteDataSource>();
  }
  if (sl.isRegistered<DiscoverRepository>()) {
    sl.unregister<DiscoverRepository>();
  }
  if (sl.isRegistered<DiscoverApi>()) {
    sl.unregister<DiscoverApi>();
  }

  // 7. Jots Feature Resets
  if (sl.isRegistered<JotsRemoteDataSource>()) {
    sl.unregister<JotsRemoteDataSource>();
  }
  if (sl.isRegistered<JotsRepository>()) {
    sl.unregister<JotsRepository>();
  }
  if (sl.isRegistered<JotsApi>()) {
    sl.unregister<JotsApi>();
  }

  // --- RE-REGISTER ---

  // 1. Re-register Dio
  // SharedPreferences'ı çek (clear'dan sonra hala instance var mı? Var, sadece içi boş.)
  // Ancak unregister edilmediği için sl<SharedPreferences>() hala çalışır.
  final sharedPreferences = sl<SharedPreferences>();

  // Dio'yu yeniden oluştur
  final dio = await NetworkModule.provideDio(sharedPreferences);
  // Unregister Dio yapıldı yukarıda, şimdi register ediyoruz.
  sl.registerLazySingleton(() => dio);

  // 2. Re-register Auth Feature
  if (!sl.isRegistered<AuthApi>()) {
    sl.registerLazySingleton(() => AuthApi(sl()));
  }
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(api: sl()),
    );
  }
  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    );
  }

  // 3. Re-register Other Features
  _registerFeatureSingletons();

  print("🔄 resetOnLogout completed. Dio and Features reset.");
}

void _registerFeatureSingletons() {
  // Profile Feature
  if (!sl.isRegistered<ProfileApi>()) {
    sl.registerLazySingleton(() => ProfileApi(sl()));
  }
  if (!sl.isRegistered<ProfileRemoteDataSource>()) {
    sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(api: sl()),
    );
  }
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()),
    );
  }

  // Friendship Feature
  if (!sl.isRegistered<FriendshipApi>()) {
    sl.registerLazySingleton(() => FriendshipApi(sl()));
  }
  if (!sl.isRegistered<FriendshipRemoteDataSource>()) {
    sl.registerLazySingleton<FriendshipRemoteDataSource>(
      () => FriendshipRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<FriendshipRepository>()) {
    sl.registerLazySingleton<FriendshipRepository>(
      () => FriendshipRepositoryImpl(sl()),
    );
  }

  // Discover Feature
  if (!sl.isRegistered<DiscoverApi>()) {
    sl.registerLazySingleton(() => DiscoverApi(sl()));
  }
  if (!sl.isRegistered<DiscoverRemoteDataSource>()) {
    sl.registerLazySingleton<DiscoverRemoteDataSource>(
      () => DiscoverRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<DiscoverRepository>()) {
    sl.registerLazySingleton<DiscoverRepository>(
      () => DiscoverRepositoryImpl(sl()),
    );
  }

  // Messages Feature
  if (!sl.isRegistered<MessageRemoteDataSource>()) {
    sl.registerLazySingleton<MessageRemoteDataSource>(
      () => MessageRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<MessageRepository>()) {
    sl.registerLazySingleton<MessageRepository>(
      () => MessageRepositoryImpl(sl()),
    );
  }

  // Jots Feature
  if (!sl.isRegistered<JotsApi>()) {
    sl.registerLazySingleton(() => JotsApi(sl()));
  }
  if (!sl.isRegistered<JotsRemoteDataSource>()) {
    sl.registerLazySingleton<JotsRemoteDataSource>(
      () => JotsRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<JotsRepository>()) {
    sl.registerLazySingleton<JotsRepository>(() => JotsRepositoryImpl(sl()));
  }
}

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
  //! Friendship Feature
  // API
  sl.registerLazySingleton(() => FriendshipApi(sl()));

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

  sl.registerFactory(
    () => FriendshipStatusBloc(
      getFriendshipStatus: sl(),
      getSentRequests: sl(),
      getPendingRequests: sl(),
      getMyFriends: sl(),
    ),
  );

  //! Discover Feature
  // API
  sl.registerLazySingleton(() => DiscoverApi(sl()));

  // Data Sources
  sl.registerLazySingleton<DiscoverRemoteDataSource>(
    () => DiscoverRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));

  // Bloc
  sl.registerFactory(() => DiscoverBloc(searchUsers: sl()));

  //! Messages Feature
  // Data Sources
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationMessagesUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkConversationAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMessageUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerLazySingleton(() => EditMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => ConversationsBloc(
      getConversations: sl(),
      deleteConversation: sl(),
      markConversationAsRead: sl(),
      getUnreadCount: sl(),
    ),
  );

  sl.registerFactory(
    () => ChatBloc(
      getMessages: sl(),
      sendMessage: sl(),
      editMessage: sl(),
      deleteMessage: sl(),
    ),
  );

  //! Jots Feature
  // API
  sl.registerLazySingleton(() => JotsApi(sl()));

  // Data Sources
  sl.registerLazySingleton<JotsRemoteDataSource>(
    () => JotsRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<JotsRepository>(() => JotsRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => CreateJotUseCase(sl()));
  sl.registerLazySingleton(() => GetFeedUseCase(sl()));
  sl.registerLazySingleton(() => GetUserJotsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteJotUseCase(sl()));
}
