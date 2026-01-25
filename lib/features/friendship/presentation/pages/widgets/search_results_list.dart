import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../bloc/action/friendship_action_bloc.dart';
import '../../bloc/action/friendship_action_event.dart';
import '../../bloc/action/friendship_action_state.dart';
import '../../bloc/list/friendship_list_bloc.dart';
import '../../bloc/list/friendship_list_state.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendshipListBloc, FriendshipListState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is FriendshipListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendshipListFailure) {
          return Center(child: Text("Hata: ${state.message}"));
        } else if (state is FriendSearchResultsLoaded) {
          final results = state.results;
          if (results.isEmpty) {
            return const Center(child: Text("Kullanıcı bulunamadı."));
          }
          return ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = results[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePictureUrl != null
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null
                        ? Text(user.username[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.username),
                  subtitle: Text(
                    user.firstName != null
                        ? "${user.firstName} ${user.lastName ?? ''}"
                        : "",
                  ),
                  trailing: BlocProvider(
                    create: (_) => sl<FriendshipActionBloc>(),
                    child:
                        BlocConsumer<
                          FriendshipActionBloc,
                          FriendshipActionState
                        >(
                          listener: (context, state) {
                            if (state is FriendshipActionSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            } else if (state is FriendshipActionFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.error)),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is FriendshipActionLoading) {
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            // Check if already friends or request sent?
                            // The API search result might not allow us to know status immediately unless expanded.
                            // For now assuming we can send request.
                            return IconButton(
                              icon: const Icon(
                                Icons.person_add,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                context.read<FriendshipActionBloc>().add(
                                  SendFriendRequestEvent(
                                    targetUserId: user.id,
                                    message: "Merhaba, arkadaş olalım!",
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: Text("Aramak için yazmaya başlayın..."));
      },
    );
  }
}
