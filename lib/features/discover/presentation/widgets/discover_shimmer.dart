import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class DiscoverShimmer extends StatelessWidget {
  const DiscoverShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerLow
        : Colors.grey[300]!;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
        : Colors.grey[100]!;
    final containerColor = isDark
        ? theme.colorScheme.surface
        : Colors.grey[200]!;

    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      itemCount: 15,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        // Instagram tarzı: çoğu kare, bazıları uzun
        final double height;
        if (index % 10 == 0) {
          height = 260; // Her 10 item'da 1 büyük
        } else if (index % 5 == 0) {
          height = 200;
        } else {
          height = 130; // Çoğu kare-ish
        }

        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
