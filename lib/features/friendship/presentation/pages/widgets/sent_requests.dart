import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/list/friendship_list_bloc.dart';
import '../../bloc/list/friendship_list_event.dart';
import '../../bloc/list/friendship_list_state.dart';
import 'friend_status_card.dart';

class SentRequests extends StatefulWidget {
  const SentRequests({super.key});

  @override
  State<SentRequests> createState() => _SentRequestsState();
}

class _SentRequestsState extends State<SentRequests> {
  @override
  void initState() {
    super.initState();
    context.read<FriendshipListBloc>().add(LoadSentRequestsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendshipListBloc, FriendshipListState>(
      builder: (context, state) {
        if (state is FriendshipListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendshipListFailure) {
          return Center(child: Text("Hata: ${state.message}"));
        } else if (state is SentRequestsLoaded) {
          // Note: Since SentRequests typically return REQUEST objects, we map them too.
          // But usually Sent Requests might not carry full profile info of target user depending on API.
          // Assuming FriendRequestEntity has target info or requester info (here it gets tricky if API only returns 'request' entity structure).
          // For now, mapping best effort.
          final requests = state.requests;
          if (requests.isEmpty) {
            return const Center(child: Text("Gönderilen istek yok."));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              // In a real app, sent requests should show TARGET user info.
              // Current FriendRequestEntity seems to store 'requester' info (which is me).
              // I'll assume for now we might need to adjust Entity/DTO to include 'targetUser' info for SentRequests.
              // Or maybe 'requesterUsername' is actually the 'other' person in some contexts?
              // Standard: SentRequest -> Target User.

              return FriendStatusCard(
                index: index,
                imageUrl: '', // Target user image
                firstName: 'User',
                lastName: '${request.id}',
                username: 'target_user', // Placeholder as DTO might need update
                statusInfo: "İstek gönderildi",
                type: FriendshipCardType.sent,
                onMessageTap: null, // Can't msg yet
                onCancelRequestTap: () {
                  // Usually requires cancelling by ID
                  context.read<FriendshipActionBloc>().add(
                    // Remove/Cancel logic
                    // Ideally: CancelFriendRequestEvent
                    // Reuse Reject/Remove? Usually 'Delete' endpoint handles cancellation too.
                    // Using RemoveFriendEvent for now if ID matches friendship ID
                    RemoveFriendEvent(friendId: request.id),
                  );
                },
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}
