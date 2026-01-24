import 'package:flutter/material.dart';

class ProfileTaggedTab extends StatelessWidget {
  const ProfileTaggedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      key: const PageStorageKey('tagged_tab'),
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
              childAspectRatio: 1.0, // Kare
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  // 🔥 SADECE GRİ KUTU
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                );
              },
              childCount: 12,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}