import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';

import 'package:package_info_plus/package_info_plus.dart';

class CopyrightPage extends StatefulWidget {
  const CopyrightPage({super.key});

  @override
  State<CopyrightPage> createState() => _CopyrightPageState();
}

class _CopyrightPageState extends State<CopyrightPage> {
  String _version = "";
  final String _appReleaseStage =
      "Beta"; // Geliştirme aşaması (Alfa, Beta vb.) için buradan değişiklik yapabilirsiniz.

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          "Telif Hakkı",
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
          children: [
            const SizedBox(height: 20),
            _buildLogo(isDark),
            const SizedBox(height: 32),

            _buildCopyrightText(currentYear, isDark),
            const SizedBox(height: 40),

            _buildLegalSection(
              title: "Yasal Uyarı",
              content:
                  "Helmove uygulaması içindeki tüm metinler, grafikler, logolar, buton ikonları, görseller ve yazılımlar Helmove'un mülkiyetindedir ve uluslararası telif hakkı yasalarıyla korunmaktadır.",
              isDark: isDark,
            ),

            _buildLegalSection(
              title: "Tersine Mühendislik Yasağı",
              content:
                  "Bu yazılımın ve içerdiği algoritmaların tersine mühendislik (reverse engineering) yoluyla çözülmesi, kaynak koduna dönüştürülmesi veya parçalarına ayrılması kesinlikle yasaktır. Bu tür girişimler fikri mülkiyet haklarının ihlali sayılacaktır.",
              isDark: isDark,
            ),

            _buildLegalSection(
              title: "Kullanım Hakları",
              content:
                  "Bu uygulama ve içeriği sadece kişisel kullanım içindir. Helmove'un önceden yazılı izni olmaksızın içeriğin kopyalanması, çoğaltılması, yeniden yayınlanması, yüklenmesi, iletilmesi veya dağıtılması yasaktır.",
              isDark: isDark,
            ),

            _buildLegalSection(
              title: "Ticari Markalar",
              content:
                  "Helmove logosu ve hizmet markaları, Helmove'un tescilli ticari markalarıdır. Diğer tüm markalar ilgili sahiplerine aittir.",
              isDark: isDark,
            ),

            const SizedBox(height: 40),
            _buildOpenSourceSection(isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.motorcycle_rounded,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Helmove",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          "Advanced Communication and Social Rider Ecosystem",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        if (_version.isNotEmpty)
          Text(
            "v$_version ($_appReleaseStage)",
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildCopyrightText(int year, bool isDark) {
    return Column(
      children: [
        Text(
          "© $year Helmove",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tüm Hakları Saklıdır.",
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSourceSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Açık Kaynak Lisansları",
          style: TextStyle(
            fontSize: 14,
            decoration: TextDecoration.underline,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Helmove, harika açık kaynaklı yazılımlar ve özgün mimari planlamalar kullanılarak geliştirilmiştir.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
