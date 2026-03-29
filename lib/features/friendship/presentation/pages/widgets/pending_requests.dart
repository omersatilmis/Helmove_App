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
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FriendshipListBloc>().add(
                LoadPendingRequestsEvent(),
              );
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
    } else if (state is PendingRequestsLoaded) {
      final requests = state.requests;
      if (requests.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(child: Text(AppLocalizations.of(context)!.noPendingRequests)),
          ],
        );
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return FriendStatusCard(
            imageUrl: request.requesterProfilePicture ?? '',
            firstName: request.requesterName ?? '',
            lastName: '',
            username: request.requesterUsername,
            statusInfo: request.requestedAt != null
              ? AppLocalizations.of(context)!.requestedOnDate(
                request.requestedAt!.day,
                request.requestedAt!.month,
                )
                : AppLocalizations.of(context)!.waiting,
            type: FriendshipCardType.received,
            onMessageTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.notFriendsYet)),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [SizedBox()],
    );
  }
}
