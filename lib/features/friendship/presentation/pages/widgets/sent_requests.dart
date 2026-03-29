import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
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
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FriendshipListBloc>().add(LoadSentRequestsEvent());
          },
          child: _buildContent(context, state),
        );
      },
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
    } else if (state is SentRequestsLoaded) {
      final requests = state.requests;
      if (requests.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(child: Text(AppLocalizations.of(context)!.noSentRequestsYet)),
          ],
        );
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final displayUsername =
            request.receiverUsername ?? AppLocalizations.of(context)!.unknownUser;
          final displayName =
            request.receiverName ?? AppLocalizations.of(context)!.unnamedUser;
          final displayPicture = request.receiverProfilePicture ?? '';
          return FriendStatusCard(
            imageUrl: displayPicture,
            firstName: displayName,
            lastName: '',
            username: displayUsername,
            statusInfo: AppLocalizations.of(context)!.requestSent,
            type: FriendshipCardType.sent,
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
