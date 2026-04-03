import 'package:flutter/material.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:package_info_plus/package_info_plus.dart';

class CopyrightPage extends StatefulWidget {
  const CopyrightPage({super.key});

  @override
  State<CopyrightPage> createState() => _CopyrightPageState();
}

class _CopyrightPageState extends State<CopyrightPage> {
  String _version = "";

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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          l10n.copyright,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            _buildLogo(isDark, l10n),
            const SizedBox(height: 32),

            _buildCopyrightText(currentYear, isDark, l10n),
            const SizedBox(height: 40),

            _buildWebsiteLink(isDark, l10n),

            _buildLegalSection(
              title: l10n.copyrightLegalNoticeTitle,
              content: l10n.copyrightLegalNoticeContent,
              isDark: isDark,
            ),

            _buildLegalSection(
              title: l10n.copyrightReverseEngineeringTitle,
              content: l10n.copyrightReverseEngineeringContent,
              isDark: isDark,
            ),

            _buildLegalSection(
              title: l10n.copyrightUsageRightsTitle,
              content: l10n.copyrightUsageRightsContent,
              isDark: isDark,
            ),

            _buildLegalSection(
              title: l10n.copyrightTrademarksTitle,
              content: l10n.copyrightTrademarksContent,
              isDark: isDark,
            ),

            const SizedBox(height: 40),
            _buildOpenSourceSection(isDark, l10n),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
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
          l10n.copyrightTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        if (_version.isNotEmpty)
          Text(
            l10n.version(l10n.releaseStageBeta, _version),
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

  Widget _buildCopyrightText(
    int year,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Text(
          l10n.copyrightHeader(year),
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
          l10n.copyrightAllRightsReserved,
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

  Widget _buildOpenSourceSection(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.copyrightOpenSourceTitle,
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
            l10n.copyrightOpenSourceDescription,
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
  Widget _buildWebsiteLink(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.supportVisitWebsite,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            context.push(
              '/webview',
              extra: {
                'url': 'https://helmove.com/terms-of-use',
                'title': l10n.copyright,
              },
            );
          },
          child: Text(
            l10n.copyright,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
