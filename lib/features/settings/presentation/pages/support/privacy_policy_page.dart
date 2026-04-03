import 'package:flutter/material.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema kontrolü (Dark/Light)
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          l10n.privacyPolicy,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLastUpdated(isDark, l10n),

            _buildWebLink(context, isDark, l10n),
            const SizedBox(height: 24),

            _buildSection(
              title: l10n.privacySection1Title,
              content: l10n.privacySection1Content,
              isDark: isDark,
            ),

            _buildSection(
              title: l10n.privacySection2Title,
              content: l10n.privacySection2Content,
              isDark: isDark,
            ),

            _buildSection(
              title: l10n.privacySection3Title,
              content: l10n.privacySection3Content,
              isDark: isDark,
            ),

            _buildSection(
              title: l10n.privacySection4Title,
              content: l10n.privacySection4Content,
              isDark: isDark,
            ),

            _buildSection(
              title: l10n.privacySection5Title,
              content: l10n.privacySection5Content,
              isDark: isDark,
            ),

            _buildSection(
              title: l10n.privacySection6Title,
              content: l10n.privacySection6Content,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 40),
            _buildBottomBanner(isDark, l10n),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLink(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Text(
          l10n.supportVisitWebsite,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            context.push(
              '/webview',
              extra: {
                'url': 'https://helmove.com/privacy-policy',
                'title': l10n.privacyWebLinkText,
              },
            );
          },
          child: Text(
            l10n.privacyWebLinkText,
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

  Widget _buildLastUpdated(bool isDark, AppLocalizations l10n) {
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
            l10n.privacyLastUpdated,
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

  Widget _buildBottomBanner(bool isDark, AppLocalizations l10n) {
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
              l10n.privacyBottomBannerText,
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
