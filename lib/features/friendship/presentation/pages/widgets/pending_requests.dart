import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Consider adding this package or formatting manually
import '../../../../../../core/di/injection_container.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/list/friendship_list_bloc.dart';
import '../../bloc/list/friendship_list_event.dart';
import '../../bloc/list/friendship_list_state.dart';
import 'friend_status_card.dart';

class PendingRequests extends StatefulWidget {
  const PendingRequests({super.key});

  @override
  State<PendingRequests> createState() => _PendingRequestsState();
}

class _PendingRequestsState extends State<PendingRequests> {
  late FriendshipListBloc _listBloc;

  @override
  void initState() {
    super.initState();
    _listBloc = sl<FriendshipListBloc>()..add(LoadPendingRequestsEvent());
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
          } else if (state is PendingRequestsLoaded) {
            final requests = state.requests;
            if (requests.isEmpty) {
              return const Center(child: Text("Bekleyen istek yok."));
            }
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return FriendStatusCard(
                  index: index,
                  imageUrl: request.requesterProfilePicture ?? '',
                  firstName:
                      request.requesterName ??
                      '', // Assuming name is split or full, handling gracefully
                  lastName: '',
                  username: request.requesterUsername,
                  statusInfo: request.requestedAt != null
                      ? "${request.requestedAt!.day}/${request.requestedAt!.month} tarihinde"
                      : "Beklemede",
                  type: FriendshipCardType.received,
                  onMessageTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Henüz arkadaş değilsiniz."),
                      ),
                    );
                  },
                  onAcceptTap: () {
                    context.read<FriendshipActionBloc>().add(
                      AcceptFriendRequestEvent(friendshipId: request.id),
                    );
                  },
                  onRejectTap: () {
                    context.read<FriendshipActionBloc>().add(
                      RejectFriendRequestEvent(friendshipId: request.id),
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
