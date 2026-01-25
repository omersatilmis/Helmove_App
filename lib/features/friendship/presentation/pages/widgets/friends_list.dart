import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
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
  late FriendshipListBloc _listBloc;

  @override
  void initState() {
    super.initState();
    _listBloc = sl<FriendshipListBloc>()..add(LoadMyFriendsEvent());
  }

  @override
  void dispose() {
    _listBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _listBloc,
      child: BlocBuilder<FriendshipListBloc, FriendshipListState>(
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
                    // TODO: Navigate to chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${friend.username} ile sohbet başlatılıyor...",
                        ),
                      ),
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
          return const SizedBox();
        },
      ),
    );
  }
}
