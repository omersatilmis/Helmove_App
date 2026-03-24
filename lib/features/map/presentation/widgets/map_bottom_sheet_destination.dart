import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../../../core/widgets/app_frosted_button.dart';
import '../../domain/entities/location_entity.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';

class MapBottomSheetDestination extends StatelessWidget {
  final LocationEntity location;
  final bool isLoading;
  final bool canRoute;
  final LocationEntity? startPoint;
  final LocationEntity? endPoint;
  final List<LocationEntity> stops;
  final bool isSelectionMode;

  const MapBottomSheetDestination({
    super.key,
    required this.location,
    this.isLoading = false,
    required this.canRoute,
    this.startPoint,
    this.endPoint,
    this.stops = const [],
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStartSelected = startPoint != null;
    final isEndSelected = endPoint != null;
    final subtitle =
        location.subtitle ??
        (location.context != null && location.context!.isNotEmpty
            ? location.context!.join(', ')
            : null) ??
        location.country;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                location.label,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                  fontSize: 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (!isSelectionMode ||
                location.label != 'Haritadan durak seçiniz') ...[
              _ActionIcon(
                icon: Icons.bookmark_border,
                tooltip: 'Kaydet',
                onTap: () {},
              ),
              const SizedBox(width: 6),
              _ActionIcon(
                icon: Icons.share_outlined,
                tooltip: 'Paylaş',
                onTap: _shareLocation,
              ),
              const SizedBox(width: 6),
              _ActionIcon(
                icon: Icons.close_rounded,
                tooltip: 'Kapat',
                onTap: () {
                  final bloc = context.read<MapBloc>();
                  bloc.add(MapSelectLocation(null));
                  if (isSelectionMode) {
                    bloc.add(MapToggleStopSelectionMode(false));
                  }
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (isLoading) ...[
          _buildSkeletonBar(theme, width: double.infinity, height: 16),
          const SizedBox(height: 6),
          _buildSkeletonBar(theme, width: 220, height: 16),
        ] else if (subtitle != null && subtitle.trim().isNotEmpty)
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 12),
        if (isSelectionMode)
          _buildSelectionButton(context, theme)
        else
          // --- 3 YAN YANA MODERN BUTON (Bitiş, Başlangıç, Yol Tarifi) ---
          Row(
            children: [
              Expanded(
                child: _PointActionButton(
                  onPressed: () {
                    context.read<MapBloc>().add(
                      MapPointSelectedFromMap(
                        point: location.point,
                        isStart: false,
                        label: location.label,
                      ),
                    );
                    context.read<MapBloc>().add(MapSelectLocation(null));
                  },
                  icon: Icons.flag_rounded,
                  label: 'Bitiş',
                  isSelected: isEndSelected,
                  filledColor: Colors.deepOrange.shade500, // Farklı Ton Turuncu
                  outlinedColor: Colors.orange.shade600,   // Outlined Turuncu
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PointActionButton(
                  onPressed: () {
                    context.read<MapBloc>().add(
                      MapPointSelectedFromMap(
                        point: location.point,
                        isStart: true,
                        label: location.label,
                      ),
                    );
                    context.read<MapBloc>().add(MapSelectLocation(null));
                  },
                  icon: Icons.my_location_rounded,
                  label: 'Başlangıç',
                  isSelected: isStartSelected,
                  filledColor: Colors.orange.shade600,     // Farklı Ton Turuncu
                  outlinedColor: Colors.orange.shade600,   // Outlined Turuncu
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppFrostedTextButton(
                  text: 'Yol Tarifi',
                  onPressed: canRoute
                      ? () => context.read<MapBloc>().add(MapRouteRequested())
                      : null,
                  height: 48,
                  fontSize: 12,
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  backgroundColor: canRoute
                      ? Colors.black
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.08,
                        ),
                  textColor: canRoute
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                  borderColor: canRoute
                      ? Colors.black
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.15,
                        ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Yol Tarifi'),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectionButton(BuildContext context, ThemeData theme) {
    final isAlreadyAdded = stops.any((stop) => _isSamePoint(stop, location));
    final isStartPoint =
        startPoint != null && _isSamePoint(startPoint!, location);
    final isEndPoint = endPoint != null && _isSamePoint(endPoint!, location);
    final isMarked = isAlreadyAdded || isStartPoint || isEndPoint;
    final isPlaceholder = location.label == 'Haritadan durak seçiniz';
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: AppFrostedTextButton(
            text: 'Geri',
            onPressed: () =>
                context.read<MapBloc>().add(MapToggleStopSelectionMode(false)),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            textColor: theme.colorScheme.onSurface,
            height: 48,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AppFrostedTextButton(
            text: isMarked ? 'Durak Seçildi' : 'Durak Seç',
            onPressed: (isMarked || isPlaceholder)
                ? null
                : () => context.read<MapBloc>().add(
                  MapAddStopRequested(location),
                ),
            backgroundColor: isMarked
                ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                : theme.colorScheme.primary,
            textColor: isMarked
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : theme.colorScheme.onPrimary,
            height: 48,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBar(
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  bool _isSamePoint(LocationEntity a, LocationEntity b) {
    return a.point.coordinates.lng == b.point.coordinates.lng &&
        a.point.coordinates.lat == b.point.coordinates.lat;
  }

  String _buildLocationShareLink() {
    final lat = location.point.coordinates.lat;
    final lng = location.point.coordinates.lng;
    final uri = Uri(
      scheme: 'helmove',
      host: 'share',
      path: 'location',
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'label': location.label,
      },
    );
    return uri.toString();
  }

  void _shareLocation() {
    final link = _buildLocationShareLink();
    share_plus.SharePlus.instance.share(
      share_plus.ShareParams(uri: Uri.parse(link)),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Tooltip(
        message: tooltip,
        child: AppFrostedButton(
          icon: icon,
          onTap: onTap,
          size: 34,
          iconSize: 18,
        ),
      ),
    );
  }
}

// --- RENK VE CAM MOTORU (Senin İstediğin Kurallara Göre) ---
class _PointActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color filledColor;
  final Color outlinedColor;

  const _PointActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.filledColor,
    required this.outlinedColor,
  });

  @override
  Widget build(BuildContext context) {
    // SEÇİLİYSE: Arka planı outlined (çerçeve) renginden beslenir ama saydamdır.
    // SEÇİLİ DEĞİLSE: Farklı ton turuncu renginden beslenir.
    final bgColor = isSelected ? outlinedColor : filledColor;
    
    // SEÇİLİYSE: İkon ve yazı Turuncu (Outlined)
    // SEÇİLİ DEĞİLSE: İkon ve yazı Bembeyaz (Filled)
    final itemColor = isSelected ? outlinedColor : Colors.white;

    return AppFrostedTextButton(
      text: label,
      onPressed: onPressed,
      height: 48,
      fontSize: 12,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: isSelected ? Colors.transparent : bgColor,
      textColor: itemColor,
      borderColor: isSelected ? outlinedColor : null,
      borderWidth: isSelected ? 1.4 : 1,
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}
