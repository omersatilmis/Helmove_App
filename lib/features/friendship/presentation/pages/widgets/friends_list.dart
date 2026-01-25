import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/list/friendship_list_bloc.dart';
import '../../bloc/list/friendship_list_event.dart';
import '../../bloc/list/friendship_list_state.dart';
import 'friend_status_card.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

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
    return BlocBuilder<FriendshipListBloc, FriendshipListState>(
      builder: (context, state) {
        if (state is FriendshipListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendshipListFailure) {
          return Center(child: Text("Hata: ${state.message}"));
        } else if (state is MyFriendsLoaded) {
          final friends = state.friends;
          if (friends.isEmpty) {
            return const Center(child: Text("Henüz arkadaşın yok."));
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return FriendStatusCard(
                index: index,
                imageUrl: friend.profilePictureUrl ?? '',
                firstName: friend.firstName ?? '',
                lastName: friend.lastName ?? '',
                username: friend.username,
                statusInfo: friend.isOnline ? "Çevrimiçi" : "Çevrimdışı",
                type: FriendshipCardType.friends,
                onMessageTap: () {
                  // Navigate to chat
                  // Navigator.push...
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${friend.username} ile sohbet...")),
                  );
                },
                onRemoveTap: () {
                  context.read<FriendshipActionBloc>().add(
                    RemoveFriendEvent(friendId: friend.id),
                  );
                },
              );
            },
          );
        }
        // If searching or other state, show empty or loading?
        // Logic handled by parent, but if state is irrelevant here, return empty.
        return const SizedBox();
      },
    );
  }
}
