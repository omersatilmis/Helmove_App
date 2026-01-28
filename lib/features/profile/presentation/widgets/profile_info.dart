import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/profile/presentation/pages/edit_profile.dart';
import 'package:moto_comm_app_1/features/friendship/domain/entities/friendship_status.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_state.dart';

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
    this.onSendRequest,
    this.onCancelRequest,
    this.onAcceptRequest,
    this.onRejectRequest,
    this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onSendRequest: onSendRequest,
          onCancelRequest: onCancelRequest,
          onAcceptRequest: onAcceptRequest,
          onRejectRequest: onRejectRequest,
          onRemoveFriend: onRemoveFriend,
        ),
      ],
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
          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
          _StatItem("256790", "Rating", onTap: onRatingTap),
          _StatItem(friendCount, "Friends", onTap: onFriendsTap),
          _StatItem("1.5K", "Followers", onTap: onFollowersTap),
          _StatItem("1.2K", "Following", onTap: onFollowingTap),
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
            ? _buildOwnProfileButtons(context) // ✅ Kendi Profilimiz
            : _buildOtherProfileButtons(context), // ❌ Başkasının Profili
      ),
    );
  }

  // --- KENDİ PROFİLİMİZ İSE GÖRÜNECEKLER (GÜNCELLENDİ) ---
  List<Widget> _buildOwnProfileButtons(BuildContext context) {
    final theme = Theme.of(context);
    const orangeColor = Colors.deepOrange;

    return [
      // 1. Profili Düzenle
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

      // 2. İçerik Ekle
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text(
            "İçerik Ekle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: orangeColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: orangeColor, width: 1.5),
            overlayColor: orangeColor.withValues(alpha: 0.1),
          ),
        ),
      ),
    ];
  }

  // --- BAŞKASININ PROFİLİ İSE GÖRÜNECEKLER (GÜNCELLENDİ) ---
  List<Widget> _buildOtherProfileButtons(BuildContext context) {
    final theme = Theme.of(context);
    // Düğme yapısı duruma göre değişecek

    Widget mainActionBtn;
    // İkincil aksiyon (Mesaj) genellikle sabit kalır veya duruma göre değişebilir.

    if (friendshipStatus == null || friendshipStatus == FriendshipStatus.none) {
      // Arkadaş Ekle
      mainActionBtn = ElevatedButton.icon(
        onPressed: onSendRequest,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text(
          "Arkadaş Ekle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    } else if (friendshipStatus == FriendshipStatus.accepted) {
      // Arkadaşsınız (Belki Çıkar butonu veya sadece 'Arkadaş' etiketi + menü)
      // Burada 'Arkadaş' yazıp tıklayınca menü açılan bir logic kurulabilir,
      // şimdilik 'Arkadaş' butonu yapalım.
      mainActionBtn = OutlinedButton.icon(
        onPressed: () {
          // Basit bir sheet açıp çıkar diyelim
          showModalBottomSheet(
            context: context,
            builder: (c) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_remove,
                        color: Colors.red,
                      ),
                      title: const Text(
                        "Arkadaşlıktan Çıkar",
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(c);
                        if (onRemoveFriend != null) onRemoveFriend!();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.check, size: 20, color: Colors.green),
        label: const Text(
          "Arkadaşsınız",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    } else if (friendshipStatus == FriendshipStatus.pending) {
      if (friendRequestType == FriendRequestType.sent) {
        // İstek Gönderildi -> İptal butonu devre dışı (backend endpoint yok)
        mainActionBtn = OutlinedButton.icon(
          onPressed:
              null, // Backend endpoint eklenince onCancelRequest kullanılacak
          icon: const Icon(Icons.access_time, size: 20),
          label: const Text(
            "İstek Gönderildi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      } else {
        // İstek Geldi -> Kabul / Red
        // Bu durumda yer darlığı olabilir, Expanded yerine Row içinde sığdırmalıyız.
        // Tek buton yerine Kabul butonunu ana buton yapalım, Reddet'i yanda ikon yapabiliriz.
        return [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAcceptRequest,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                "Kabul Et",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onRejectRequest,
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: "Reddet",
            ),
          ),
          const SizedBox(width: 12),
          // Mesaj İkonu
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onMessageTap,
              icon: const Icon(Icons.mail_outline_rounded),
              tooltip: "Mesaj",
            ),
          ),
        ];
      }
    } else {
      // Blocked veya bilinmeyen
      mainActionBtn = ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.block, size: 20),
        label: const Text("Engelli"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
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

      // 2. Mesaj Gönder (Standart)
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onMessageTap,
          icon: const Icon(Icons.mail_outline_rounded, size: 20),
          label: const Text(
            "Mesaj",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    ];
  }
}
