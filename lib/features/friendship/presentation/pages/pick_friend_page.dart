import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/list/friendship_list_bloc.dart';
import 'package:moto_comm_app_1/features/messages/presentation/pages/chat_page.dart';
import 'widgets/friends_list.dart';

class PickFriendPage extends StatelessWidget {
  const PickFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FriendshipListBloc>()),
        // Action bloc might be needed by FriendsList internally even if we don't use actions
        BlocProvider(create: (_) => sl<FriendshipActionBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppFrostedButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          title: Column(
            children: [
              Text('Yeni Sohbet', style: AppTextStyles.h3),
              Text(
                'Kişi Seçin',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: FriendsList(
          onFriendSelected: (friend) {
            // "Replace" so that back button in ChatPage goes back to MessagesPage, not this picker
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  otherUserId: friend.userId,
                  username: friend.username,
                  firstName: friend.firstName,
                  lastName: friend.lastName,
                  profileImageUrl: friend.profilePictureUrl,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
