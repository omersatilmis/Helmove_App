import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/friendship_error_mapper.dart';
import '../../../follow/presentation/bloc/list/follow_list_bloc.dart';
import '../../../follow/presentation/bloc/list/follow_list_event.dart';
import '../../../follow/presentation/bloc/list/follow_list_state.dart';
import '../../../follow/presentation/bloc/action/follow_action_bloc.dart';
import '../../../follow/presentation/bloc/action/follow_action_event.dart';
import '../../../follow/presentation/bloc/action/follow_action_state.dart';
import '../../../follow/domain/entities/follow_user.dart';
import 'package:helmove/l10n/app_localizations.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return MultiBlocProvider(
      providers: [
        BlocProvider<BlockedListBloc>(
          create: (context) => sl<BlockedListBloc>()..add(const LoadBlockedUsersEvent()),
        ),
        BlocProvider<FollowActionBloc>(
          create: (context) => sl<FollowActionBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.blockedAccounts),
          centerTitle: true,
        ),
        body: const _BlockedUsersView(),
      ),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return BlocListener<FollowActionBloc, FollowActionState>(
      listener: (context, state) {
        if (state is UnblockUserSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userUnblocked),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the list after unblocking
          context.read<BlockedListBloc>().add(const LoadBlockedUsersEvent(refresh: true));
        } else if (state is FollowActionError) {
          final mappedMessage = FriendshipErrorMapper.mapForUi(
            rawMessage: state.message,
            l10n: l10n,
            fallback: l10n.errorOccurred,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mappedMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<BlockedListBloc, FollowListState>(
        builder: (context, state) {
          if (state is FollowListLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is FollowListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorWithPrefix(state.message)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BlockedListBloc>().add(const LoadBlockedUsersEvent(refresh: true));
                    },
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (state is FollowListLoaded) {
            final users = state.users;

            if (users.isEmpty) {
              return Center(child: Text(l10n.noBlockedUsers));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<BlockedListBloc>().add(const LoadBlockedUsersEvent(refresh: true));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _BlockedUserTile(user: user);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final FollowUser user;

  const _BlockedUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // PP
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePictureUrl!.toAbsoluteImageUrl()) as ImageProvider
                  : const AssetImage('assets/images/default_avatar.png'),
            ),
          ),
          const SizedBox(width: 16),
          // Info (Center)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.username,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  "@${user.username}",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Action (Right)
          BlocBuilder<FollowActionBloc, FollowActionState>(
            builder: (context, state) {
              final isLoading = state is FollowActionLoading && state.userId == user.id;

              return AppButton(
                text: l10n.unblockUser,
                onPressed: () {
                  context.read<FollowActionBloc>().add(UnblockUserEvent(user.id));
                },
                variant: AppButtonVariant.primary,
                style: AppButtonStyle.outlined,
                size: AppButtonSize.small,
                width: 110,
                isLoading: isLoading,
              );
            },
          ),
        ],
      ),
    );
  }
}
