import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:go_router/go_router.dart';

// 🔥 BUTON IMPORT
import 'package:moto_comm_app_1/core/widgets/app_frosted_button.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------------------------------------------------
            // 1. ÖZEL BAŞLIK ALANI (HEADER)
            // ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👈 SOL: Frosted Button (Size 44)
                  AppFrostedButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),

                  // ORTA: Başlık
                  Text(
                    "Yardım & Destek",
                    style: AppTextStyles.h3.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                    ),
                  ),

                  // SAĞ: Dengelemek için boşluk (44px)
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // 2. SAYFA İÇERİĞİ
            // ---------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchHeader(isDark),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Kategoriler", isDark),
                          const SizedBox(height: 16),
                          _buildCategoryGrid(isDark),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Sıkça Sorulan Sorular", isDark),
                          const SizedBox(height: 16),
                          _buildFAQList(isDark),
                          const SizedBox(height: 40),
                          _buildSupportBanner(isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Nasıl yardımcı olabiliriz?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          AppInputField(
            controller: _searchController,
            type: AppInputType.discover,
            hint: "Sorununuzu arayın...",
            radius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    final categories = [
      {'icon': Icons.settings_voice_rounded, 'title': 'İnterkom'},
      {'icon': Icons.group_work_rounded, 'title': 'Grup Sürüşü'},
      {'icon': Icons.map_rounded, 'title': 'Harita'},
      {'icon': Icons.person_rounded, 'title': 'Hesap'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat['icon'] as IconData, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                cat['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQList(bool isDark) {
    final faqs = [
      {
        'q': 'Grup sürüşüne nasıl katılırım?',
        'a':
            'İletişim sekmesinden arkadaşınızın paylaştığı oda kodunu girerek veya daveti kabul ederek katılabilirsiniz.',
      },
      {
        'q': 'Hayalet Mod nedir?',
        'a':
            'Hayalet Mod açıkken konumunuz haritada diğer kullanıcılara görünmez, ancak siz yine de uygulamayı kullanabilirsiniz.',
      },
      {
        'q': 'Ses gecikmesini nasıl önlerim?',
        'a':
            'İnternet bağlantınızı kontrol edin. LiveKit altyapısı sayesinde gecikme minimize edilmiştir, ancak düşük sinyal etkileyebilir.',
      },
    ];

    return Column(
      children: faqs
          .map((faq) => _buildFAQItem(faq['q']!, faq['a']!, isDark))
          .toList(),
    );
  }

  Widget _buildFAQItem(String q, String a, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          q,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            a,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Çözüm bulamadınız mı?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Destek ekibimizle iletişime geçin.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}
