import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/enums/user_tier.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

// --- KENDİ PROJE IMPORTLARIN ---
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/profile_info.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/profile_tabs.dart';

// 🔥 PROVIDER IMPORTLARI
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

// 🔥 FRIENDSHIP BLOC IMPORTLARI
import 'package:flutter_bloc/flutter_bloc.dart'
    hide ReadContext, WatchContext, SelectContext;
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_event.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_state.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_event.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_state.dart';
import 'package:moto_comm_app_1/features/friendship/domain/entities/friendship_status.dart';
import 'package:moto_comm_app_1/core/constants/report_enums.dart';
import 'package:moto_comm_app_1/features/help/presentation/widgets/report_bottom_sheet.dart';
import 'package:moto_comm_app_1/features/follow/presentation/bloc/action/follow_action_bloc.dart';
import 'package:moto_comm_app_1/features/follow/presentation/bloc/action/follow_action_event.dart' as follow_events;
import 'package:moto_comm_app_1/features/follow/presentation/bloc/action/follow_action_state.dart';
import 'package:moto_comm_app_1/features/follow/presentation/pages/follow_list_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileInfoKey = GlobalKey();
  final GlobalKey _optionsButtonKey = GlobalKey();

  double _dynamicHeight = 450;
  double _headerOpacity = 1.0;
  double _statsOpacity = 1.0;
  bool _showPinnedTitle = false;

  FriendshipStatusBloc? _statusBloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    final profileProvider = context.read<ProfileProvider>();
    final myId = profileProvider.currentUserId;
    final bool isMe = profileProvider.isOwnProfileTarget(widget.userId);

    if (!isMe) {
      final userIdInt = int.tryParse(widget.userId!);
      if (userIdInt != null) {
        _statusBloc = sl<FriendshipStatusBloc>()..add(CheckFriendshipStatusEvent(targetUserId: userIdInt));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMe && myId != null) {
        context.read<ProfileProvider>().loadProfile();
      } else {
        final userIdInt = int.tryParse(widget.userId!);
        if (userIdInt != null) {
          context.read<ProfileProvider>().loadUserProfile(userIdInt);
        }
      }
      _calculateHeight();
    });
  }

  Future<void> _handleRefresh() async {
    final profileProvider = context.read<ProfileProvider>();
    final isMe = profileProvider.isOwnProfileTarget(widget.userId);

    if (isMe) {
      await profileProvider.loadProfile(forceRefresh: true);
    } else {
      final userIdInt = int.tryParse(widget.userId!);
      if (userIdInt != null) {
        await profileProvider.loadUserProfile(userIdInt, forceRefresh: true);
        _statusBloc?.add(CheckFriendshipStatusEvent(targetUserId: userIdInt));
      }
    }
  }

  void _calculateHeight() {
    final RenderBox? renderBox = _profileInfoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      if (renderBox.size.height != _dynamicHeight) {
        setState(() {
          _dynamicHeight = renderBox.size.height;
        });
      }
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final topSafe = MediaQuery.of(context).padding.top;
    final totalHeight = _dynamicHeight > 0 ? _dynamicHeight : 300.0;

    final headerFade = (1 - (offset / (totalHeight * 0.75))).clamp(0.0, 1.0);
    final statsStart = totalHeight * 0.35;
    final statsEnd = totalHeight * 0.55;
    final range = (statsEnd - statsStart) > 0 ? (statsEnd - statsStart) : 1.0;
    final statsFade = (1 - ((offset - statsStart) / range)).clamp(0.0, 1.0);
    final showTitle = offset > (totalHeight - kToolbarHeight - topSafe - 20);

    if (headerFade != _headerOpacity ||
        statsFade != _statsOpacity ||
        showTitle != _showPinnedTitle) {
      setState(() {
        _headerOpacity = headerFade;
        _statsOpacity = statsFade;
        _showPinnedTitle = showTitle;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _statusBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topSafe = MediaQuery.of(context).padding.top;

    final profileProvider = context.watch<ProfileProvider>();
    final isOwnProfile = profileProvider.isOwnProfileTarget(widget.userId);
    final displayedUser = isOwnProfile ? profileProvider.profile : profileProvider.visitedProfile;

    final firstName = displayedUser?.firstName ?? "";
    final lastName = displayedUser?.lastName ?? "";
    final username = displayedUser?.username ?? "";
    final bio = displayedUser?.bio;
    final profileImageUrl = displayedUser?.profileImageUrl;
    final followersCount = displayedUser?.followersCount ?? 0;
    final followingCount = displayedUser?.followingCount ?? 0;
    final isFollowing = displayedUser?.isFollowing ?? false;

    final double minAppBarHeight = kToolbarHeight + topSafe + 20;

    return MultiBlocProvider(
      providers: [
        BlocProvider<FriendshipActionBloc>(create: (_) => sl<FriendshipActionBloc>()),
        BlocProvider<FollowActionBloc>(create: (_) => sl<FollowActionBloc>()),
        if (_statusBloc != null) BlocProvider.value(value: _statusBloc!),
      ],
      child: profileProvider.errorMessage != null
          ? Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_rounded, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(height: 20),
                      Text(
                        profileProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h3.copyWith(color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Bu profile ulaşılamıyor.",
                        style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : DefaultTabController(
              length: 5,
              child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            displacement: topSafe + 60,
            edgeOffset: topSafe,
            backgroundColor: theme.colorScheme.surface,
            color: theme.colorScheme.primary,
            child: Stack(
              children: [
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: NestedScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverOverlapAbsorber(
                          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                          sliver: SliverAppBar(
                            expandedHeight: math.max(_dynamicHeight, minAppBarHeight),
                            toolbarHeight: kToolbarHeight + topSafe + 15,
                            pinned: true,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            centerTitle: true,
                            title: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _showPinnedTitle ? 1 : 0,
                              child: Padding(
                                padding: EdgeInsets.only(top: topSafe / 1.5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "$firstName $lastName",
                                      style: AppTextStyles.h3.copyWith(
                                        fontSize: 18,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "@$username",
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              collapseMode: CollapseMode.parallax,
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: Container(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: ProfileInfoWrapperWidget(
                                          firstName: firstName,
                                          lastName: lastName,
                                          username: username,
                                          isOwnProfile: isOwnProfile,
                                          bio: bio,
                                          profileImageUrl: profileImageUrl,
                                          otherUserId: displayedUser?.id,
                                          followersCount: followersCount,
                                          followingCount: followingCount,
                                          friendsCount: displayedUser?.friendsCount ?? 0,
                                          isFollowing: isFollowing,
                                          tier: displayedUser?.tier ?? UserTier.free,
                                          myId: profileProvider.currentUserId,
                                          profileProvider: profileProvider,
                                          profileInfoKey: _profileInfoKey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 120),
                                      opacity: 1 - _headerOpacity,
                                      child: Container(color: theme.scaffoldBackgroundColor),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, left: 0, right: 0, height: 160,
                                    child: IgnorePointer(
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 120),
                                        opacity: 1 - _statsOpacity,
                                        child: Container(color: theme.scaffoldBackgroundColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const ProfileTabBarSliver(),
                      ];
                    },
                    body: const ProfileTabViews(),
                  ),
                ),
                Positioned(
                  top: topSafe + 5, left: 12, right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppFrostedButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          if (context.canPop()) context.pop();
                        },
                      ),
                      Container(
                        key: _optionsButtonKey,
                        child: AppFrostedButton(
                          icon: Icons.more_horiz_rounded,
                          onTap: () => _showOptionsMenu(context, isOwnProfile, displayedUser?.id, username),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsMenu(BuildContext context, bool isOwnProfile, int? userId, String username) async {
    final RenderBox? renderBox = _optionsButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final theme = Theme.of(context);

    final value = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 150 + size.width, offset.dy + size.height + 10,
        offset.dx + size.width, offset.dy + size.height + 200,
      ),
      elevation: 8,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Text("Profili Paylaş", style: AppTextStyles.medium.copyWith(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
        if (isOwnProfile) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Text("Ayarlar", style: AppTextStyles.medium.copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
        if (!isOwnProfile) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'block',
            child: Row(
              children: [
                const Icon(Icons.block_outlined, color: Colors.red),
                const SizedBox(width: 12),
                Text("Kullanıcıyı Engelle", style: AppTextStyles.medium.copyWith(color: Colors.red)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.report_problem_outlined, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Text("Bildir", style: AppTextStyles.medium.copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ],
    );

    if (value == 'share') {
      if (!context.mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      final String profileUrl = "https://motocomm.app/profile/${userId ?? profileProvider.currentUserId}";
      final String shareText = isOwnProfile 
          ? "MotoComm'da profilime göz at! $profileUrl" 
          : "MotoComm'da $username kullanıcısının profiline göz at! $profileUrl";
      
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: shareText,
          subject: 'MotoComm Profil Paylaşımı',
        ),
      );
    } else if (value == 'settings') {
      if (!context.mounted) return;
      context.push('/settings');
    } else if (value == 'block' && userId != null) {
      if (!context.mounted) return;
      context.read<FollowActionBloc>().add(follow_events.BlockUserEvent(userId));
    } else if (value == 'report' && userId != null) {
      if (!context.mounted) return;
      ReportBottomSheet.show(context, targetId: userId.toString(), targetType: ReportTargetType.user);
    }
  }
}

class ProfileInfoWrapperWidget extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final bool isOwnProfile;
  final String? bio;
  final String? profileImageUrl;
  final int? otherUserId;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final bool isFollowing;
  final UserTier tier;
  final int? myId;
  final ProfileProvider profileProvider;
  final GlobalKey profileInfoKey;

  const ProfileInfoWrapperWidget({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.isOwnProfile,
    this.bio,
    this.profileImageUrl,
    this.otherUserId,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.isFollowing = false,
    this.tier = UserTier.free,
    this.myId,
    required this.profileProvider,
    required this.profileInfoKey,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return ProfileInfo(
        firstName: firstName,
        lastName: lastName,
        username: username,
        bio: bio,
        profileImageUrl: profileImageUrl,
        isOwnProfile: true,
        tier: tier,
        friendCount: friendsCount.toString(),
        followerCount: followersCount.toString(),
        followingCount: followingCount.toString(),
        isFollowing: isFollowing,
        key: profileInfoKey,
        onFriendsTap: () => context.push('/friends'),
        onFollowersTap: () {
          final targetId = profileProvider.currentUserId;
          if (targetId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FollowListPage(userId: targetId, type: FollowListType.followers)),
            );
          }
        },
        onFollowingTap: () {
          final targetId = profileProvider.currentUserId;
          if (targetId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FollowListPage(userId: targetId, type: FollowListType.following)),
            );
          }
        },
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<FriendshipActionBloc, FriendshipActionState>(
          listener: (context, actionState) {
            if (actionState is FriendshipActionSuccess) {
              if (otherUserId != null) {
                context.read<FriendshipStatusBloc>().add(CheckFriendshipStatusEvent(targetUserId: otherUserId!));
                if (actionState.message.contains("accepted") || actionState.message.contains("kabul")) {
                  profileProvider.updateFollowStats(userId: otherUserId!, isFollowing: true);
                } else if (actionState.message.contains("removed") || actionState.message.contains("çıkar")) {
                  profileProvider.updateFollowStats(userId: otherUserId!, isFollowing: false);
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(actionState.message)));
            } else if (actionState is FriendshipActionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(actionState.error), backgroundColor: Colors.red),
              );
            }
          },
        ),
        BlocListener<FollowActionBloc, FollowActionState>(
          listener: (context, followState) {
            if (followState is FollowUserSuccess) {
              profileProvider.updateFollowStats(userId: followState.userId, isFollowing: true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı takip ediliyor")));
            } else if (followState is UnfollowUserSuccess) {
              profileProvider.updateFollowStats(userId: followState.userId, isFollowing: false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takipten çıkıldı")));
            } else if (followState is BlockUserSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı engellendi")));
              if (context.canPop()) context.pop();
            }
          },
        ),
      ],
      child: BlocBuilder<FriendshipStatusBloc, FriendshipStatusState>(
        builder: (context, statusState) {
          FriendshipStatus? status;
          FriendRequestType? requestType;
          int? friendshipId;

          if (statusState is FriendshipStatusLoaded) {
            status = statusState.status;
            requestType = statusState.requestType;
            friendshipId = statusState.friendshipId;
          }

          return BlocBuilder<FollowActionBloc, FollowActionState>(
            builder: (context, followState) {
              return ProfileInfo(
                firstName: firstName,
                lastName: lastName,
                username: username,
                bio: bio,
                profileImageUrl: profileImageUrl,
                isOwnProfile: false,
                tier: tier,
                friendCount: friendsCount.toString(),
                followerCount: followersCount.toString(),
                followingCount: followingCount.toString(),
                isFollowing: isFollowing,
                friendshipStatus: status,
                friendRequestType: requestType,
                isLoadingStatus: statusState is FriendshipStatusLoading,
                isFollowActionLoading: followState is FollowActionLoading,
                onFollowersTap: () {
                  final targetId = otherUserId ?? myId;
                  if (targetId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FollowListPage(userId: targetId, type: FollowListType.followers)),
                    );
                  }
                },
                onFollowingTap: () {
                  final targetId = otherUserId ?? myId;
                  if (targetId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FollowListPage(userId: targetId, type: FollowListType.following)),
                    );
                  }
                },
                onFollowTap: () {
                  if (otherUserId != null) {
                    profileProvider.updateFollowStats(userId: otherUserId!, isFollowing: true);
                    context.read<FollowActionBloc>().add(follow_events.FollowUserEvent(otherUserId!));
                  }
                },
                onUnfollowTap: () {
                  if (otherUserId != null) {
                    profileProvider.updateFollowStats(userId: otherUserId!, isFollowing: false);
                    context.read<FollowActionBloc>().add(follow_events.UnfollowUserEvent(otherUserId!));
                  }
                },
                onSendRequest: () {
                  if (otherUserId != null) {
                    context.read<FriendshipActionBloc>().add(
                      SendFriendRequestEvent(targetUserId: otherUserId!, message: "Merhaba!"),
                    );
                  }
                },
                onCancelRequest: () {
                  if (otherUserId != null) {
                    context.read<FriendshipActionBloc>().add(RemoveFriendEvent(friendId: otherUserId!));
                  }
                },
                onAcceptRequest: () {
                  if (friendshipId != null) {
                    context.read<FriendshipActionBloc>().add(AcceptFriendRequestEvent(friendshipId: friendshipId));
                  }
                },
                onRejectRequest: () {
                  if (friendshipId != null) {
                    context.read<FriendshipActionBloc>().add(RejectFriendRequestEvent(friendshipId: friendshipId));
                  }
                },
                onRemoveFriend: () {
                  if (otherUserId != null) {
                    context.read<FriendshipActionBloc>().add(RemoveFriendEvent(friendId: otherUserId!));
                  }
                },
                key: profileInfoKey,
              );
            },
          );
        },
      ),
    );
  }
}