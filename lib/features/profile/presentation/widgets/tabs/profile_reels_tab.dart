import 'package:flutter/material.dart';

class ProfileReelsTab extends StatefulWidget {
  const ProfileReelsTab({super.key});

  @override
  State<ProfileReelsTab> createState() => _ProfileReelsTabState();
}

class _ProfileReelsTabState extends State<ProfileReelsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 🔥 SAYFAYI CANLI TUT

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🔥 ŞART!
    final theme = Theme.of(context);

    return CustomScrollView(
      key: const PageStorageKey('reels_tab'),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.56, // 🔥 9:16 Dikdörtgen Formatı
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 🔥 ZEMİN: Gri Kutu (Resim yok)
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                  ),

                  // 🔥 ORTA: Play İkonu
                  Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                      size: 32,
                    ),
                  ),

                  // 🔥 ALT SOL: İzlenme Sayısı (Dümenden)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Text(
                      "12.4K",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }, childCount: 15),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
