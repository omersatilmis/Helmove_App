import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';
import 'package:flutter_application_1/features/plan/widgets/plan_model.dart';

class PremiumPlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final VoidCallback onBuyTap;

  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 🔥 KESİN ÇÖZÜM: Ekranın modu ne?
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // Kart rengi: Dark ise Koyu Gri, Light ise Beyazımsı
        color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer, 
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
          // 1. KART BAŞLIĞI (Değişmedi - Zaten Beyaz)
          // -----------------------------------------------------------
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  plan.title,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.price,
                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32),
                    ),
                    Text(
                      plan.period,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // 2. ÖZELLİKLER LİSTESİ (MANUEL RENK AYARI)
          // -----------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ...plan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            // Tik Kutusu
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: plan.gradientColors.first.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, size: 16, color: plan.gradientColors.first),
                            ),
                            const SizedBox(width: 12),
                            
                            // Özellik Metni
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTextStyles.regular.copyWith(
                                  // 🔥 BURASI ARTIK KESİN ÇALIŞACAK:
                                  // Temayı beklemiyoruz, direkt isDark kontrolü yapıyoruz.
                                  color: isDark ? Colors.white : const Color(0xFF212121),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const Spacer(),

                  // -----------------------------------------------------------
                  // 3. SATIN AL BUTONU
                  // -----------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onBuyTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
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