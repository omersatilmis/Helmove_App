import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/action/friendship_action_state.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<FriendshipListBloc>().add(LoadPendingRequestsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendshipActionBloc, FriendshipActionState>(
      listener: (context, state) {
        if (state is FriendshipActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          context.read<FriendshipListBloc>().add(LoadPendingRequestsEvent());
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
                context.read<FriendshipListBloc>().add(
                  LoadPendingRequestsEvent(),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(child: Text("Hata: ${state.message}")),
                ],
              ),
            );
          } else if (state is PendingRequestsLoaded) {
            final requests = state.requests;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendshipListBloc>().add(
                  LoadPendingRequestsEvent(),
                );
              },
              child: requests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(child: Text("Bekleyen istek yok.")),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return FriendStatusCard(
                          index: index,
                          imageUrl: request.requesterProfilePicture ?? '',
                          firstName: request.requesterName ?? '',
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
                              AcceptFriendRequestEvent(
                                friendshipId: request.id,
                              ),
                            );
                          },
                          onRejectTap: () {
                            context.read<FriendshipActionBloc>().add(
                              RejectFriendRequestEvent(
                                friendshipId: request.id,
                              ),
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
