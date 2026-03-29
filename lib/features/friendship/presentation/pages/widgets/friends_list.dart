import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/action/friendship_action_state.dart';
import '../../bloc/list/friendship_list_bloc.dart';
import '../../bloc/list/friendship_list_event.dart';
import '../../bloc/list/friendship_list_state.dart';
import 'friend_status_card.dart';

class FriendsList extends StatefulWidget {
  final Function(dynamic friend)? onFriendSelected;

  const FriendsList({super.key, this.onFriendSelected});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  @override
  void initState() {
    super.initState();
    // Use the Bloc provided by FriendsPage
    context.read<FriendshipListBloc>().add(LoadMyFriendsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendshipActionBloc, FriendshipActionState>(
      listener: (context, state) {
        if (state is FriendshipActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          context.read<FriendshipListBloc>().add(LoadMyFriendsEvent());
        } else if (state is FriendshipActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<FriendshipListBloc, FriendshipListState>(
        builder: (context, state) {
          if (state is FriendshipListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // We wrap the content in a RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FriendshipListBloc>().add(LoadMyFriendsEvent());
            },
            child: _buildContent(context, state),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FriendshipListState state) {
    if (state is FriendshipListFailure) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(child: Text(AppLocalizations.of(context)!.errorLabel(state.message))),
        ],
      );
    } else if (state is MyFriendsLoaded) {
      final friends = state.friends;
      if (friends.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(child: Text(AppLocalizations.of(context)!.noFriendsYet)),
          ],
        );
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return FriendStatusCard(
            imageUrl: friend.profilePictureUrl ?? '',
            firstName: friend.firstName ?? '',
            lastName: friend.lastName ?? '',
            username: friend.username,
            statusInfo: friend.isOnline 
                ? AppLocalizations.of(context)!.online 
                : AppLocalizations.of(context)!.offline,
            type: FriendshipCardType.friends,
            showActions: widget.onFriendSelected == null,
            onCardTap: widget.onFriendSelected != null
                ? () => widget.onFriendSelected!(friend)
                : null,
            onMessageTap: () {
              // Navigate to chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.chattingWith(friend.username))),
              );
            },
            onOptionsTap: () {
              context.read<FriendshipActionBloc>().add(
                RemoveFriendEvent(friendId: friend.userId),
              );
            },
          );
        },
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [SizedBox()],
    );
  }
}
