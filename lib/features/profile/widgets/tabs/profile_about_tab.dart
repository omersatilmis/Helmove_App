import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';
import 'package:flutter_application_1/features/profile/widgets/tabs/about/about_section.dart';
import 'package:flutter_application_1/features/profile/widgets/tabs/about/bike_card_widget.dart';
import 'package:flutter_application_1/features/profile/widgets/tabs/about/bike_model.dart';



class ProfileAboutTab extends StatefulWidget {
  const ProfileAboutTab({super.key});

  @override
  State<ProfileAboutTab> createState() => _ProfileAboutTabState();
}

class _ProfileAboutTabState extends State<ProfileAboutTab> {
  // 🔥 Motorların tutulduğu ana liste burada kalmalı
  final List<BikeModel> _myBikes = [];

  // Yeni motor ekleme fonksiyonu
  void _addNewBike() {
    setState(() {
      _myBikes.add(
        BikeModel(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
    });
  }

  // Listeden motor silme fonksiyonu
  void _removeBike(String id) {
    setState(() {
      _myBikes.removeWhere((bike) => bike.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      key: const PageStorageKey('about_tab'),
      slivers: [
        // Header çakışmasını önleyen zımbırtı
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. BÖLÜM: Hakkında Yazısı (Kendi dosyasından geliyor)
              const AboutSection(),

              const SizedBox(height: 40),
              Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
              const SizedBox(height: 20),

              // 2. BÖLÜM: Garaj Başlığı
              Center(
                child: Text(
                  "My Garage",
                  style: AppTextStyles.h3.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 16),

              // 3. BÖLÜM: Motor Kartları Listesi
              // Spread operatörü (...) ile listeyi buraya dağıtıyoruz
              ..._myBikes.map((bike) {
                return BikeCardWidget(
                  key: ValueKey(bike.id),
                  bike: bike,
                  // Eğer marka model boşsa (yeni eklenmişse) edit modunda başlasın
                  initialEdit: bike.makeModel.isEmpty,
                  onDelete: () => _removeBike(bike.id),
                );
              }),

              const SizedBox(height: 20),

              // 4. BÖLÜM: Motor Ekleme Butonu
              Center(
                child: SizedBox(
                  width: 160,
                  child: ElevatedButton.icon(
                    onPressed: _addNewBike,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Motor Ekle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              // Alt boşluk (Navigasyon barın altında kalmasın diye)
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}