import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/plan/presentation/widgets/plan_model.dart';

class PremiumPlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onBuyTap;

  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    this.isActive = false,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // Kart arka planı: Helmove estetiği için Dark modda derinlik kazandırıldı
        color: isDark
            ? const Color(0xFF1E1E1E)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: plan.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: isSelected
            ? Border.all(color: plan.gradientColors.first, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // -----------------------------------------------------------
          // 1. KART BAŞLIĞI (Gradiyent Alan)
          // -----------------------------------------------------------
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              gradient: LinearGradient(
                colors: plan.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  plan.title, // Burası "Helmove Pro Access" veya "Helmove Plus Access" gelecek
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.price,
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      plan.period,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // 2. ÖZELLİKLER LİSTESİ
          // -----------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...plan.features.map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  // Şık Tik Kutusu
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: plan.gradientColors.first
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: plan.gradientColors.first,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Özellik Metni (Dark/Light Uyumlu)
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: AppTextStyles.regular.copyWith(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF212121),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // 3. SATIN AL BUTONU (Tetikleyici) VEYA AKTİF DURUMU
                  // -----------------------------------------------------------
                  SizedBox(
                     width: double.infinity,
                     height: 54,
                     child: isActive 
                        ? Container(
                           decoration: BoxDecoration(
                             color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                             borderRadius: BorderRadius.circular(27),
                             border: Border.all(
                               color: plan.gradientColors.first.withValues(alpha: 0.5),
                               width: 1,
                             ),
                           ),
                           alignment: Alignment.center,
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(
                                 Icons.check_circle_rounded,
                                 color: plan.gradientColors.first,
                                 size: 20,
                               ),
                               const SizedBox(width: 8),
                               Text(
                                 "Mevcut Planınız",
                                 style: AppTextStyles.button.copyWith(
                                   fontSize: 16,
                                   color: isDark ? Colors.white70 : Colors.black87,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ],
                           ),
                         )
                        : ElevatedButton(
                             onPressed: onBuyTap,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.transparent,
                               shadowColor: Colors.transparent,
                               padding: EdgeInsets.zero,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(27),
                               ),
                             ),
                             child: Ink(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(colors: plan.gradientColors),
                                 borderRadius: BorderRadius.circular(27),
                               ),
                               child: Container(
                                 alignment: Alignment.center,
                                 child: Text(
                                   "HEMEN BAŞLA",
                                   style: AppTextStyles.button.copyWith(
                                     fontSize: 16,
                                     color: Colors.white,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                             ),
                           ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
