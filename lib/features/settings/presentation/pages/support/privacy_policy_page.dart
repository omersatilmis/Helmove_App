import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema kontrolü (Dark/Light)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          "Gizlilik Politikası",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLastUpdated(isDark),
            const SizedBox(height: 24),

            _buildSection(
              title: "1. Giriş",
              content:
                  "Helmove olarak gizliliğinize önem veriyoruz. Bu gizlilik politikası, uygulamamızı kullandığınızda verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu açıklar.",
              isDark: isDark,
            ),

            _buildSection(
              title: "2. Toplanan Veriler",
              content:
                  "Uygulamamızı kullanırken aşağıdaki verileri toplayabiliriz:\n\n"
                  "• Profil Bilgileri: Adınız, e-posta adresiniz ve profil fotoğrafınız.\n"
                  "• Konum Verileri: Grup sürüşlerinde diğer sürücülerle konumunuzu paylaşabilmeniz için (Hayalet Mod kapalıyken).\n"
                  "• Medya: Paylaştığınız gönderiler, 'jot'lar ve fotoğraflar.\n"
                  "• Cihaz Bilgileri: Uygulama performansı ve hata takibi için gerekli teknik veriler.",
              isDark: isDark,
            ),

            _buildSection(
              title: "3. Veri Kullanımı",
              content:
                  "Topladığımız verileri şu amaçlarla kullanıyoruz:\n\n"
                  "• İletişim özelliklerini (Sesli oturumlar, mesajlaşma) sağlamak.\n"
                  "• Sürüş güvenliği ve grup koordinasyonunu artırmak.\n"
                  "• Uygulama deneyimini kişiselleştirmek ve iyileştirmek.\n"
                  "• Teknik sorunları gidermek ve güvenliği sağlamak.",
              isDark: isDark,
            ),

            _buildSection(
              title: "4. Veri Paylaşımı",
              content:
                  "Verileriniz, yasal zorunluluklar haricinde üçüncü şahıslarla reklam amaçlı paylaşılmaz. Sesli iletişim için LiveKit gibi altyapı sağlayıcıları kullanılırken sadece gerekli teknik kimlikler paylaşılır.",
              isDark: isDark,
            ),

            _buildSection(
              title: "5. Haklarınız",
              content:
                  "Dilediğiniz zaman profilinizi düzenleyebilir, verilerinize erişebilir veya hesabınızı silerek tüm kişisel verilerinizin kaldırılmasını talep edebilirsiniz. Gizlilik ayarlarından konum paylaşımınızı her an kapatabilirsiniz.",
              isDark: isDark,
            ),

            _buildSection(
              title: "6. İletişim",
              content:
                  "Gizlilik politikamız hakkında sorularınız için destek@Helmove.app adresinden bize ulaşabilirsiniz.",
              isDark: isDark,
            ),

            const SizedBox(height: 40),
            _buildBottomBanner(isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.update_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            "Son Güncelleme: 6 Mart 2026",
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner(bool isDark) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              "Helmove Güvenli Sürüş Platformu",
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
