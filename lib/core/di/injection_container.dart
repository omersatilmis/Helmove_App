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

import 'package:moto_comm_app_1/features/interaction/data/datasources/comment_remote_datasource.dart';
import 'package:moto_comm_app_1/features/interaction/data/repositories/comment_repository_impl.dart';
import 'package:moto_comm_app_1/features/interaction/domain/repositories/comment_repository.dart';
import 'package:moto_comm_app_1/features/interaction/domain/usecases/add_comment_usecase.dart';
import 'package:moto_comm_app_1/features/interaction/domain/usecases/delete_comment_usecase.dart';
import 'package:moto_comm_app_1/features/interaction/domain/usecases/get_comments_usecase.dart';
import 'package:moto_comm_app_1/features/interaction/presentation/bloc/comments_bloc.dart';

// Jots Feature
import '../../features/content/jots/data/api/jots_api.dart';
import '../../features/content/jots/data/datasources/jots_remote_datasource.dart';
import '../../features/content/jots/data/repositories/jots_repository_impl.dart';
import '../../features/content/jots/domain/repositories/jots_repository.dart';
import '../../features/content/jots/domain/usecases/create_jot_usecase.dart';
import '../../features/content/jots/domain/usecases/delete_jot_usecase.dart';
import '../../features/content/jots/domain/usecases/get_feed_usecase.dart';
import '../../features/content/jots/domain/usecases/get_user_jots_usecase.dart';
import '../../features/content/jots/domain/usecases/like_jot_usecase.dart';
import '../../features/content/jots/presentation/bloc/jots_bloc.dart';

// Posts Feature
import '../../features/content/posts/data/api/post_api.dart';
import '../../features/content/posts/data/datasources/post_remote_datasource.dart';
import '../../features/content/posts/data/repositories/post_repository_impl.dart';
import '../../features/content/posts/domain/repositories/post_repository.dart';
import '../../features/content/posts/domain/usecases/create_post_usecase.dart';
import '../../features/content/posts/domain/usecases/delete_post_usecase.dart';
import '../../features/content/posts/domain/usecases/get_feed_usecase.dart';
import '../../features/content/posts/domain/usecases/get_user_posts_usecase.dart';
import '../../features/content/posts/domain/usecases/like_post_usecase.dart';
import '../../features/content/posts/presentation/bloc/create_post_cubit.dart';
import '../../features/content/posts/presentation/bloc/posts_bloc.dart';

// Media Feature
import '../../features/media/data/api/media_api.dart';
import '../../features/media/data/repositories/media_repository_impl.dart';
import '../../features/media/domain/repositories/media_repository.dart';
import '../../features/media/domain/usecases/upload_image_usecase.dart';

// Notification Feature
import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/domain/usecases/get_notifications_usecase.dart';
import '../../features/notification/domain/usecases/get_unread_count_usecase.dart'
    as notif;
import '../../features/notification/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notification/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notification/presentation/bloc/notifications_bloc.dart';

// Settings Feature
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/update_audio_usecase.dart';
import '../../features/settings/domain/usecases/update_map_usecase.dart';
import '../../features/settings/domain/usecases/update_privacy_usecase.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/domain/usecases/update_units_usecase.dart';

import '../../features/plan/data/datasources/subscription_remote_data_source.dart';
import '../../features/plan/data/repositories/subscription_repository_impl.dart';
import '../../features/plan/domain/repositories/subscription_repository.dart';
import '../../features/plan/domain/usecases/get_plans_usecase.dart';
import '../../features/plan/domain/usecases/subscribe_usecase.dart';
import '../../features/plan/presentation/bloc/subscription_bloc.dart';

final sl = GetIt.instance;

void setup() {
  sl.allowReassignment = true;
}

/// Logout sırasında çağrılmalı - singleton önbelleklerini temizler
/// Dio ve SharedPreferences hariç tüm singleton'ları resetler
Future<void> resetOnLogout() async {
  // 1. CLEAR CACHES FIRST (Before unregistering anything)
  if (sl.isRegistered<FriendshipRepository>()) {
    try {
      sl<FriendshipRepository>().clearCache();
    } catch (e) {
      print("⚠️ Error clearing friendship cache: $e");
    }
  }

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

  // 1.5 No need to re-register Dio or SharedPreferences as they are root singletons
  // that don't hold user-specific state that can't be cleared.
  // The AuthInterceptor already handles the cleared SharedPreferences.

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
  if (sl.isRegistered<FriendshipRepository>()) {
    sl.unregister<FriendshipRepository>();
  }
  if (sl.isRegistered<FriendshipRemoteDataSource>()) {
    sl.unregister<FriendshipRemoteDataSource>();
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

  // 8. Posts Feature Resets
  if (sl.isRegistered<PostRemoteDataSource>()) {
    sl.unregister<PostRemoteDataSource>();
  }
  if (sl.isRegistered<PostRepository>()) {
    sl.unregister<PostRepository>();
  }
  if (sl.isRegistered<PostApi>()) {
    sl.unregister<PostApi>();
  }

  // --- RE-REGISTER ---

  // 1. Re-register Auth Feature
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
  // UseCases
  sl.registerLazySingleton(() => CreateJotUseCase(sl()));
  sl.registerLazySingleton(() => DeleteJotUseCase(sl()));
  sl.registerLazySingleton(() => GetUserJotsUseCase(sl()));
  sl.registerLazySingleton(() => LikeJotUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => JotsBloc(
      getUserJots: sl<GetUserJotsUseCase>(),
      getFeed: sl<GetJotsFeedUseCase>(),
      createJot: sl<CreateJotUseCase>(),
      deleteJot: sl<DeleteJotUseCase>(),
      likeJot: sl<LikeJotUseCase>(),
    ),
  );

  // Posts Feature
  if (!sl.isRegistered<PostApi>()) {
    sl.registerLazySingleton(() => PostApi(sl()));
  }
  if (!sl.isRegistered<PostRemoteDataSource>()) {
    sl.registerLazySingleton<PostRemoteDataSource>(
      () => PostRemoteDataSourceImpl(sl<PostApi>()),
    );
  }
  if (!sl.isRegistered<PostRepository>()) {
    sl.registerLazySingleton<PostRepository>(
      () => PostRepositoryImpl(sl<PostRemoteDataSource>()),
    );
  }

  // Media Feature
  if (!sl.isRegistered<MediaApi>()) {
    sl.registerLazySingleton(() => MediaApi(sl()));
  }
  if (!sl.isRegistered<MediaRepository>()) {
    sl.registerLazySingleton<MediaRepository>(() => MediaRepositoryImpl(sl()));
  }

  // Interaction Feature (Comments)
  if (!sl.isRegistered<CommentRemoteDataSource>()) {
    sl.registerLazySingleton<CommentRemoteDataSource>(
      () => CommentRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<CommentRepository>()) {
    sl.registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(sl<CommentRemoteDataSource>()),
    );
  }
}

Future<void> init() async {
  setup();
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  final dio = await NetworkModule.provideDio(sharedPreferences);
  sl.registerSingleton<Dio>(dio);

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
  sl.registerFactory(() => SendFriendRequestUseCase(sl()));
  sl.registerFactory(() => AcceptFriendRequestUseCase(sl()));
  sl.registerFactory(() => RejectFriendRequestUseCase(sl()));
  sl.registerFactory(() => RemoveFriendUseCase(sl()));
  sl.registerFactory(() => BlockUserUseCase(sl()));
  sl.registerFactory(() => UnblockUserUseCase(sl()));
  sl.registerFactory(() => GetMyFriendsUseCase(sl()));
  sl.registerFactory(() => GetPendingRequestsUseCase(sl()));
  sl.registerFactory(() => GetSentRequestsUseCase(sl()));
  sl.registerFactory(() => GetFriendshipStatsUseCase(sl()));
  sl.registerFactory(() => GetMutualFriendsUseCase(sl()));
  sl.registerFactory(() => SearchFriendsUseCase(sl()));
  sl.registerFactory(() => CheckAreFriendsUseCase(sl()));
  sl.registerFactory(() => GetFriendshipStatusUseCase(sl()));

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

  sl.registerFactory(() => FriendshipStatusBloc(getFriendshipStatus: sl()));

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
  sl.registerFactory(() => SearchUsersUseCase(sl()));

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
  sl.registerFactory(() => SendMessageUseCase(sl()));
  sl.registerFactory(() => GetConversationsUseCase(sl()));
  sl.registerFactory(() => GetConversationMessagesUseCase(sl()));
  sl.registerFactory(() => MarkAsReadUseCase(sl()));
  sl.registerFactory(() => MarkConversationAsReadUseCase(sl()));
  sl.registerFactory(() => DeleteMessageUseCase(sl()));
  sl.registerFactory(() => DeleteConversationUseCase(sl()));
  sl.registerFactory(() => EditMessageUseCase(sl()));
  sl.registerFactory(() => GetUnreadCountUseCase(sl()));

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
      markConversationAsRead: sl(),
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
  sl.registerFactory(() => CreateJotUseCase(sl<JotsRepository>()));
  sl.registerFactory(() => GetJotsFeedUseCase(sl<JotsRepository>()));
  sl.registerFactory(() => GetUserJotsUseCase(sl<JotsRepository>()));
  sl.registerFactory(() => DeleteJotUseCase(sl<JotsRepository>()));
  sl.registerFactory(() => LikeJotUseCase(sl<JotsRepository>()));

  // Blocs
  sl.registerFactory(
    () => JotsBloc(
      getUserJots: sl<GetUserJotsUseCase>(),
      getFeed: sl<GetJotsFeedUseCase>(),
      createJot: sl<CreateJotUseCase>(),
      deleteJot: sl<DeleteJotUseCase>(),
      likeJot: sl<LikeJotUseCase>(),
    ),
  );

  // Posts Feature
  // API
  if (!sl.isRegistered<PostApi>()) {
    sl.registerLazySingleton(() => PostApi(sl()));
  }

  // Data Sources
  if (!sl.isRegistered<PostRemoteDataSource>()) {
    sl.registerLazySingleton<PostRemoteDataSource>(
      () => PostRemoteDataSourceImpl(sl()),
    );
  }

  // Repository
  if (!sl.isRegistered<PostRepository>()) {
    sl.registerLazySingleton<PostRepository>(() => PostRepositoryImpl(sl()));
  }

  // UseCases
  sl.registerFactory(() => CreatePostUseCase(sl()));
  sl.registerFactory(() => GetPostsFeedUseCase(sl()));
  sl.registerFactory(() => GetUserPostsUseCase(sl()));
  sl.registerFactory(() => DeletePostUseCase(sl()));
  sl.registerFactory(() => LikePostUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => PostsBloc(
      getFeed: sl(),
      getUserPosts: sl(),
      deletePost: sl(),
      likePost: sl(),
    ),
  );
  sl.registerFactory(
    () => CreatePostCubit(
      createPost: sl<CreatePostUseCase>(),
      uploadImage: sl<UploadImageUseCase>(),
    ),
  );

  //! Interaction Feature
  // Data Sources
  sl.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(sl<CommentRemoteDataSource>()),
  );

  // UseCases
  sl.registerFactory(() => GetCommentsUseCase(sl<CommentRepository>()));
  sl.registerFactory(() => AddCommentUseCase(sl<CommentRepository>()));
  sl.registerFactory(() => DeleteCommentUseCase(sl<CommentRepository>()));

  // Bloc
  sl.registerFactory(
    () => CommentsBloc(
      getComments: sl<GetCommentsUseCase>(),
      addComment: sl<AddCommentUseCase>(),
      deleteComment: sl<DeleteCommentUseCase>(),
    ),
  );

  //! Media Feature
  // API
  sl.registerLazySingleton(() => MediaApi(sl()));

  // Repository
  sl.registerLazySingleton<MediaRepository>(() => MediaRepositoryImpl(sl()));

  // UseCases
  sl.registerFactory(() => UploadImageUseCase(sl()));

  //! Notification Feature
  // Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(client: sl()),
  );

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  // UseCases
  sl.registerFactory(() => GetNotificationsUseCase(sl()));
  sl.registerFactory(() => notif.GetUnreadCountUseCase(sl()));
  sl.registerFactory(() => MarkNotificationReadUseCase(sl()));
  sl.registerFactory(() => MarkAllNotificationsReadUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => NotificationsBloc(
      getNotifications: sl(),
      getUnreadCount: sl(),
      markNotificationRead: sl(),
      markAllNotificationsRead: sl(),
    ),
  );

  //! Settings Feature
  // Data Sources
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(client: sl()),
  );

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );

  // UseCases
  sl.registerFactory(() => UpdatePrivacyUseCase(sl()));
  sl.registerFactory(() => UpdateUnitsUseCase(sl()));
  sl.registerFactory(() => UpdateMapUseCase(sl()));
  sl.registerFactory(() => UpdateAudioUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => SettingsBloc(
      updatePrivacy: sl(),
      updateUnits: sl(),
      updateMap: sl(),
      updateAudio: sl(),
    ),
  );

  // ! Subscription Feature
  // Data Sources
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSourceImpl(client: sl()),
  );

  // Repository
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(remoteDataSource: sl()),
  );

  // UseCases
  sl.registerFactory(() => GetPlansUseCase(sl()));
  sl.registerFactory(() => SubscribeUseCase(sl()));

  // Bloc
  sl.registerFactory(() => SubscriptionBloc(getPlans: sl(), subscribe: sl()));
}
