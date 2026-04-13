import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/profile/presentation/widgets/tabs/about/about_section.dart';
import 'package:helmove/features/profile/presentation/widgets/tabs/about/bike_card_widget.dart';
import 'package:helmove/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';

class ProfileAboutTab extends StatefulWidget {
  final bool isOwnProfile;
  final int? viewedUserId;

  const ProfileAboutTab({
    super.key,
    required this.isOwnProfile,
    required this.viewedUserId,
  });

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
    // Sadece kendi profilimde /me/motorcycles endpoint'ini çağır.
    if (widget.isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProfileProvider>().loadMotorcycles();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileAboutTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isOwnProfile && widget.isOwnProfile) {
      context.read<ProfileProvider>().loadMotorcycles();
    }

    if (!widget.isOwnProfile && _isAddingNew) {
      setState(() {
        _isAddingNew = false;
      });
    }
  }

  // Yeni motor ekleme fonksiyonu
  void _addNewBike() {
    if (!widget.isOwnProfile) return;
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
    final l10n = AppLocalizations.of(context)!;

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
              // 1. BÖLÜM: Hakkında Yazısı
              AboutSection(isOwnProfile: widget.isOwnProfile),

              const SizedBox(height: 40),
              Divider(color: theme.dividerColor.withValues(alpha:0.5)),
              const SizedBox(height: 20),

              // 2. BÖLÜM: Garaj Başlığı
              Center(
                child: Text(
                  l10n.myGarage,
                  style: AppTextStyles.h3.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. BÖLÜM: Motor Kartları Listesi
              Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  final bikes = widget.isOwnProfile
                      ? provider.motorcycles
                      : (provider.visitedProfile?.motorcycles ??
                            const <MotorcycleEntity>[]);

                  if (provider.isLoading &&
                      widget.isOwnProfile &&
                      bikes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Varsa Listelenen Motorlar
                      ...bikes.map((bike) {
                        return BikeCardWidget(
                          key: ValueKey(bike.id ?? bike.hashCode),
                          bike: bike,
                          readOnly: !widget.isOwnProfile,
                          // Var olan motor silinince provider'dan sil
                          onDelete: () {}, // BikeCard içinde yönetiliyor
                        );
                      }),

                      // Yeni Eklenen (Henüz kaydedilmemiş) Boş Kart
                      if (_isAddingNew && widget.isOwnProfile)
                        BikeCardWidget(
                          key: const ValueKey("new_bike"),
                          bike: const MotorcycleEntity(brand: "", model: ""),
                          initialEdit: true,
                          onDelete: _cancelAddNew,
                          onSave:
                              _cancelAddNew, // 🔥 Kayıt başarılı olunca da kapat (çünkü liste yenilendi)
                        ),

                      if (bikes.isEmpty && !_isAddingNew)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            widget.isOwnProfile
                                ? l10n.noBikesYet
                                : l10n.userGarageEmpty,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 4. BÖLÜM: Motor Ekleme Butonu (sadece kendi profilimde)
              if (widget.isOwnProfile)
                Center(
                  child: SizedBox(
                    width: 160,
                    child: ElevatedButton.icon(
                      onPressed: _addNewBike,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addBike),
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
