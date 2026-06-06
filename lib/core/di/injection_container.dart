import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helmove/l10n/app_localizations_en.dart';

import '../network/network_module.dart';
import '../network/auth_bootstrap_gate.dart';
import '../config/env_config.dart';
import '../../features/auth/data/api/auth_api.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_id_use_case.dart';

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

// Follow Feature
import '../../features/follow/data/data_sources/follow_remote_data_source.dart';
import '../../features/follow/data/repositories/follow_repository_impl.dart';
import '../../features/follow/domain/repositories/follow_repository.dart';
import '../../features/follow/domain/usecases/follow_user_usecase.dart';
import '../../features/follow/domain/usecases/unfollow_user_usecase.dart';
import '../../features/follow/domain/usecases/get_followers_usecase.dart';
import '../../features/follow/domain/usecases/get_following_usecase.dart';
import '../../features/follow/domain/usecases/follow_block_user_usecase.dart';
import '../../features/follow/domain/usecases/follow_unblock_user_usecase.dart';
import '../../features/follow/domain/usecases/get_blocked_users_usecase.dart';
import '../../features/follow/presentation/bloc/action/follow_action_bloc.dart';
import '../../features/follow/presentation/bloc/list/follow_list_bloc.dart';

// Messages Feature
import '../../features/messages/data/datasources/message_remote_data_source.dart';
import '../../features/messages/data/repositories/message_repository_impl.dart';
import '../../features/messages/domain/repositories/message_repository.dart';

// Discover Feature
import '../../features/discover/data/api/discover_api.dart';
import '../../features/discover/data/datasources/discover_remote_datasource.dart';
import '../../features/discover/data/repositories/discover_repository_impl.dart';
import '../../features/discover/domain/repositories/discover_repository.dart';

import 'package:helmove/features/interaction/data/datasources/comment_remote_datasource.dart';
import 'package:helmove/features/interaction/data/repositories/comment_repository_impl.dart';
import 'package:helmove/features/interaction/domain/repositories/comment_repository.dart';

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
import '../../features/content/jots/data/cache/jot_feed_cache.dart';

// Posts Feature
import '../../features/content/posts/data/api/post_api.dart';
import '../../features/content/posts/data/cache/post_feed_cache.dart';
import '../../features/content/posts/data/datasources/post_remote_datasource.dart';
import '../../features/content/posts/data/repositories/post_repository_impl.dart';
import '../../features/content/posts/domain/repositories/post_repository.dart';
import '../../features/content/posts/domain/usecases/get_feed_usecase.dart';
import '../../features/content/posts/domain/usecases/get_user_posts_usecase.dart';
import '../../features/content/posts/domain/usecases/delete_post_usecase.dart';
import '../../features/content/posts/domain/usecases/like_post_usecase.dart';
import '../../features/content/posts/presentation/bloc/posts_bloc.dart';

// Search/Discover Feature UseCases/Bloc
import '../../features/discover/domain/usecases/search_users_usecase.dart';
import '../../features/discover/domain/usecases/get_explore_usecase.dart';
import '../../features/discover/presentation/bloc/discover_bloc.dart';

// Media Feature
import '../../features/media/data/api/media_api.dart';
import '../../features/media/data/repositories/media_repository_impl.dart';
import '../../features/media/domain/repositories/media_repository.dart';

// Notification Feature

// Settings Feature

// Attendance Feature
import 'package:helmove/features/attendance_management/data/api/attendance_api.dart';
import 'package:helmove/features/attendance_management/data/datasources/attendance_remote_data_source.dart';
import 'package:helmove/features/attendance_management/data/repositories/attendance_repository_impl.dart';
import 'package:helmove/features/attendance_management/domain/repositories/attendance_repository.dart';

// Voice Session Feature
import '../../features/voice_session/data/api/voice_session_api.dart';
import '../../features/voice_session/data/datasources/voice_session_remote_data_source.dart';
import '../../features/voice_session/data/repositories/voice_session_repository_impl.dart';
import '../../features/voice_session/domain/repositories/voice_session_repository.dart';
import '../../features/voice_session/domain/usecases/create_voice_session_usecase.dart';
import '../../features/voice_session/domain/usecases/join_voice_session_usecase.dart';
import '../../features/voice_session/domain/usecases/leave_voice_session_usecase.dart';
import '../../features/voice_session/domain/usecases/invite_to_voice_session_usecase.dart';
import '../../features/voice_session/domain/usecases/get_voice_session_details_usecase.dart';
import '../../features/voice_session/domain/usecases/get_my_voice_sessions_usecase.dart';
import '../../features/voice_session/domain/usecases/accept_voice_session_invitation_usecase.dart';

// Help Feature
import '../../features/help/data/api/help_api.dart';
import '../../features/help/data/datasources/help_remote_data_source.dart';
import '../../features/help/data/repositories/help_repository_impl.dart';
import '../../features/help/domain/repositories/help_repository.dart';
import '../../features/help/domain/usecases/create_report_usecase.dart';
import '../../features/help/domain/usecases/send_feedback_usecase.dart'
    as help_feedback;
import '../../features/help/presentation/bloc/help_bloc.dart';
import '../../features/voice_session/domain/usecases/reject_voice_session_invitation_usecase.dart';
import '../../features/voice_session/domain/usecases/end_voice_session_usecase.dart';
import '../../features/voice_session/domain/usecases/kick_user_usecase.dart';
import '../../features/voice_session/domain/usecases/mute_user_usecase.dart';
import '../../features/voice_session/domain/usecases/transfer_host_usecase.dart';
import '../../features/voice_session/domain/usecases/promote_participant_usecase.dart';
import '../../features/voice_session/domain/usecases/demote_participant_usecase.dart';
import '../../features/voice_session/domain/usecases/kick_participant_usecase.dart';
// Status Management Feature
import '../../features/status_management/data/datasources/status_remote_data_source.dart';
import '../../features/status_management/data/repositories/status_repository_impl.dart';
import '../../features/status_management/domain/repositories/status_repository.dart';
import '../../features/status_management/domain/usecases/start_ride_usecase.dart';
import '../../features/status_management/domain/usecases/complete_ride_usecase.dart';
import '../../features/status_management/domain/usecases/cancel_ride_usecase.dart';
import '../../features/status_management/domain/usecases/postpone_ride_usecase.dart';

// Group Ride Feature
import '../../features/group_ride/data/api/group_ride_api.dart';
import '../../features/group_ride/data/datasources/group_ride_remote_data_source.dart';
import '../../features/group_ride/data/repositories/group_ride_repository_impl.dart';
import '../../features/group_ride/domain/repositories/group_ride_repository.dart';
import '../../features/group_ride/domain/usecases/create_group_ride_usecase.dart';
import '../../features/group_ride/domain/usecases/get_active_group_rides_usecase.dart';
import '../../features/group_ride/domain/usecases/get_group_ride_by_id_usecase.dart';
import '../../features/group_ride/domain/usecases/update_group_ride_usecase.dart';
import '../../features/group_ride/domain/usecases/delete_group_ride_usecase.dart';
import '../../features/group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../features/group_ride/presentation/live_ride/live_ride_controller.dart';
import '../../features/attendance_management/domain/usecases/leave_group_ride_usecase.dart';

// Call Feature
// import '../../features/call/data/api/call_api.dart'; // Removed
import '../../features/call/data/datasources/call_remote_data_source.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/domain/usecases/call_usecases.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';

// Notification Feature (data layer + use cases + bloc)
import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/domain/usecases/get_notifications_usecase.dart';
import '../../features/notification/domain/usecases/get_grouped_notifications_usecase.dart';
import '../../features/notification/domain/usecases/get_unread_count_usecase.dart'
    as notif_unread;
import '../../features/notification/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notification/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notification/domain/usecases/mark_group_read_usecase.dart';
import '../../features/notification/domain/usecases/delete_notification_usecase.dart';
import '../../features/notification/domain/usecases/delete_notification_group_usecase.dart';
import '../../features/notification/presentation/bloc/notifications_bloc.dart';

// Settings Feature (data layer + use cases + bloc)
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/update_privacy_usecase.dart';
import '../../features/settings/domain/usecases/update_units_usecase.dart';
import '../../features/settings/domain/usecases/update_map_usecase.dart';
import '../../features/settings/domain/usecases/update_audio_usecase.dart';
import '../../features/settings/domain/usecases/get_audio_settings_usecase.dart';
import '../../features/settings/domain/usecases/update_network_usecase.dart';
import '../../features/settings/domain/usecases/get_network_settings_usecase.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

// Subscription / Plan Feature (data layer + use cases + bloc)
import '../../features/plan/data/datasources/subscription_remote_data_source.dart';
import '../../features/plan/data/repositories/subscription_repository_impl.dart';
import '../../features/plan/domain/repositories/subscription_repository.dart';
import '../../features/plan/domain/usecases/get_plans_usecase.dart';
import '../../features/plan/domain/usecases/subscribe_usecase.dart';
import '../../features/plan/presentation/bloc/subscription_bloc.dart';

// Friendship UseCases + Blocs
import '../../features/friendship/domain/usecases/get_my_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_pending_requests_usecase.dart';
import '../../features/friendship/domain/usecases/get_sent_requests_usecase.dart';
import '../../features/friendship/domain/usecases/get_friendship_stats_usecase.dart';
import '../../features/friendship/domain/usecases/get_mutual_friends_usecase.dart';
import '../../features/friendship/domain/usecases/search_friends_usecase.dart';
import '../../features/friendship/domain/usecases/get_friendship_status_usecase.dart';
import '../../features/friendship/domain/usecases/send_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/accept_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/reject_friend_request_usecase.dart';
import '../../features/friendship/domain/usecases/cancel_sent_request_usecase.dart';
import '../../features/friendship/domain/usecases/remove_friend_usecase.dart';
import '../../features/friendship/domain/usecases/block_user_usecase.dart';
import '../../features/friendship/domain/usecases/unblock_user_usecase.dart';
import '../../features/friendship/presentation/bloc/list/friendship_list_bloc.dart';
import '../../features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import '../../features/friendship/presentation/bloc/status/friendship_status_bloc.dart';

// Messages UseCases + Blocs
import '../../features/messages/domain/usecases/get_conversations_usecase.dart';
import '../../features/messages/domain/usecases/delete_conversation_usecase.dart';
import '../../features/messages/domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../features/messages/domain/usecases/get_unread_count_usecase.dart'
    as msg_unread;
import '../../features/messages/domain/usecases/get_conversation_messages_usecase.dart';
import '../../features/messages/domain/usecases/send_message_usecase.dart';
import '../../features/messages/domain/usecases/edit_message_usecase.dart';
import '../../features/messages/domain/usecases/delete_message_usecase.dart';
import '../../features/messages/presentation/bloc/conversations/conversations_bloc.dart';
import '../../features/messages/presentation/bloc/chat/chat_bloc.dart';

// Interaction (Comments) UseCases + Bloc
import '../../features/interaction/domain/usecases/get_comments_usecase.dart';
import '../../features/interaction/domain/usecases/add_comment_usecase.dart';
import '../../features/interaction/domain/usecases/delete_comment_usecase.dart';
import '../../features/interaction/presentation/bloc/comments_bloc.dart';

// Media UseCases
import '../../features/media/domain/usecases/upload_image_usecase.dart';

// Posts CreatePostCubit
import '../../features/content/posts/domain/usecases/create_post_usecase.dart';
import '../../features/content/posts/presentation/bloc/create_post_cubit.dart';

import '../services/signalr_service.dart';
import '../services/communication_realtime_bus.dart';
import '../../features/presence/services/presence_controller.dart';
import '../services/communication_refresh_coordinator.dart';
import '../services/message_signalr_service.dart';
import '../services/callkit_incoming_service.dart';
import '../services/call_listener_service.dart';
import '../services/notification_service.dart';
import '../services/sos_alert_listener_service.dart';
import '../services/app_session.dart';
import '../services/real_time_service.dart';
import '../services/livekit_api.dart';
import '../services/livekit_room_service.dart';
import '../services/permissions_service.dart';
import '../services/webrtc_service.dart';
import '../services/audio_orchestrator_service.dart';
import '../services/connectivity_watcher_service.dart';
import '../services/home_summary_service.dart';
import '../services/home_bootstrap_service.dart';
import '../services/subscription_service.dart';
import '../../features/voice_session/presentation/bloc/voice_session_bloc.dart';

import 'package:helmove/features/intercom/domain/intercom_engine.dart';
import 'package:helmove/features/intercom/data/intercom_engine_impl.dart';
// Map Feature
import '../../features/map/data/datasources/map_remote_data_source.dart';
import '../../features/map/data/repositories/map_repository_impl.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../features/map/domain/usecases/get_route_usecase.dart';
import '../../features/map/domain/usecases/search_location_usecase.dart';
import '../../features/map/domain/usecases/search_location_suggestions_usecase.dart';
import '../../features/map/domain/usecases/reverse_geocode_usecase.dart';
import '../../features/map/presentation/providers/map_bloc.dart';
import '../../features/map/config/mapbox_config.dart';

import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/language_provider.dart';

// Ride History Feature
import '../../features/ride_history/data/api/rides_api.dart';
import '../../features/ride_history/data/repositories/ride_repository_impl.dart';
import '../../features/ride_history/data/services/ride_recording_service_impl.dart';
import '../../features/ride_history/domain/repositories/ride_repository.dart';
import '../../features/ride_history/domain/services/ride_recording_service.dart';
import '../../features/ride_history/presentation/providers/ride_history_provider.dart';

final sl = GetIt.instance;
bool _coreInitialized = false;
Completer<void>? _coreInitCompleter;
bool _deferredFeaturesInitialized = false;
Completer<void>? _deferredFeaturesInitCompleter;
bool _communicationRuntimeStarted = false;
Completer<void>? _communicationRuntimeStartCompleter;

void _logInitProfile(String phase, Stopwatch stopwatch) {
  if (kReleaseMode) {
    return;
  }
  debugPrint('[DI][PROFILE] $phase ${stopwatch.elapsedMilliseconds}ms');
  stopwatch
    ..reset()
    ..start();
}

Future<void> initDeferredFeatures() async {
  if (_deferredFeaturesInitialized) {
    return;
  }
  if (_deferredFeaturesInitCompleter != null) {
    return _deferredFeaturesInitCompleter!.future;
  }

  final completer = Completer<void>();
  _deferredFeaturesInitCompleter = completer;
  try {
    final stopwatch = Stopwatch()..start();
    _registerFeatureSingletons();
    _logInitProfile('registerFeatureSingletons(deferred)', stopwatch);
    _registerDeferredRuntimeSingletons();
    _logInitProfile('registerDeferredRuntimeSingletons', stopwatch);
    _deferredFeaturesInitialized = true;
    completer.complete();
  } catch (e, st) {
    completer.completeError(e, st);
    rethrow;
  } finally {
    _deferredFeaturesInitCompleter = null;
  }
}

Future<void> ensureCommunicationRuntimeStarted() async {
  await initDeferredFeatures();

  if (_communicationRuntimeStarted) {
    return;
  }
  if (_communicationRuntimeStartCompleter != null) {
    return _communicationRuntimeStartCompleter!.future;
  }

  final completer = Completer<void>();
  _communicationRuntimeStartCompleter = completer;
  try {
    sl<RealTimeService>().start();
    sl<CallListenerService>().start();
    sl<SosAlertListenerService>().start();
    await sl<IntercomEngine>().start();
    // Presence: SignalR baÄŸlantÄ±sÄ± kurulunca heartbeat'i baÅŸlat.
    sl<PresenceController>().initialize();
    _communicationRuntimeStarted = true;
    completer.complete();
  } catch (e, st) {
    completer.completeError(e, st);
    rethrow;
  } finally {
    _communicationRuntimeStartCompleter = null;
  }
}

Future<void> _handleAuthInvalidationFromInterceptor() async {
  try {
    if (sl.isRegistered<AppSession>()) {
      sl<AppSession>().clearSession();
    }
  } catch (e) {
    debugPrint("âš ï¸ Auth invalidation handler error: $e");
  }
}

Future<void> _handleTokenRefreshedFromInterceptor(String token) async {
  try {
    if (sl.isRegistered<AppSession>()) {
      sl<AppSession>().updateToken(token);
    }
  } catch (e) {
    debugPrint("âš ï¸ Token refresh handler error: $e");
  }
}

void setup() {
  sl.allowReassignment = true;
}

/// Logout sÄ±rasÄ±nda Ã§aÄŸrÄ±lmalÄ± - singleton Ã¶nbelleklerini temizler
/// Dio ve SharedPreferences hariÃ§ tÃ¼m singleton'larÄ± resetler
Future<void> resetOnLogout() async {
  if (sl.isRegistered<AppSession>()) {
    sl<AppSession>().clearSession();
  }

  // 1. CLEAR CACHES FIRST (Before unregistering anything)
  if (sl.isRegistered<FriendshipRepository>()) {
    try {
      sl<FriendshipRepository>().clearCache();
    } catch (e) {
      debugPrint("âš ï¸ Error clearing friendship cache: $e");
    }
  }

  // 1. Clear SharedPreferences (User Data)
  try {
    if (sl.isRegistered<SharedPreferences>()) {
      final sharedPreferences = sl<SharedPreferences>();
      await sharedPreferences.clear();
      debugPrint("ğŸ§¹ SharedPreferences cleared.");
    }
  } catch (e) {
    debugPrint("âš ï¸ Error clearing SharedPreferences: $e");
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

  // Follow Feature Resets
  if (sl.isRegistered<FollowRemoteDataSource>()) {
    sl.unregister<FollowRemoteDataSource>();
  }
  if (sl.isRegistered<FollowRepository>()) {
    sl.unregister<FollowRepository>();
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
  // MessageApi yok, direkt DS kullanÄ±yor olabilir.

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

  // 9. Attendance Feature Resets
  if (sl.isRegistered<AttendanceRemoteDataSource>()) {
    sl.unregister<AttendanceRemoteDataSource>();
  }
  if (sl.isRegistered<AttendanceRepository>()) {
    sl.unregister<AttendanceRepository>();
  }
  if (sl.isRegistered<AttendanceApi>()) {
    sl.unregister<AttendanceApi>();
  }

  // 10. Voice Session Feature Resets
  if (sl.isRegistered<VoiceSessionRemoteDataSource>()) {
    sl.unregister<VoiceSessionRemoteDataSource>();
  }
  if (sl.isRegistered<VoiceSessionRepository>()) {
    sl.unregister<VoiceSessionRepository>();
  }
  if (sl.isRegistered<VoiceSessionApi>()) {
    sl.unregister<VoiceSessionApi>();
  }

  // --- RE-REGISTER ---
  // Auth + Profile + Friendship + VoiceSession + Discover + Messages + Jots vb.
  _registerFeatureSingletons();

  debugPrint("ğŸ”„ resetOnLogout completed. Dio and Features reset.");
}

void _registerCoreFeatureSingletons() {
  // Attendance Feature (Core dependency for GroupRideBloc)
  if (!sl.isRegistered<AttendanceApi>()) {
    sl.registerLazySingleton(() => AttendanceApi(sl()));
  }
  if (!sl.isRegistered<AttendanceRemoteDataSource>()) {
    sl.registerLazySingleton<AttendanceRemoteDataSource>(
      () => AttendanceRemoteDataSourceImpl(sl<AttendanceApi>()),
    );
  }
  if (!sl.isRegistered<AttendanceRepository>()) {
    sl.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(sl()),
    );
  }


  // Auth Feature (AuthApi, AuthRemoteDataSource, AuthRepository)
  if (!sl.isRegistered<AuthApi>()) {
    sl.registerLazySingleton(() => AuthApi(sl()));
  }
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(api: sl()),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    );
  }
  if (!sl.isRegistered<GetCurrentUserIdUseCase>()) {
    sl.registerLazySingleton(
      () => GetCurrentUserIdUseCase(appSession: sl(), authRepository: sl()),
    );
  }

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

  // Ride History Feature
  if (!sl.isRegistered<RidesApi>()) {
    sl.registerLazySingleton(() => RidesApi(sl()));
  }
  if (!sl.isRegistered<RideRepository>()) {
    sl.registerLazySingleton<RideRepository>(
      () => RideRepositoryImpl(sl()),
    );
  }
  if (!sl.isRegistered<RideRecordingService>()) {
    sl.registerLazySingleton<RideRecordingService>(
      () => RideRecordingServiceImpl(
        reverseGeocode: sl.isRegistered<ReverseGeocodeUseCase>()
            ? sl<ReverseGeocodeUseCase>()
            : null,
      ),
    );
  }
  if (!sl.isRegistered<RideHistoryProvider>()) {
    sl.registerLazySingleton(() => RideHistoryProvider(sl()));
  }

  // Messages core path (only unread count path for startup badge fallback)
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
  if (!sl.isRegistered<msg_unread.GetUnreadCountUseCase>()) {
    sl.registerLazySingleton(() => msg_unread.GetUnreadCountUseCase(sl()));
  }

  // Posts Feature (home feed)
  if (!sl.isRegistered<PostFeedCache>()) {
    sl.registerLazySingleton(() => PostFeedCache(sl<SharedPreferences>()));
  }
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
  if (!sl.isRegistered<GetPostsFeedUseCase>()) {
    sl.registerFactory(() => GetPostsFeedUseCase(sl()));
  }
  if (!sl.isRegistered<GetUserPostsUseCase>()) {
    sl.registerFactory(() => GetUserPostsUseCase(sl()));
  }
  if (!sl.isRegistered<DeletePostUseCase>()) {
    sl.registerFactory(() => DeletePostUseCase(sl()));
  }
  if (!sl.isRegistered<LikePostUseCase>()) {
    sl.registerFactory(() => LikePostUseCase(sl()));
  }
  if (!sl.isRegistered<PostsBloc>()) {
    sl.registerLazySingleton(
      () => PostsBloc(
        getFeed: sl<GetPostsFeedUseCase>(),
        getUserPosts: sl<GetUserPostsUseCase>(),
        deletePost: sl<DeletePostUseCase>(),
        likePost: sl<LikePostUseCase>(),
        getCurrentUserIdUseCase: sl<GetCurrentUserIdUseCase>(),
        appSession: sl<AppSession>(),
        postFeedCache: sl<PostFeedCache>(),
      ),
    );
  }

  // Notification unread count fallback for home top bar
  if (!sl.isRegistered<NotificationRemoteDataSource>()) {
    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<NotificationRepository>()) {
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<notif_unread.GetUnreadCountUseCase>()) {
    sl.registerLazySingleton(() => notif_unread.GetUnreadCountUseCase(sl()));
  }

  // Settings Feature
  // Must be available from app start because Drawer > Settings can be opened
  // before deferred feature initialization is triggered.
  if (!sl.isRegistered<SettingsRemoteDataSource>()) {
    sl.registerLazySingleton<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () =>
          SettingsRepositoryImpl(remoteDataSource: sl(), intercomEngine: sl()),
    );
  }
  if (!sl.isRegistered<UpdatePrivacyUseCase>()) {
    sl.registerLazySingleton(() => UpdatePrivacyUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateUnitsUseCase>()) {
    sl.registerLazySingleton(() => UpdateUnitsUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateMapUseCase>()) {
    sl.registerLazySingleton(() => UpdateMapUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateAudioUseCase>()) {
    sl.registerLazySingleton(() => UpdateAudioUseCase(sl()));
  }
  if (!sl.isRegistered<GetAudioSettingsUseCase>()) {
    sl.registerLazySingleton(() => GetAudioSettingsUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateNetworkUseCase>()) {
    sl.registerLazySingleton(() => UpdateNetworkUseCase(sl()));
  }
  if (!sl.isRegistered<GetNetworkSettingsUseCase>()) {
    sl.registerLazySingleton(() => GetNetworkSettingsUseCase(sl()));
  }
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory(
      () => SettingsBloc(
        updatePrivacy: sl(),
        updateUnits: sl(),
        updateMap: sl(),
        getAudioSettings: sl(),
        updateAudio: sl(),
        getNetworkSettings: sl(),
        updateNetwork: sl(),
      ),
    );
  }

  // Map Feature
  const mapboxDioName = 'mapboxDio';

  if (!sl.isRegistered<Dio>(instanceName: mapboxDioName)) {
    sl.registerLazySingleton<Dio>(instanceName: mapboxDioName, () {
      final dio = Dio(
        BaseOptions(
          baseUrl: MapboxConfig.baseUrl,
          connectTimeout: EnvConfig.connectTimeout,
          receiveTimeout: EnvConfig.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          queryParameters: {'access_token': MapboxConfig.accessToken},
        ),
      );

      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );

      return dio;
    });
  }

  if (!sl.isRegistered<MapRemoteDataSource>()) {
    sl.registerLazySingleton<MapRemoteDataSource>(
      () => MapRemoteDataSourceImpl(dio: sl<Dio>(instanceName: mapboxDioName)),
    );
  }
  if (!sl.isRegistered<MapRepository>()) {
    sl.registerLazySingleton<MapRepository>(
      () => MapRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<SearchLocationUseCase>()) {
    sl.registerLazySingleton(() => SearchLocationUseCase(sl()));
  }
  if (!sl.isRegistered<SearchLocationSuggestionsUseCase>()) {
    sl.registerLazySingleton(() => SearchLocationSuggestionsUseCase(sl()));
  }
  if (!sl.isRegistered<GetRouteUseCase>()) {
    sl.registerLazySingleton(() => GetRouteUseCase(sl()));
  }
  if (!sl.isRegistered<ReverseGeocodeUseCase>()) {
    sl.registerLazySingleton(() => ReverseGeocodeUseCase(sl()));
  }
  if (!sl.isRegistered<MapBloc>()) {
    sl.registerFactory(
      () => MapBloc(
        searchLocation: sl(),
        searchSuggestions: sl(),
        getRoute: sl(),
        reverseGeocode: sl(),
        recordingService: sl(),
        rideRepository: sl(),
      ),
    );
  }
}

void _registerFeatureSingletons() {
  // Guard: resetOnLogout can unregister auth local dependencies while core
  // init flags remain true. Re-register here to keep lazy feature factories safe.
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }
  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        sharedPreferences: sl(),
        secureStorage: sl(),
      ),
    );
  }

  // Auth Feature (AuthApi, AuthRemoteDataSource, AuthRepository)
  if (!sl.isRegistered<AuthApi>()) {
    sl.registerLazySingleton(() => AuthApi(sl()));
  }
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(api: sl()),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    );
  }
  if (!sl.isRegistered<GetCurrentUserIdUseCase>()) {
    sl.registerLazySingleton(
      () => GetCurrentUserIdUseCase(appSession: sl(), authRepository: sl()),
    );
  }

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

  // Follow Feature
  if (!sl.isRegistered<FollowRemoteDataSource>()) {
    sl.registerLazySingleton<FollowRemoteDataSource>(
      () => FollowRemoteDataSourceImpl(dio: sl()),
    );
  }
  if (!sl.isRegistered<FollowRepository>()) {
    sl.registerLazySingleton<FollowRepository>(
      () => FollowRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Follow UseCases
  if (!sl.isRegistered<FollowUserUseCase>()) {
    sl.registerLazySingleton(() => FollowUserUseCase(sl()));
  }
  if (!sl.isRegistered<UnfollowUserUseCase>()) {
    sl.registerLazySingleton(() => UnfollowUserUseCase(sl()));
  }
  if (!sl.isRegistered<FollowBlockUserUseCase>()) {
    sl.registerLazySingleton(() => FollowBlockUserUseCase(sl()));
  }
  if (!sl.isRegistered<FollowUnblockUserUseCase>()) {
    sl.registerLazySingleton(() => FollowUnblockUserUseCase(sl()));
  }
  if (!sl.isRegistered<GetFollowersUseCase>()) {
    sl.registerLazySingleton(() => GetFollowersUseCase(sl()));
  }
  if (!sl.isRegistered<GetFollowingUseCase>()) {
    sl.registerLazySingleton(() => GetFollowingUseCase(sl()));
  }
  if (!sl.isRegistered<GetBlockedUsersUseCase>()) {
    sl.registerLazySingleton(() => GetBlockedUsersUseCase(sl()));
  }

  // Follow Bloc
  if (!sl.isRegistered<FollowActionBloc>()) {
    sl.registerFactory(
      () => FollowActionBloc(
        followUserUseCase: sl(),
        unfollowUserUseCase: sl(),
        blockUserUseCase: sl(),
        unblockUserUseCase: sl(),
      ),
    );
  }
  if (!sl.isRegistered<FollowersListBloc>()) {
    sl.registerFactory(() => FollowersListBloc(getFollowersUseCase: sl()));
  }
  if (!sl.isRegistered<FollowingListBloc>()) {
    sl.registerFactory(() => FollowingListBloc(getFollowingUseCase: sl()));
  }
  if (!sl.isRegistered<BlockedListBloc>()) {
    sl.registerFactory(() => BlockedListBloc(getBlockedUsersUseCase: sl()));
  }

  // Voice Session Feature
  if (!sl.isRegistered<VoiceSessionApi>()) {
    sl.registerLazySingleton(() => VoiceSessionApi(sl()));
  }
  if (!sl.isRegistered<VoiceSessionRemoteDataSource>()) {
    sl.registerLazySingleton<VoiceSessionRemoteDataSource>(
      () => VoiceSessionRemoteDataSourceImpl(sl<VoiceSessionApi>()),
    );
  }
  if (!sl.isRegistered<VoiceSessionRepository>()) {
    sl.registerLazySingleton<VoiceSessionRepository>(
      () => VoiceSessionRepositoryImpl(sl()),
    );
  }

  // Help Feature
  if (!sl.isRegistered<HelpApi>()) {
    sl.registerLazySingleton(() => HelpApi(sl()));
  }
  if (!sl.isRegistered<HelpRemoteDataSource>()) {
    sl.registerLazySingleton<HelpRemoteDataSource>(
      () => HelpRemoteDataSourceImpl(api: sl()),
    );
  }
  if (!sl.isRegistered<HelpRepository>()) {
    sl.registerLazySingleton<HelpRepository>(
      () => HelpRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<CreateReportUseCase>()) {
    sl.registerLazySingleton(() => CreateReportUseCase(sl()));
  }
  if (!sl.isRegistered<help_feedback.SendFeedbackUseCase>()) {
    sl.registerLazySingleton(() => help_feedback.SendFeedbackUseCase(sl()));
  }

  // Help Feature Bloc
  if (!sl.isRegistered<HelpBloc>()) {
    sl.registerFactory(
      () => HelpBloc(
        createReportUseCase: sl(),
        sendFeedbackUseCase: sl<help_feedback.SendFeedbackUseCase>(),
      ),
    );
  }
  // Voice Session UseCases
  if (!sl.isRegistered<CreateVoiceSessionUseCase>()) {
    sl.registerLazySingleton(() => CreateVoiceSessionUseCase(sl()));
  }
  if (!sl.isRegistered<JoinVoiceSessionUseCase>()) {
    sl.registerLazySingleton(() => JoinVoiceSessionUseCase(sl()));
  }
  if (!sl.isRegistered<LeaveVoiceSessionUseCase>()) {
    sl.registerLazySingleton(() => LeaveVoiceSessionUseCase(sl()));
  }
  if (!sl.isRegistered<InviteToVoiceSessionUseCase>()) {
    sl.registerLazySingleton(() => InviteToVoiceSessionUseCase(sl()));
  }
  if (!sl.isRegistered<GetVoiceSessionDetailsUseCase>()) {
    sl.registerLazySingleton(() => GetVoiceSessionDetailsUseCase(sl()));
  }
  if (!sl.isRegistered<GetMyVoiceSessionsUseCase>()) {
    sl.registerLazySingleton(() => GetMyVoiceSessionsUseCase(sl()));
  }
  if (!sl.isRegistered<AcceptVoiceSessionInvitationUseCase>()) {
    sl.registerLazySingleton(() => AcceptVoiceSessionInvitationUseCase(sl()));
  }
  if (!sl.isRegistered<RejectVoiceSessionInvitationUseCase>()) {
    sl.registerLazySingleton(() => RejectVoiceSessionInvitationUseCase(sl()));
  }
  if (!sl.isRegistered<EndVoiceSessionUseCase>()) {
    sl.registerLazySingleton(() => EndVoiceSessionUseCase(sl()));
  }
  if (!sl.isRegistered<KickUserUseCase>()) {
    sl.registerLazySingleton(() => KickUserUseCase(sl()));
  }
  if (!sl.isRegistered<MuteUserUseCase>()) {
    sl.registerLazySingleton(() => MuteUserUseCase(sl()));
  }
  if (!sl.isRegistered<TransferHostUseCase>()) {
    sl.registerLazySingleton(() => TransferHostUseCase(sl()));
  }
  if (!sl.isRegistered<PromoteParticipantUseCase>()) {
    sl.registerLazySingleton(() => PromoteParticipantUseCase(sl()));
  }
  if (!sl.isRegistered<DemoteParticipantUseCase>()) {
    sl.registerLazySingleton(() => DemoteParticipantUseCase(sl()));
  }
  if (!sl.isRegistered<KickParticipantUseCase>()) {
    sl.registerLazySingleton(() => KickParticipantUseCase(sl()));
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
  if (!sl.isRegistered<CreateJotUseCase>()) {
    sl.registerLazySingleton(() => CreateJotUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteJotUseCase>()) {
    sl.registerLazySingleton(() => DeleteJotUseCase(sl()));
  }
  if (!sl.isRegistered<GetUserJotsUseCase>()) {
    sl.registerLazySingleton(() => GetUserJotsUseCase(sl()));
  }
  if (!sl.isRegistered<LikeJotUseCase>()) {
    sl.registerLazySingleton(() => LikeJotUseCase(sl()));
  }
  if (!sl.isRegistered<GetJotsFeedUseCase>()) {
    sl.registerLazySingleton(() => GetJotsFeedUseCase(sl()));
  }

  if (!sl.isRegistered<JotFeedCache>()) {
    sl.registerLazySingleton(() => JotFeedCache(sl<SharedPreferences>()));
  }

  // Bloc
  if (!sl.isRegistered<JotsBloc>()) {
    sl.registerFactory(
      () => JotsBloc(
        getUserJots: sl<GetUserJotsUseCase>(),
        getFeed: sl<GetJotsFeedUseCase>(),
        createJot: sl<CreateJotUseCase>(),
        deleteJot: sl<DeleteJotUseCase>(),
        likeJot: sl<LikeJotUseCase>(),
        jotFeedCache: sl<JotFeedCache>(),
        uploadImage: sl<UploadImageUseCase>(),
        appSession: sl<AppSession>(),
        getCurrentUserIdUseCase: sl<GetCurrentUserIdUseCase>(),
      ),
    );
  }

  // Posts Feature
  if (!sl.isRegistered<PostFeedCache>()) {
    sl.registerLazySingleton(() => PostFeedCache(sl<SharedPreferences>()));
  }
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

  // UseCases
  if (!sl.isRegistered<GetPostsFeedUseCase>()) {
    sl.registerFactory(() => GetPostsFeedUseCase(sl()));
  }
  if (!sl.isRegistered<GetUserPostsUseCase>()) {
    sl.registerFactory(() => GetUserPostsUseCase(sl()));
  }
  if (!sl.isRegistered<DeletePostUseCase>()) {
    sl.registerFactory(() => DeletePostUseCase(sl()));
  }
  if (!sl.isRegistered<LikePostUseCase>()) {
    sl.registerFactory(() => LikePostUseCase(sl()));
  }

  // Bloc
  if (!sl.isRegistered<PostsBloc>()) {
    sl.registerLazySingleton(
      () => PostsBloc(
        getFeed: sl<GetPostsFeedUseCase>(),
        getUserPosts: sl<GetUserPostsUseCase>(),
        deletePost: sl<DeletePostUseCase>(),
        likePost: sl<LikePostUseCase>(),
        getCurrentUserIdUseCase: sl<GetCurrentUserIdUseCase>(),
        appSession: sl<AppSession>(),
        postFeedCache: sl<PostFeedCache>(),
      ),
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

  // UseCases
  if (!sl.isRegistered<SearchUsersUseCase>()) {
    sl.registerFactory(() => SearchUsersUseCase(sl()));
  }
  if (!sl.isRegistered<GetExploreUseCase>()) {
    sl.registerFactory(() => GetExploreUseCase(sl()));
  }

  // Bloc
  if (!sl.isRegistered<DiscoverBloc>()) {
    sl.registerFactory(
      () => DiscoverBloc(
        searchUsers: sl<SearchUsersUseCase>(),
        getExplore: sl<GetExploreUseCase>(),
        likePost: sl<LikePostUseCase>(),
      ),
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

  // Attendance Feature
  if (!sl.isRegistered<AttendanceApi>()) {
    sl.registerLazySingleton(() => AttendanceApi(sl()));
  }
  if (!sl.isRegistered<AttendanceRemoteDataSource>()) {
    sl.registerLazySingleton<AttendanceRemoteDataSource>(
      () => AttendanceRemoteDataSourceImpl(sl<AttendanceApi>()),
    );
  }
  if (!sl.isRegistered<AttendanceRepository>()) {
    sl.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(sl()),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Notification Feature (data layer + use cases + bloc)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<NotificationRemoteDataSource>()) {
    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<NotificationRepository>()) {
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<GetNotificationsUseCase>()) {
    sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  }
  if (!sl.isRegistered<GetGroupedNotificationsUseCase>()) {
    sl.registerLazySingleton(() => GetGroupedNotificationsUseCase(sl()));
  }
  if (!sl.isRegistered<notif_unread.GetUnreadCountUseCase>()) {
    sl.registerLazySingleton(() => notif_unread.GetUnreadCountUseCase(sl()));
  }
  if (!sl.isRegistered<MarkNotificationReadUseCase>()) {
    sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  }
  if (!sl.isRegistered<MarkAllNotificationsReadUseCase>()) {
    sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  }
  if (!sl.isRegistered<MarkGroupReadUseCase>()) {
    sl.registerLazySingleton(() => MarkGroupReadUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteNotificationUseCase>()) {
    sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteNotificationGroupUseCase>()) {
    sl.registerLazySingleton(() => DeleteNotificationGroupUseCase(sl()));
  }
  if (!sl.isRegistered<NotificationsBloc>()) {
    sl.registerFactory(
      () => NotificationsBloc(
        getNotifications: sl(),
        getGroupedNotifications: sl(),
        getUnreadCount: sl(),
        markNotificationRead: sl(),
        markAllNotificationsRead: sl(),
        markGroupRead: sl(),
        deleteNotification: sl(),
        deleteNotificationGroup: sl(),
        signalRService: sl(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Settings Feature (data layer + use cases + bloc)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<SettingsRemoteDataSource>()) {
    sl.registerLazySingleton<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () =>
          SettingsRepositoryImpl(remoteDataSource: sl(), intercomEngine: sl()),
    );
  }
  if (!sl.isRegistered<UpdatePrivacyUseCase>()) {
    sl.registerLazySingleton(() => UpdatePrivacyUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateUnitsUseCase>()) {
    sl.registerLazySingleton(() => UpdateUnitsUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateMapUseCase>()) {
    sl.registerLazySingleton(() => UpdateMapUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateAudioUseCase>()) {
    sl.registerLazySingleton(() => UpdateAudioUseCase(sl()));
  }
  if (!sl.isRegistered<GetAudioSettingsUseCase>()) {
    sl.registerLazySingleton(() => GetAudioSettingsUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateNetworkUseCase>()) {
    sl.registerLazySingleton(() => UpdateNetworkUseCase(sl()));
  }
  if (!sl.isRegistered<GetNetworkSettingsUseCase>()) {
    sl.registerLazySingleton(() => GetNetworkSettingsUseCase(sl()));
  }
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory(
      () => SettingsBloc(
        updatePrivacy: sl(),
        updateUnits: sl(),
        updateMap: sl(),
        getAudioSettings: sl(),
        updateAudio: sl(),
        getNetworkSettings: sl(),
        updateNetwork: sl(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Subscription / Plan Feature (data layer + use cases + bloc)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<SubscriptionRemoteDataSource>()) {
    sl.registerLazySingleton<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<SubscriptionRepository>()) {
    sl.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(remoteDataSource: sl()),
    );
  }
  if (!sl.isRegistered<GetPlansUseCase>()) {
    sl.registerLazySingleton(() => GetPlansUseCase(sl()));
  }
  if (!sl.isRegistered<SubscribeUseCase>()) {
    sl.registerLazySingleton(() => SubscribeUseCase(sl()));
  }
  if (!sl.isRegistered<SubscriptionBloc>()) {
    sl.registerFactory(
      () => SubscriptionBloc(
        getPlans: sl(),
        subscribe: sl(),
        subscriptionService: sl(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Friendship UseCases + Blocs
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // List Bloc use cases
  if (!sl.isRegistered<GetMyFriendsUseCase>()) {
    sl.registerLazySingleton(() => GetMyFriendsUseCase(sl()));
  }
  if (!sl.isRegistered<GetFriendsUseCase>()) {
    sl.registerLazySingleton(() => GetFriendsUseCase(sl()));
  }
  if (!sl.isRegistered<GetPendingRequestsUseCase>()) {
    sl.registerLazySingleton(() => GetPendingRequestsUseCase(sl()));
  }
  if (!sl.isRegistered<GetSentRequestsUseCase>()) {
    sl.registerLazySingleton(() => GetSentRequestsUseCase(sl()));
  }
  if (!sl.isRegistered<GetFriendshipStatsUseCase>()) {
    sl.registerLazySingleton(() => GetFriendshipStatsUseCase(sl()));
  }
  if (!sl.isRegistered<GetMutualFriendsUseCase>()) {
    sl.registerLazySingleton(() => GetMutualFriendsUseCase(sl()));
  }
  if (!sl.isRegistered<SearchFriendsUseCase>()) {
    sl.registerLazySingleton(() => SearchFriendsUseCase(sl()));
  }
  if (!sl.isRegistered<FriendshipListBloc>()) {
    sl.registerFactory(
      () => FriendshipListBloc(
        getMyFriends: sl(),
        getFriends: sl(),
        getPendingRequests: sl(),
        getSentRequests: sl(),
        getStats: sl(),
        getMutualFriends: sl(),
        searchFriends: sl(),
      ),
    );
  }
  // Action Bloc use cases
  if (!sl.isRegistered<SendFriendRequestUseCase>()) {
    sl.registerLazySingleton(() => SendFriendRequestUseCase(sl()));
  }
  if (!sl.isRegistered<AcceptFriendRequestUseCase>()) {
    sl.registerLazySingleton(() => AcceptFriendRequestUseCase(sl()));
  }
  if (!sl.isRegistered<RejectFriendRequestUseCase>()) {
    sl.registerLazySingleton(() => RejectFriendRequestUseCase(sl()));
  }
  if (!sl.isRegistered<CancelSentRequestUseCase>()) {
    sl.registerLazySingleton(() => CancelSentRequestUseCase(sl()));
  }
  if (!sl.isRegistered<RemoveFriendUseCase>()) {
    sl.registerLazySingleton(() => RemoveFriendUseCase(sl()));
  }
  if (!sl.isRegistered<BlockUserUseCase>()) {
    sl.registerLazySingleton(() => BlockUserUseCase(sl()));
  }
  if (!sl.isRegistered<UnblockUserUseCase>()) {
    sl.registerLazySingleton(() => UnblockUserUseCase(sl()));
  }
  if (!sl.isRegistered<FriendshipActionBloc>()) {
    sl.registerFactory(
      () => FriendshipActionBloc(
        sendFriendRequest: sl(),
        acceptFriendRequest: sl(),
        rejectFriendRequest: sl(),
        cancelSentRequest: sl(),
        removeFriend: sl(),
        blockUser: sl(),
        unblockUser: sl(),
      ),
    );
  }
  // Status Bloc use case
  if (!sl.isRegistered<GetFriendshipStatusUseCase>()) {
    sl.registerLazySingleton(() => GetFriendshipStatusUseCase(sl()));
  }
  if (!sl.isRegistered<FriendshipStatusBloc>()) {
    sl.registerFactory(
      () => FriendshipStatusBloc(
        getFriendshipStatus: sl(),
        getPendingRequests: sl(),
        getSentRequests: sl(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Messages UseCases + Blocs (ConversationsBloc, ChatBloc)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<GetConversationsUseCase>()) {
    sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteConversationUseCase>()) {
    sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  }
  if (!sl.isRegistered<MarkConversationAsReadUseCase>()) {
    sl.registerLazySingleton(() => MarkConversationAsReadUseCase(sl()));
  }
  if (!sl.isRegistered<msg_unread.GetUnreadCountUseCase>()) {
    sl.registerLazySingleton(() => msg_unread.GetUnreadCountUseCase(sl()));
  }
  if (!sl.isRegistered<ConversationsBloc>()) {
    sl.registerFactory(
      () => ConversationsBloc(
        getConversations: sl(),
        deleteConversation: sl(),
        markConversationAsRead: sl(),
        getUnreadCount: sl(),
        messageSignalRService: sl(),
      ),
    );
  }
  if (!sl.isRegistered<GetConversationMessagesUseCase>()) {
    sl.registerLazySingleton(() => GetConversationMessagesUseCase(sl()));
  }
  if (!sl.isRegistered<SendMessageUseCase>()) {
    sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  }
  if (!sl.isRegistered<EditMessageUseCase>()) {
    sl.registerLazySingleton(() => EditMessageUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteMessageUseCase>()) {
    sl.registerLazySingleton(() => DeleteMessageUseCase(sl()));
  }
  if (!sl.isRegistered<ChatBloc>()) {
    sl.registerFactory(
      () => ChatBloc(
        getMessages: sl(),
        sendMessage: sl(),
        editMessage: sl(),
        deleteMessage: sl(),
        markConversationAsRead: sl(),
        messageSignalRService: sl(),
        mediaApi: sl(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Interaction (Comments) UseCases + Bloc
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<GetCommentsUseCase>()) {
    sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  }
  if (!sl.isRegistered<AddCommentUseCase>()) {
    sl.registerLazySingleton(() => AddCommentUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteCommentUseCase>()) {
    sl.registerLazySingleton(() => DeleteCommentUseCase(sl()));
  }
  if (!sl.isRegistered<CommentsBloc>()) {
    sl.registerFactory(
      () => CommentsBloc(
        getComments: sl(),
        addComment: sl(),
        deleteComment: sl(),
        getCurrentUserIdUseCase: sl<GetCurrentUserIdUseCase>(),
        appSession: sl<AppSession>(),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Media UseCases
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<UploadImageUseCase>()) {
    sl.registerLazySingleton(() => UploadImageUseCase(sl()));
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Posts CreatePostCubit
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  if (!sl.isRegistered<CreatePostUseCase>()) {
    sl.registerLazySingleton(() => CreatePostUseCase(sl()));
  }
  if (!sl.isRegistered<CreatePostCubit>()) {
    sl.registerFactory(
      () => CreatePostCubit(createPost: sl(), uploadImage: sl()),
    );
  }
}

void _registerDeferredRuntimeSingletons() {
  if (!sl.isRegistered<CallListenerService>()) {
    sl.registerLazySingleton(() => CallListenerService());
  }
  // Status Management Feature
  if (!sl.isRegistered<StatusRemoteDataSource>()) {
    sl.registerLazySingleton<StatusRemoteDataSource>(
      () => StatusRemoteDataSourceImpl(sl()),
    );
  }
  if (!sl.isRegistered<StatusRepository>()) {
    sl.registerLazySingleton<StatusRepository>(
      () => StatusRepositoryImpl(sl()),
    );
  }
  if (!sl.isRegistered<StartRideUseCase>()) {
    sl.registerFactory(() => StartRideUseCase(sl()));
  }
  if (!sl.isRegistered<CompleteRideUseCase>()) {
    sl.registerFactory(() => CompleteRideUseCase(sl()));
  }
  if (!sl.isRegistered<CancelRideUseCase>()) {
    sl.registerFactory(() => CancelRideUseCase(sl()));
  }
  if (!sl.isRegistered<PostponeRideUseCase>()) {
    sl.registerFactory(() => PostponeRideUseCase(sl()));
  }

  // Call Feature
  if (!sl.isRegistered<CallRemoteDataSource>()) {
    sl.registerLazySingleton<CallRemoteDataSource>(
      () => CallRemoteDataSourceImpl(client: sl()),
    );
  }
  if (!sl.isRegistered<CallRepository>()) {
    sl.registerLazySingleton<CallRepository>(() => CallRepositoryImpl(sl()));
  }
  if (!sl.isRegistered<SendCallRequestUseCase>()) {
    sl.registerFactory(() => SendCallRequestUseCase(sl()));
  }
  if (!sl.isRegistered<AcceptCallUseCase>()) {
    sl.registerFactory(() => AcceptCallUseCase(sl()));
  }
  if (!sl.isRegistered<RejectCallUseCase>()) {
    sl.registerFactory(() => RejectCallUseCase(sl()));
  }
  if (!sl.isRegistered<EndCallUseCase>()) {
    sl.registerFactory(() => EndCallUseCase(sl()));
  }
  if (!sl.isRegistered<GetOnlineUsersUseCase>()) {
    sl.registerFactory(() => GetOnlineUsersUseCase(sl()));
  }
  if (!sl.isRegistered<CheckUserOnlineStatusUseCase>()) {
    sl.registerFactory(() => CheckUserOnlineStatusUseCase(sl()));
  }
  if (!sl.isRegistered<GetPendingCallsUseCase>()) {
    sl.registerFactory(() => GetPendingCallsUseCase(sl()));
  }
  if (!sl.isRegistered<CallBloc>()) {
    sl.registerLazySingleton(
      () => CallBloc(
        signalRService: sl(),
        webRTCService: sl(),
        sendCallRequestUseCase: sl(),
        acceptCallUseCase: sl(),
        rejectCallUseCase: sl(),
        endCallUseCase: sl(),
        getPendingCallsUseCase: sl(),
        permissionsService: sl(),
        callKitIncomingService: sl(),
      ),
    );
  }
}

Future<void> initCore() async {
  if (_coreInitialized) {
    return;
  }
  if (_coreInitCompleter != null) {
    return _coreInitCompleter!.future;
  }

  final completer = Completer<void>();
  _coreInitCompleter = completer;
  try {
    final stopwatch = Stopwatch()..start();
    setup();
    if (!sl.isRegistered<AppSession>()) {
      sl.registerLazySingleton(() => AppSession());
    }
    if (!sl.isRegistered<AuthBootstrapGate>()) {
      sl.registerLazySingleton(() => AuthBootstrapGate());
    }

    //! External
    final sharedPreferences = await SharedPreferences.getInstance();
    if (!sl.isRegistered<SharedPreferences>()) {
      sl.registerLazySingleton(() => sharedPreferences);
    }
    _logInitProfile('SharedPreferences', stopwatch);

    if (!sl.isRegistered<FlutterSecureStorage>()) {
      sl.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
      );
    }

    if (!sl.isRegistered<AuthLocalDataSource>()) {
      sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(
          sharedPreferences: sl(),
          secureStorage: sl(),
        ),
      );
    }
    _logInitProfile('AuthLocalDataSource', stopwatch);

    if (!sl.isRegistered<Dio>()) {
      final dio = await NetworkModule.provideDio(
        sl<AuthLocalDataSource>(),
        authBootstrapGate: sl<AuthBootstrapGate>(),
        onAuthInvalidated: _handleAuthInvalidationFromInterceptor,
        onTokenRefreshed: _handleTokenRefreshedFromInterceptor,
      );
      sl.registerSingleton<Dio>(dio);
    }
    _logInitProfile('NetworkModule.provideDio', stopwatch);

    sl.registerLazySingleton(
      () => SignalRService(sl<AuthLocalDataSource>(), sl<Dio>()),
    );
    if (!sl.isRegistered<AudioOrchestratorService>()) {
      sl.registerLazySingleton(() => AudioOrchestratorService());
    }
    if (!sl.isRegistered<PermissionsService>()) {
      sl.registerLazySingleton(() => PermissionsService());
    }
    if (!sl.isRegistered<WebRTCService>()) {
      sl.registerLazySingleton(() => WebRTCService());
    }
    if (!sl.isRegistered<LiveKitApi>()) {
      sl.registerLazySingleton(() => LiveKitApi(sl<Dio>()));
    }
    if (!sl.isRegistered<LiveKitRoomService>()) {
      sl.registerLazySingleton(() => LiveKitRoomService());
    }
    if (!sl.isRegistered<IntercomEngine>()) {
      sl.registerLazySingleton<IntercomEngine>(
        () => IntercomEngineImpl(
          signalRService: sl(),
          webRTCService: sl(),
          liveKitApi: sl(),
          liveKitRoomService: sl(),
          permissionsService: sl(),
          audioOrchestratorService: sl(),
          appSession: sl(),
        ),
      );
    }
    if (!sl.isRegistered<ConnectivityWatcherService>()) {
      sl.registerLazySingleton<ConnectivityWatcherService>(
        () => ConnectivityWatcherService(
          sl<SignalRService>(),
          sl<LiveKitRoomService>(),
        ),
      );
    }
    sl.registerLazySingleton(
      () => RealtimeStateCoordinator(signalRService: sl<SignalRService>()),
    );
    sl.registerLazySingleton(
      () => CommunicationRealtimeBus(sl<RealtimeStateCoordinator>()),
    );
    sl.registerLazySingleton(
      () => CommunicationRefreshCoordinator(sl<RealtimeStateCoordinator>()),
    );
    sl.registerLazySingleton(
      () => RealTimeService(sl<AppSession>(), sl<SignalRService>()),
    );
    sl.registerLazySingleton(() => HomeBootstrapService(sl()));
    sl.registerLazySingleton(() => HomeSummaryService(sl()));
    sl.registerLazySingleton(
      () => MessageSignalRService(sl<AuthLocalDataSource>()),
    );
    sl.registerLazySingleton(
      () => PresenceController(
        signalRService: sl<MessageSignalRService>(),
        dio: sl<Dio>(),
      ),
    );
    if (!sl.isRegistered<CallListenerService>()) {
      sl.registerLazySingleton<CallListenerService>(
        () => CallListenerService(),
      );
    }
    if (!sl.isRegistered<CallKitIncomingService>()) {
      sl.registerLazySingleton<CallKitIncomingService>(
        () => CallKitIncomingService(),
      );
    }
    if (!sl.isRegistered<SosAlertListenerService>()) {
      sl.registerLazySingleton<SosAlertListenerService>(
        () => SosAlertListenerService(sl<SignalRService>()),
      );
    }

    sl.registerLazySingleton(() => NotificationService(sl(), sl(), sl()));
    _logInitProfile('Core service registrations', stopwatch);

    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // ğŸ’³ REVENUECAT (SUBSCRIPTION) SERVICE INITIALIZATION
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (!sl.isRegistered<SubscriptionService>()) {
      final subscriptionService = SubscriptionServiceImpl(
        sl<Dio>(),
        sl<AuthLocalDataSource>(),
        sl<AppSession>(),
      );
      sl.registerLazySingleton<SubscriptionService>(() => subscriptionService);
      // Only call initialize once
      await subscriptionService.initialize();
    }

    // Feature'larÄ± kaydet (Auth, Profile, Friendship, Voice, Discover vb.)
    _registerCoreFeatureSingletons();
    _logInitProfile('registerCoreFeatureSingletons', stopwatch);    
    // Voice Session Feature (Core dependence for global Blocs)
    if (!sl.isRegistered<VoiceSessionApi>()) {
      sl.registerLazySingleton(() => VoiceSessionApi(sl()));
    }
    if (!sl.isRegistered<VoiceSessionRemoteDataSource>()) {
      sl.registerLazySingleton<VoiceSessionRemoteDataSource>(
        () => VoiceSessionRemoteDataSourceImpl(sl<VoiceSessionApi>()),
      );
    }
    if (!sl.isRegistered<VoiceSessionRepository>()) {
      sl.registerLazySingleton<VoiceSessionRepository>(
        () => VoiceSessionRepositoryImpl(sl()),
      );
    }

    // Voice Session UseCases
    if (!sl.isRegistered<CreateVoiceSessionUseCase>()) {
      sl.registerLazySingleton(() => CreateVoiceSessionUseCase(sl()));
    }
    if (!sl.isRegistered<JoinVoiceSessionUseCase>()) {
      sl.registerLazySingleton(() => JoinVoiceSessionUseCase(sl()));
    }
    if (!sl.isRegistered<LeaveVoiceSessionUseCase>()) {
      sl.registerLazySingleton(() => LeaveVoiceSessionUseCase(sl()));
    }
    if (!sl.isRegistered<InviteToVoiceSessionUseCase>()) {
      sl.registerLazySingleton(() => InviteToVoiceSessionUseCase(sl()));
    }
    if (!sl.isRegistered<GetVoiceSessionDetailsUseCase>()) {
      sl.registerLazySingleton(() => GetVoiceSessionDetailsUseCase(sl()));
    }
    if (!sl.isRegistered<GetMyVoiceSessionsUseCase>()) {
      sl.registerLazySingleton(() => GetMyVoiceSessionsUseCase(sl()));
    }
    if (!sl.isRegistered<AcceptVoiceSessionInvitationUseCase>()) {
      sl.registerLazySingleton(() => AcceptVoiceSessionInvitationUseCase(sl()));
    }
    if (!sl.isRegistered<RejectVoiceSessionInvitationUseCase>()) {
      sl.registerLazySingleton(() => RejectVoiceSessionInvitationUseCase(sl()));
    }
    if (!sl.isRegistered<EndVoiceSessionUseCase>()) {
      sl.registerLazySingleton(() => EndVoiceSessionUseCase(sl()));
    }
    if (!sl.isRegistered<KickUserUseCase>()) {
      sl.registerLazySingleton(() => KickUserUseCase(sl()));
    }
    if (!sl.isRegistered<MuteUserUseCase>()) {
      sl.registerLazySingleton(() => MuteUserUseCase(sl()));
    }
    if (!sl.isRegistered<TransferHostUseCase>()) {
      sl.registerLazySingleton(() => TransferHostUseCase(sl()));
    }
    if (!sl.isRegistered<PromoteParticipantUseCase>()) {
      sl.registerLazySingleton(() => PromoteParticipantUseCase(sl()));
    }
    if (!sl.isRegistered<DemoteParticipantUseCase>()) {
      sl.registerLazySingleton(() => DemoteParticipantUseCase(sl()));
    }
    if (!sl.isRegistered<KickParticipantUseCase>()) {
      sl.registerLazySingleton(() => KickParticipantUseCase(sl()));
    }


    if (!sl.isRegistered<GroupRideApi>()) {
      sl.registerLazySingleton(() => GroupRideApi(sl()));
    }
    if (!sl.isRegistered<GroupRideRemoteDataSource>()) {
      sl.registerLazySingleton<GroupRideRemoteDataSource>(
        () => GroupRideRemoteDataSourceImpl(sl<GroupRideApi>()),
      );
    }
    if (!sl.isRegistered<GroupRideRepository>()) {
      sl.registerLazySingleton<GroupRideRepository>(
        () => GroupRideRepositoryImpl(sl()),
      );
    }
    if (!sl.isRegistered<LiveRideController>()) {
      sl.registerLazySingleton<LiveRideController>(
        () => LiveRideController(
          sl<SignalRService>(),
          sl<AuthLocalDataSource>(),
          sl<GroupRideRepository>(),
        ),
      );
    }
    if (!sl.isRegistered<CreateGroupRideUseCase>()) {
      sl.registerFactory(() => CreateGroupRideUseCase(sl()));
    }
    if (!sl.isRegistered<GetActiveGroupRidesUseCase>()) {
      sl.registerFactory(() => GetActiveGroupRidesUseCase(sl()));
    }
    if (!sl.isRegistered<GetGroupRideByIdUseCase>()) {
      sl.registerFactory(() => GetGroupRideByIdUseCase(sl()));
    }
    if (!sl.isRegistered<UpdateGroupRideUseCase>()) {
      sl.registerFactory(() => UpdateGroupRideUseCase(sl()));
    }
    if (!sl.isRegistered<DeleteGroupRideUseCase>()) {
      sl.registerFactory(() => DeleteGroupRideUseCase(sl()));
    }
    if (!sl.isRegistered<LeaveGroupRideUseCase>()) {
      sl.registerFactory(() => LeaveGroupRideUseCase(sl()));
    }
    if (!sl.isRegistered<GroupRideBloc>()) {
      sl.registerFactory(
        () => GroupRideBloc(
          createGroupRideUseCase: sl(),
          deleteGroupRideUseCase: sl(),
          getActiveGroupRidesUseCase: sl(),
          leaveGroupRideUseCase: sl(),
          signalRService: sl(),
          realtimeBus: sl(),
          refreshCoordinator: sl(),
          updateGroupRideUseCase: sl(),
          getGroupRideByIdUseCase: sl(),
          getVoiceSessionDetailsUseCase: sl(),
        ),
      );
    }

    if (!sl.isRegistered<VoiceSessionBloc>()) {
      sl.registerLazySingleton(
        () => VoiceSessionBloc(
          createVoiceSessionUseCase: sl(),
          joinVoiceSessionUseCase: sl(),
          leaveVoiceSessionUseCase: sl(),
          inviteToVoiceSessionUseCase: sl(),
          getVoiceSessionDetailsUseCase: sl(),
          getMyVoiceSessionsUseCase: sl(),
          getCurrentUserIdUseCase: sl(),
          acceptVoiceSessionInvitationUseCase: sl(),
          rejectVoiceSessionInvitationUseCase: sl(),
          endVoiceSessionUseCase: sl(),
          appSession: sl(),
          kickUserUseCase: sl(),
          muteUserUseCase: sl(),
          transferHostUseCase: sl(),
          signalRService: sl(),
          realtimeBus: sl(),
          refreshCoordinator: sl(),
          permissionsService: sl(),
          intercomEngine: sl(),
          callKitIncomingService: sl(),
          audioOrchestratorService: sl(),
          promoteParticipantUseCase: sl(),
          demoteParticipantUseCase: sl(),
          kickParticipantUseCase: sl(),
          l10n: AppLocalizationsEn(), // Placeholder during init
        ),
      );
    }

    // --- ChangeNotifier Providers (GetIt singleton, root tree'den Ã§Ä±karÄ±ldÄ±) ---
    // NOT: AuthRepository ve ProfileRepository artÄ±k _registerFeatureSingletons()
    // tarafÄ±ndan yukarÄ±da kaydedildi.
    sl.registerLazySingleton(
      () => AuthProvider(
        sl<AuthRepository>(),
        sl<ProfileRepository>(),
        sl<NotificationService>(),
        sl<AppSession>(),
      ),
    );
    sl.registerLazySingleton(
      () => ProfileProvider(sl<ProfileRepository>(), sl<AppSession>()),
    );
    sl.registerLazySingleton(() => ThemeProvider());
    sl.registerLazySingleton(() => LanguageProvider());
    _logInitProfile('Root provider registrations', stopwatch);

    _coreInitialized = true;
    completer.complete();
  } catch (e, st) {
    completer.completeError(e, st);
    rethrow;
  } finally {
    _coreInitCompleter = null;
  }
}

Future<void> init() async {
  await initCore();
}

