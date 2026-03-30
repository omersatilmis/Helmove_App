import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/list/follow_list_bloc.dart';
import '../bloc/list/follow_list_event.dart';
import '../bloc/list/follow_list_state.dart';
import '../bloc/action/follow_action_bloc.dart';
import '../bloc/action/follow_action_event.dart';
import '../bloc/action/follow_action_state.dart';
import '../../domain/entities/follow_user.dart';

enum FollowListType { followers, following }

class FollowListPage extends StatelessWidget {
  final int userId;
  final FollowListType type;

  const FollowListPage({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (type == FollowListType.followers)
          BlocProvider<FollowersListBloc>(
            create: (context) => sl<FollowersListBloc>()..add(LoadFollowersEvent(userId: userId)),
          )
        else
          BlocProvider<FollowingListBloc>(
            create: (context) => sl<FollowingListBloc>()..add(LoadFollowingEvent(userId: userId)),
          ),
        BlocProvider<FollowActionBloc>(
          create: (context) => sl<FollowActionBloc>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<FollowActionBloc, FollowActionState>(
            listener: (context, state) {
              if (state is FollowUserSuccess) {
                _updateListStatus(context, state.userId, true);
                context.read<ProfileProvider>().updateFollowStats(
                  userId: state.userId,
                  isFollowing: true,
                );
              } else if (state is UnfollowUserSuccess) {
                _updateListStatus(context, state.userId, false);
                context.read<ProfileProvider>().updateFollowStats(
                  userId: state.userId,
                  isFollowing: false,
                );
              } else if (state is FollowActionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              type == FollowListType.followers
                  ? AppLocalizations.of(context)!.followers
                  : AppLocalizations.of(context)!.following,
            ),
            centerTitle: true,
          ),
          body: _FollowListView(
            userId: userId,
            type: type,
          ),
        ),
      ),
    );
  }

  void _updateListStatus(BuildContext context, int targetUserId, bool isFollowing) {
    if (type == FollowListType.followers) {
      context.read<FollowersListBloc>().add(
        UpdateUserFollowStatusEvent(userId: targetUserId, isFollowing: isFollowing),
      );
    } else {
      context.read<FollowingListBloc>().add(
        UpdateUserFollowStatusEvent(userId: targetUserId, isFollowing: isFollowing),
      );
    }
  }
}

class _FollowUserTile extends StatelessWidget {
  final FollowUser user;
  final FollowListType type;
  final int? currentUserId;

  const _FollowUserTile({
    required this.user,
    required this.type,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelf = currentUserId != null && currentUserId == user.id;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
              ? CachedNetworkImageProvider(user.profilePictureUrl!) as ImageProvider
              : const AssetImage('assets/icons/ic_profile.png'),
        ),
      ),
      title: Text(
        user.fullName.isNotEmpty ? user.fullName : user.username,
        style: AppTextStyles.bold.copyWith(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "@${user.username}",
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (user.isFollower) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Seni takip ediyor",
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: isSelf
          ? null
          : BlocBuilder<FollowActionBloc, FollowActionState>(
              builder: (context, state) {
                final isLoading =
                    state is FollowActionLoading && state.userId == user.id;

                return AppButton(
                  text: user.isFollowing
                      ? AppLocalizations.of(context)!.followingListStatus
                      : AppLocalizations.of(context)!.follow,
                  onPressed: () {
                    final bloc = context.read<FollowActionBloc>();
                    if (user.isFollowing) {
                      bloc.add(UnfollowUserEvent(user.id));
                    } else {
                      bloc.add(FollowUserEvent(user.id));
                    }
                  },
                  variant: AppButtonVariant.primary,
                  style: user.isFollowing
                      ? AppButtonStyle.outlined
                      : AppButtonStyle.filled,
                  size: AppButtonSize.small,
                  width: 100,
                  isLoading: isLoading,
                );
              },
            ),
      onTap: () {
        context.push('/profile/${user.id}');
      },
    );
  }
}

class _FollowListView extends StatefulWidget {
  final int userId;
  final FollowListType type;

  const _FollowListView({
    required this.userId,
    required this.type,
  });

  @override
  State<_FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<_FollowListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _handleRefresh() async {
    if (widget.type == FollowListType.followers) {
      context.read<FollowersListBloc>().add(LoadFollowersEvent(userId: widget.userId, refresh: true));
    } else {
      context.read<FollowingListBloc>().add(LoadFollowingEvent(userId: widget.userId, refresh: true));
    }

    // Refresh profile stats so counters remain consistent.
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.isOwnProfileTarget(widget.userId.toString())) {
      await profileProvider.loadProfile(forceRefresh: true);
    } else {
      await profileProvider.loadUserProfile(widget.userId, forceRefresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.type == FollowListType.followers) {
        context.read<FollowersListBloc>().add(LoadFollowersEvent(userId: widget.userId));
      } else {
        context.read<FollowingListBloc>().add(LoadFollowingEvent(userId: widget.userId));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == FollowListType.followers) {
      return BlocBuilder<FollowersListBloc, FollowListState>(
        builder: _buildListView,
      );
    } else {
      return BlocBuilder<FollowingListBloc, FollowListState>(
        builder: _buildListView,
      );
    }
  }

  Widget _buildListView(BuildContext context, FollowListState state) {
    final currentUserId = context.read<ProfileProvider>().currentUserId;
    List<FollowUser> users = [];
    bool hasReachedMax = false;
    String? error;

    if (state is FollowListLoaded) {
      users = state.users;
      hasReachedMax = state.hasReachedMax;
    } else if (state is FollowListLoading) {
      // If we already have users (from a previous Loaded state), we can show them
      // But the current implementation of Bloc might not preserve them in Loading state
      // Let's check how the Bloc handles pagination loading
    } else if (state is FollowListError) {
      error = state.message;
    }

    if (state is FollowListLoading && users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null && users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.errorLabel(error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleRefresh,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(child: Text(AppLocalizations.of(context)!.noResultsFound)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: users.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final user = users[index];
          return _FollowUserTile(
            user: user,
            type: widget.type,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}
