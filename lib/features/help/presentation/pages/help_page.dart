import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/l10n/app_localizations.dart';

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
                    AppLocalizations.of(context)!.helpAndSupport,
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
                          _buildSectionTitle(AppLocalizations.of(context)!.categories, isDark),
                          const SizedBox(height: 16),
                          _buildCategoryGrid(isDark),
                          const SizedBox(height: 32),
                          _buildSectionTitle(AppLocalizations.of(context)!.faq, isDark),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.howCanWeHelp,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          AppInputField(
            controller: _searchController,
            type: AppInputType.discover,
            hint: l10n.searchYourProblem,
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
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      {'icon': Icons.settings_voice_rounded, 'title': l10n.intercom},
      {'icon': Icons.group_work_rounded, 'title': l10n.groupRide},
      {'icon': Icons.map_rounded, 'title': l10n.map},
      {'icon': Icons.person_rounded, 'title': l10n.account},
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
    final l10n = AppLocalizations.of(context)!;
    final faqs = [
      {
        'q': l10n.faqQuestion1,
        'a': l10n.faqAnswer1,
      },
      {
        'q': l10n.faqQuestion2,
        'a': l10n.faqAnswer2,
      },
      {
        'q': l10n.faqQuestion3,
        'a': l10n.faqAnswer3,
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
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => context.push('/feedback'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                children: [
                  Text(
                    l10n.solutionNotFound,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    l10n.contactSupport,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
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
      ),
    );
  }
}
