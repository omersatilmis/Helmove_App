import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../utils/image_url_extensions.dart';

class AppAvatar extends StatelessWidget {
  final double radius;
  final String? overrideImageUrl;
  final int? userId;
  final bool isCurrentUser;

  const AppAvatar({
    super.key,
    this.radius = 20.0,
    this.overrideImageUrl,
    this.userId,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return _buildCurrentUserAvatar(context);
    }

    // Check if this avatar happens to be the current user
    final authProvider = context.read<AuthProvider>();
    if (userId != null && userId == authProvider.currentUser?.id) {
      return _buildCurrentUserAvatar(context);
    }

    return _buildAvatar(overrideImageUrl);
  }

  Widget _buildCurrentUserAvatar(BuildContext context) {
    // Listen to ProfileProvider to get the absolute latest profile picture immediately when it changes
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    final profileImageUrl =
        profileProvider.profileImageUrl ??
        authProvider.currentUser?.profileImageUrl;

    return _buildAvatar(profileImageUrl);
  }

  Widget _buildAvatar(String? imageUrl) {
    ImageProvider imageProvider;
    final absoluteUrl = imageUrl?.toAbsoluteImageUrl();
    if (absoluteUrl != null && absoluteUrl.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(
        absoluteUrl.toAvatarThumbnail(),
      );
    } else {
      imageProvider = const AssetImage('assets/icons/ic_profile.png');
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: imageProvider,
    );
  }
}
