import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/action/friendship_action_state.dart';
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
          } else if (state is FriendshipListFailure) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendshipListBloc>().add(LoadMyFriendsEvent());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(child: Text("Hata: ${state.message}")),
                ],
              ),
            );
          } else if (state is MyFriendsLoaded) {
            final friends = state.friends;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendshipListBloc>().add(LoadMyFriendsEvent());
              },
              child: friends.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(child: Text("Henüz arkadaşın yok.")),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return FriendStatusCard(
                          index: index,
                          imageUrl: friend.profilePictureUrl ?? '',
                          firstName: friend.firstName ?? '',
                          lastName: friend.lastName ?? '',
                          username: friend.username,
                          statusInfo: friend.isOnline
                              ? "Çevrimiçi"
                              : "Çevrimdışı",
                          type: FriendshipCardType.friends,
                          onMessageTap: () {
                            // Navigate to chat
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${friend.username} ile sohbet...",
                                ),
                              ),
                            );
                          },
                          onRemoveTap: () {
                            context.read<FriendshipActionBloc>().add(
                              // removeFriend expects User ID
                              RemoveFriendEvent(friendId: friend.userId),
                            );
                          },
                        );
                      },
                    ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
