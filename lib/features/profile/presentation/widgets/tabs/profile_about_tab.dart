import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/profile/presentation/widgets/tabs/about/about_section.dart';
import 'package:helmove/features/profile/presentation/widgets/tabs/about/bike_card_widget.dart';
import 'package:helmove/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:provider/provider.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';

class ProfileAboutTab extends StatefulWidget {
  const ProfileAboutTab({super.key});

  @override
  State<ProfileAboutTab> createState() => _ProfileAboutTabState();
}

class _ProfileAboutTabState extends State<ProfileAboutTab>
    with AutomaticKeepAliveClientMixin {
  // 🔥 MIXIN EKLENDİ
  // Yeni motor ekleniyor mu? (Boş kart göstermek için)
  bool _isAddingNew = false;

  @override
  bool get wantKeepAlive => true; // 🔥 SAYFAYI CANLI TUT

  @override
  void initState() {
    super.initState();
    // Motorları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadMotorcycles();
    });
  }

  // Yeni motor ekleme fonksiyonu
  void _addNewBike() {
    setState(() {
      _isAddingNew = true;
    });
  }

  // Yeni ekleme iptal edilirse
  void _cancelAddNew() {
    setState(() {
      _isAddingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🔥 ŞART!
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
              Divider(color: theme.dividerColor.withValues(alpha:0.5)),
              const SizedBox(height: 20),

              // 2. BÖLÜM: Garaj Başlığı
              Center(
                child: Text(
                  "My Garage",
                  style: AppTextStyles.h3.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. BÖLÜM: Motor Kartları Listesi
              Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.motorcycles.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Varsa Listelenen Motorlar
                      ...provider.motorcycles.map((bike) {
                        return BikeCardWidget(
                          key: ValueKey(bike.id ?? bike.hashCode),
                          bike: bike,
                          // Var olan motor silinince provider'dan sil
                          onDelete: () {}, // BikeCard içinde yönetiliyor
                        );
                      }),

                      // Yeni Eklenen (Henüz kaydedilmemiş) Boş Kart
                      if (_isAddingNew)
                        BikeCardWidget(
                          key: const ValueKey("new_bike"),
                          bike: const MotorcycleEntity(brand: "", model: ""),
                          initialEdit: true,
                          onDelete: _cancelAddNew,
                          onSave:
                              _cancelAddNew, // 🔥 Kayıt başarılı olunca da kapat (çünkü liste yenilendi)
                        ),
                    ],
                  );
                },
              ),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
