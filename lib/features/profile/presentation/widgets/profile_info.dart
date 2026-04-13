import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:helmove/features/profile/presentation/pages/edit_profile.dart';
import 'package:helmove/features/friendship/domain/entities/friendship_status.dart';
import 'package:helmove/features/friendship/presentation/bloc/status/friendship_status_state.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/enums/user_tier.dart';
import 'package:image_picker/image_picker.dart';

class ProfileInfo extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String? bio;
  final String? profileImageUrl;

  // 🔥 YENİ: Bu profil oturum açan kişiye mi ait?
  final bool isOwnProfile;

  // 🔥 YENİ: İstatistik verileri ve callback'ler
  final String? friendCount;
  final String? followerCount;
  final String? followingCount;
  final String? ratingPoints;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onMessageTap;

  // 🔥 YENİ: Takip durumu ve callback'ler
  final bool isFollowing;
  final bool isFollower;
  final bool isFollowActionLoading;
  final UserTier tier;
  final VoidCallback? onFollowTap;
  final VoidCallback? onUnfollowTap;


  // 🔥 FRIENDSHIP ACTIONS
  final FriendshipStatus? friendshipStatus;
  final FriendRequestType? friendRequestType;
  final bool isLoadingStatus;
  final VoidCallback? onSendRequest;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onRejectRequest;
  final VoidCallback? onRemoveFriend;

  const ProfileInfo({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.isOwnProfile = false, // Varsayılan olarak başkası
    this.friendCount,
    this.followerCount,
    this.followingCount,
    this.ratingPoints,
    this.onFriendsTap,
    this.onRatingTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onMessageTap,
    this.friendshipStatus,
    this.friendRequestType,
    this.isLoadingStatus = false,
    this.onSendRequest,
    this.onCancelRequest,
    this.onAcceptRequest,
    this.onRejectRequest,
    this.onRemoveFriend,
    this.isFollowing = false,
    this.isFollower = false,
    this.isFollowActionLoading = false,
    this.tier = UserTier.free,
    this.onFollowTap,
    this.onUnfollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          _ProfileHeaderSection(profileImageUrl: profileImageUrl),

          _NameSection(
            firstName: firstName,
            lastName: lastName,
            username: username,
            tier: tier,
          ),

          // Bio bölümü (varsa göster)
          if (bio != null && bio!.isNotEmpty) _BioSection(bio: bio!),

          _StatsSection(
            friendCount: friendCount ?? "0",
            followerCount: followerCount ?? "0",
            followingCount: followingCount ?? "0",
            ratingPoints: ratingPoints ?? "0",
            onFriendsTap: onFriendsTap,
            onRatingTap: onRatingTap,
            onFollowersTap: onFollowersTap,
            onFollowingTap: onFollowingTap,
          ),

          // 🔥 Durumu alt widget'a iletiyoruz
          _ActionButtonsSection(
            isOwnProfile: isOwnProfile,
            onMessageTap: onMessageTap,
            friendshipStatus: friendshipStatus,
            friendRequestType: friendRequestType,
            isLoadingStatus: isLoadingStatus,
            onSendRequest: onSendRequest,
            onCancelRequest: onCancelRequest,
            onAcceptRequest: onAcceptRequest,
            onRejectRequest: onRejectRequest,
            onRemoveFriend: onRemoveFriend,
            isFollowing: isFollowing,
            isFollower: isFollower,
            isFollowActionLoading: isFollowActionLoading,
            onFollowTap: onFollowTap,
            onUnfollowTap: onUnfollowTap,
          ),
        ],
      ),
    );
  }
}

class _AddContentItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddContentItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  final String? profileImageUrl;

  const _ProfileHeaderSection({this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.65, 1],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/profile_bg_photo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundImage: () {
                  final url = profileImageUrl?.toAbsoluteImageUrl();
                  if (url != null && url.isNotEmpty) {
                    return CachedNetworkImageProvider(url) as ImageProvider;
                  }
                  return const AssetImage('assets/icons/ic_profile.png')
                      as ImageProvider;
                }(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bio Section Widget
class _BioSection extends StatelessWidget {
  final String bio;

  const _BioSection({required this.bio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        bio,
        textAlign: TextAlign.center,
        style: AppTextStyles.medium.copyWith(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withValues(alpha:0.7),
        ),
      ),
    );
  }
}

class _NameSection extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final UserTier tier;

  const _NameSection({
    required this.firstName,
    required this.lastName,
    required this.username,
    this.tier = UserTier.free,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 30),

        // 1. İsim Soyisim Birleşimi
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$firstName $lastName",
              style: AppTextStyles.h2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (tier != UserTier.free) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.verified_rounded,
                color: tier == UserTier.plus ? AppColors.primary : Colors.amber,
                size: 22,
              ),
            ],
          ],
        ),

        const SizedBox(height: 2),

        // 2. Kullanıcı Adı (@ işareti ile)
        Text(
          "@$username", // 👈 Dinamik Veri
          style: AppTextStyles.medium.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String friendCount;
  final String followerCount;
  final String followingCount;
  final String ratingPoints;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const _StatsSection({
    required this.friendCount,
    required this.followerCount,
    required this.followingCount,
    required this.ratingPoints,
    this.onFriendsTap,
    this.onRatingTap,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (AppFeatureFlags.showRatingsSection)
            _StatItem(ratingPoints, AppLocalizations.of(context)!.rating, onTap: onRatingTap),
          _StatItem(friendCount, AppLocalizations.of(context)!.friends, onTap: onFriendsTap),
          _StatItem(followerCount, AppLocalizations.of(context)!.followers, onTap: onFollowersTap),
          _StatItem(followingCount, AppLocalizations.of(context)!.following, onTap: onFollowingTap),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem(this.count, this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ActionButtonsSection extends StatelessWidget {
  final bool isOwnProfile;
  final bool isLoadingStatus;
  final VoidCallback? onMessageTap;
  final FriendshipStatus? friendshipStatus;
  final FriendRequestType? friendRequestType;
  final VoidCallback? onSendRequest;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onRejectRequest;
  final VoidCallback? onRemoveFriend;

  // 🔥 YENİ
  final bool isFollowing;
  final bool isFollower;
  final bool isFollowActionLoading;
  final VoidCallback? onFollowTap;
  final VoidCallback? onUnfollowTap;

  const _ActionButtonsSection({
    required this.isOwnProfile,
    this.isLoadingStatus = false,
    this.onMessageTap,
    this.friendshipStatus,
    this.friendRequestType,
    this.onSendRequest,
    this.onCancelRequest,
    this.onAcceptRequest,
    this.onRejectRequest,
    this.onRemoveFriend,
    this.isFollowing = false,
    this.isFollower = false,
    this.isFollowActionLoading = false,
    this.onFollowTap,
    this.onUnfollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      children: isOwnProfile
          ? _buildOwnProfileButtons(context)
          : _buildOtherProfileButtons(context),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 1),
      child: isOwnProfile ||
              !isFollower ||
              !AppFeatureFlags.showProfileFollowInfo
          ? buttons
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seni takip ediyor",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                buttons,
              ],
            ),
    );
  }

  List<Widget> _buildOwnProfileButtons(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
          },
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: Text(
            AppLocalizations.of(context)!.edit,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showAddContentSheet(context),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: Text(
            AppLocalizations.of(context)!.addContent,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
    ];
  }

  void _showAddContentSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppLocalizations.of(context)!.createNewContent,
                  style: AppTextStyles.h3.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              _AddContentItem(
                icon: Icons.image_outlined,
                title: AppLocalizations.of(context)!.postType,
                subtitle: AppLocalizations.of(context)!.sharePhotoOrVideo,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddPostSourceSheet(context);
                },
              ),
              const SizedBox(height: 8),
              _AddContentItem(
                icon: Icons.edit_note_rounded,
                title: AppLocalizations.of(context)!.jotType,
                subtitle: AppLocalizations.of(context)!.shareShortTextOrThought,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/create_jots');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddPostSourceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (l10n == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.createPost,
                  style: AppTextStyles.h3.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              _AddContentItem(
                icon: Icons.photo_camera_rounded,
                title: l10n.shareSheetCameraTitle,
                subtitle: l10n.shareSheetCameraSubtitle,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/add_post');
                },
              ),
              const SizedBox(height: 8),
              _AddContentItem(
                icon: Icons.photo_library_rounded,
                title: l10n.shareSheetGalleryTitle,
                subtitle: l10n.shareSheetGallerySubtitle,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickFromGalleryAndOpenPrepareMedia(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGalleryAndOpenPrepareMedia(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) return;

      final file = File(image.path);
      if (!file.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.image_upload_error)),
          );
        }
        return;
      }

      if (context.mounted) {
        context.push('/prepare_media', extra: file);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.image_upload_error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Widget> _buildOtherProfileButtons(BuildContext context) {
    if (isLoadingStatus) {
      return [
        Expanded(
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const SizedBox(width: 44), // Mesaj butonu alanı kadar boşluk
      ];
    }

    Widget mainActionBtn;
    final status = friendshipStatus ?? FriendshipStatus.none;

    if (status == FriendshipStatus.accepted) {
      // Arkadaşsınız (Turuncu Outlined)
      mainActionBtn = OutlinedButton.icon(
        onPressed: () => _showRemoveFriendAction(context),
        icon: const Icon(
          Icons.person_outline_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        label: Text(
          AppLocalizations.of(context)!.youAreFriends,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          overlayColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      );
    } else if (status == FriendshipStatus.pending) {
      if (friendRequestType == FriendRequestType.received) {
        // Gelen İstek: Onayla ve Reddet
        return [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAcceptRequest,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.confirm,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRejectRequest,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                AppLocalizations.of(context)!.reject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildMessageIconButton(),
        ];
      } else {
        // Giden İstek: Gönderildi (İptal edilebilir)
        mainActionBtn = OutlinedButton.icon(
          onPressed: onCancelRequest,
          icon: const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Colors.grey,
          ),
          label: Text(
            AppLocalizations.of(context)!.sentStatus,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.grey, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    } else {
      // Arkadaş Ekle (Turuncu Dolu)
      mainActionBtn = ElevatedButton.icon(
        onPressed: onSendRequest,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          AppLocalizations.of(context)!.addFriend,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }

    // TAKİP ET BUTONU (Outlined Turuncu)
    final followBtn = isFollowing
        ? OutlinedButton(
            onPressed: isFollowActionLoading ? null : onUnfollowTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: isFollowActionLoading ? Colors.grey : AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              foregroundColor: isFollowActionLoading ? Colors.grey : AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: isFollowActionLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.followingStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  )
                : Text(
                    AppLocalizations.of(context)!.followingStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          )
        : ElevatedButton(
            onPressed: isFollowActionLoading ? null : onFollowTap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: isFollowActionLoading ? Colors.grey.shade400 : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: isFollowActionLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.follow,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    AppLocalizations.of(context)!.follow,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
          );

    return [
      Expanded(flex: 3, child: mainActionBtn),
      const SizedBox(width: 8),
      Expanded(flex: 3, child: followBtn),
      const SizedBox(width: 8),
      _buildMessageIconButton(),
    ];
  }

  Widget _buildMessageIconButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMessageTap,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(
            Icons.mail_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showRemoveFriendAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  "Arkadaşlıktan Çıkar",
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(c);
                  if (onRemoveFriend != null) onRemoveFriend!();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
