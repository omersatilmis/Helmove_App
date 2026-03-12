import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/profile/presentation/pages/edit_profile.dart';
import 'package:moto_comm_app_1/features/friendship/domain/entities/friendship_status.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_state.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

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
  final VoidCallback? onFriendsTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onMessageTap;

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
          ),

          // Bio bölümü (varsa göster)
          if (bio != null && bio!.isNotEmpty) _BioSection(bio: bio!),

          _StatsSection(
            friendCount: friendCount ?? "0",
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
                backgroundImage:
                    (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/icons/ic_profile.png')
                          as ImageProvider,
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

  const _NameSection({
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 30),

        // 1. İsim Soyisim Birleşimi
        Text(
          "$firstName $lastName", // 👈 Dinamik Veri
          style: AppTextStyles.h2.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
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
  final VoidCallback? onFriendsTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const _StatsSection({
    required this.friendCount,
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
          _StatItem("0", "Derece", onTap: onRatingTap),
          _StatItem(friendCount, "Arkadaşlar", onTap: onFriendsTap),
          _StatItem("0", "Takipçi", onTap: onFollowersTap),
          _StatItem("0", "Takip", onTap: onFollowingTap),
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 1),
      child: Row(
        children: isOwnProfile
            ? _buildOwnProfileButtons(context)
            : _buildOtherProfileButtons(context),
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
          label: const Text(
            "Düzenle",
            style: TextStyle(fontWeight: FontWeight.bold),
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
          label: const Text(
            "İçerik Ekle",
            style: TextStyle(fontWeight: FontWeight.bold),
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
      builder: (context) {
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
                  "Yeni İçerik Oluştur",
                  style: AppTextStyles.h3.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              _AddContentItem(
                icon: Icons.image_outlined,
                title: "Gönderi",
                subtitle: "Fotoğraf veya video paylaş",
                onTap: () {
                  context.pop();
                  context.push('/add_post');
                },
              ),
              const SizedBox(height: 8),
              _AddContentItem(
                icon: Icons.edit_note_rounded,
                title: "Jot",
                subtitle: "Kısa bir yazı veya düşünce paylaş",
                onTap: () {
                  context.pop();
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
        const Expanded(child: SizedBox()),
      ];
    }
    // ... rest of the content (collapsed for brevity in actual tool call)


    Widget mainActionBtn;
    final status = friendshipStatus ?? FriendshipStatus.none;

    if (status == FriendshipStatus.accepted) {
      // Arkadaşsınız (Turuncu Outlined)
      mainActionBtn = OutlinedButton.icon(
        onPressed: () => _showRemoveFriendAction(context),
        icon: const Icon(
          Icons.person_outline_rounded,
          size: 20,
          color: AppColors.primary,
        ),
        label: const Text(
          "Arkadaşsınız",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          overlayColor: AppColors.primary.withValues(alpha:0.1),
        ),
      );
    } else if (status == FriendshipStatus.pending) {
      if (friendRequestType == FriendRequestType.received) {
        // Gelen İstek: Onayla ve Reddet
        return [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAcceptRequest,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text(
                "Onayla",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRejectRequest,
              icon: const Icon(Icons.cancel_outlined, size: 20),
              label: const Text(
                "Reddet",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ];
      } else {
        // Giden İstek: Gönderildi (İptal edilebilir)
        mainActionBtn = OutlinedButton.icon(
          onPressed: onCancelRequest,
          icon: const Icon(
            Icons.access_time_rounded,
            size: 20,
            color: Colors.grey,
          ),
          label: const Text(
            "Gönderildi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.grey, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
          size: 20,
          color: Colors.white,
        ),
        label: const Text(
          "Arkadaş Ekle",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return [
      Expanded(child: mainActionBtn),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onMessageTap,
          icon: const Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          label: const Text(
            "Mesaj",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            overlayColor: AppColors.primary.withValues(alpha:0.1),
          ),
        ),
      ),
    ];
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
