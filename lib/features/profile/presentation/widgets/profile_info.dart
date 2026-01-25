import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

class ProfileInfo extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;

  // 🔥 YENİ: Bu profil oturum açan kişiye mi ait?
  final bool isOwnProfile;

  const ProfileInfo({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.isOwnProfile = false, // Varsayılan olarak başkası
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ProfileHeaderSection(),

        _NameSection(
          firstName: firstName,
          lastName: lastName,
          username: username,
        ),

        const _StatsSection(),

        // 🔥 Durumu alt widget'a iletiyoruz
        _ActionButtonsSection(isOwnProfile: isOwnProfile),
      ],
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection();

  // ... (Header kodu aynen kalıyor, burayı ellemedim)
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
              child: const CircleAvatar(
                radius: 52,
                backgroundImage: AssetImage('assets/icons/ic_profile.png'),
              ),
            ),
          ),
        ],
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
  const _StatsSection();
  // ... (İstatistikler aynen kalıyor)
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem("256790", "Rating"),
          _StatItem("1.5K", "Followers"),
          _StatItem("1.2K", "Following"),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem(this.count, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  final bool isOwnProfile;

  const _ActionButtonsSection({required this.isOwnProfile});

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

    // Turuncu rengi tanımlayalım (Temaya göre ton seçebilirsin)
    // DeepOrange genellikle beyaz/siyah zeminlerde daha iyi okunur.
    const orangeColor = Colors.deepOrange;

    return [
      // 1. Profili Düzenle (ARTIK FILLED / DOLU)
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            // context.push('/edit-profile');
          },
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: const Text(
            "Düzenle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            // Temanın ana rengiyle dolu olsun
            backgroundColor: theme.colorScheme.primary,
            // Yazısı kontrast olsun (beyaz veya siyah)
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),

      // 2. İçerik Ekle (ARTIK OUTLINED / TURUNCU)
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            // İçerik ekleme modalı
          },
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text(
            "İçerik Ekle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            // Yazı ve İkon rengi Turuncu
            foregroundColor: orangeColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            // Çerçeve Rengi Turuncu
            side: const BorderSide(color: orangeColor, width: 1.5),
            // Tıklanınca çıkan efekt rengi (hafif turuncu)
            overlayColor: orangeColor.withValues(alpha: 0.1),
          ),
        ),
      ),
    ];
  }

  // --- BAŞKASININ PROFİLİ İSE GÖRÜNECEKLER (AYNI KALDI) ---
  List<Widget> _buildOtherProfileButtons(BuildContext context) {
    return [
      // 1. Takip Et
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          label: const Text(
            "Takip Et",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),

      // 2. Mesaj Gönder
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {},
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
