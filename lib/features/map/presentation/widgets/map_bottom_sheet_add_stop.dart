import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/config/app_feature_flags.dart';
import '../providers/map_bloc.dart';
import '../providers/map_event.dart';
import 'poi_business_card.dart';
import 'map_bottom_sheet.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/widgets/glass_input_field.dart';

class MapBottomSheetAddStop extends StatefulWidget {
  final double? bottomBarHeight;

  const MapBottomSheetAddStop({
    super.key,
    this.bottomBarHeight,
  });

  @override
  State<MapBottomSheetAddStop> createState() => _MapBottomSheetAddStopState();
}

class _MapBottomSheetAddStopState extends State<MapBottomSheetAddStop> {
  int _selectedPoiIndex = 0;
  bool _isBusinessesExpanded = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static final List<({IconData icon, String label})> _poiTabs = [
    (icon: Icons.local_gas_station_rounded, label: 'Benzin'),
    (icon: Icons.coffee_rounded, label: 'Mola'),
    (icon: Icons.build_rounded, label: 'Servis'),
    (icon: Icons.shopping_bag_rounded, label: 'Ekipman'),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      final stateProvider = BottomSheetStateProvider.of(context);
      if (stateProvider != null && stateProvider.snapIndex != 2) {
        stateProvider.setSnapIndex(2);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final snapIndex = BottomSheetStateProvider.of(context)?.snapIndex ?? 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER: BAŞLIK VE HARİTADAN SEÇ ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Durak Ekle',
              style: AppTextStyles.h2.copyWith(
                color: colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
            InkWell(
              onTap: () {
                context.read<MapBloc>().add(MapToggleStopSelectionMode(true));
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Harita Üzerinden Seç',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- INPUT: DURAK ARAMA (GlassInputField) ---
        BlocBuilder<MapBloc, MapState>(
          buildWhen: (p, c) => p.lastQuery != c.lastQuery,
          builder: (context, state) {
            return GlassInputField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Durak ara...',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) {
                context.read<MapBloc>().add(
                  MapSearchQueryChanged(
                    query: value,
                    isStart: false,
                    isStop: true,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),

        // --- SUGGESTIONS OR POIS ---
        BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            final hasQuery = state.lastQuery.isNotEmpty && state.searchTargetIsStop;
            
            if (hasQuery) {
              return _buildSuggestionsList(context, state);
            }

            if (!AppFeatureFlags.showMapBusinesses) {
              return const SizedBox.shrink();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: snapIndex >= 1
                  ? Container(
                      key: const ValueKey('businesses_frame'),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                if (snapIndex >= 1) {
                                  setState(() {
                                    _isBusinessesExpanded = !_isBusinessesExpanded;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Text(
                                    'İşletmeler',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (snapIndex == 2)
                                    Icon(
                                      _isBusinessesExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 22,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Tablar (Yatay Kaydırılabilir)
                            SizedBox(
                              height: 32,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _poiTabs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final tab = _poiTabs[index];
                                  final isSelected = _selectedPoiIndex == index;
                                  return ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          tab.icon,
                                          size: 14,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(tab.label),
                                      ],
                                    ),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedPoiIndex = index);
                                      }
                                    },
                                    backgroundColor: colorScheme.surface,
                                    selectedColor: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    labelStyle: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant
                                              .withValues(alpha: 0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                },
                              ),
                            ),
                            // İşletme Kartları (AnimatedCrossFade ile genişleme)
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildBusinessList(context),
                              ),
                                crossFadeState: (snapIndex >= 1 && _isBusinessesExpanded)
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 220),
                              sizeCurve: Curves.easeOutCubic,
                            ),
                            if (snapIndex == 1) const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),

        // --- ACTIONS: GERİ DÖN (Mid ve Max durumunda görünür) ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: snapIndex >= 1
              ? Column(
                  key: const ValueKey('actions_section'),
                  children: [
                    const SizedBox(height: 24),
                    AppFrostedTextButton(
                      text: 'Geri Dön',
                      onPressed: () => context.read<MapBloc>().add(
                            MapAddStopViewToggled(false),
                          ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      backgroundColor: colorScheme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      textColor: colorScheme.onSurface,
                      height: 48,
                      fontSize: 14,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Geri Dön',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBusinessList(BuildContext context) {
    final items = _mockBusinessesForTab(_selectedPoiIndex);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return PoiBusinessCard(
          title: item.title,
          distance: item.distance,
          imageUrl: item.imageUrl,
          duration: item.duration ?? '',
          type: item.type ?? 'İşletme',
          rating: item.rating?.toString() ?? '0.0',
          reviewCount: item.reviewCount?.toString() ?? '0',
          isOpen: (item.isOpen ?? true) ? 'Açık' : 'Kapalı',
          address: item.address ?? '',
        );
      },
    );
  }

  List<_PoiBusinessMock> _mockBusinessesForTab(int index) {
    switch (index) {
      case 0:
        return const [
          _PoiBusinessMock(
            'Shell',
            '7/24 - 0.8 km',
            '0.8 km',
            duration: '2 dk',
            type: 'Istasyon',
            rating: 4.6,
            reviewCount: 120,
            isOpen: true,
            imageUrl: '',
          ),
          _PoiBusinessMock('BP', 'Rota üzeri - 2.1 km', '2.1 km', duration: '4 dk'),
          _PoiBusinessMock('Opet', 'İstasyon - 3.5 km', '3.5 km', duration: '6 dk'),
        ];
      case 1:
        return const [
          _PoiBusinessMock('Mola Noktası', 'Manzara - 1.4 km', '1.4 km', duration: '3 dk'),
          _PoiBusinessMock('Kafe', 'Kahve + WC', '1.9 km', duration: '5 dk'),
          _PoiBusinessMock('Park', 'Gölge alan', '2.6 km', duration: '7 dk'),
        ];
      case 2:
        return const [
          _PoiBusinessMock('Lastikçi', 'Acil servis', '1.2 km', duration: '4 dk'),
          _PoiBusinessMock('Servis A', 'Bakım - 2.7 km', '2.7 km', duration: '6 dk'),
          _PoiBusinessMock('Elektrik', 'Akü takviyesi', '3.8 km', duration: '8 dk'),
        ];
      default:
        return const [
          _PoiBusinessMock('Ekipman Dükkanı', 'Kask / Eldiven', '4.5 km', duration: '9 dk'),
          _PoiBusinessMock('Outdoor', 'Mont / Yağmurluk', '6.2 km', duration: '12 dk'),
        ];
    }
  }

  Widget _buildSuggestionsList(BuildContext context, MapState state) {
    if (state.isSuggesting && state.suggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state.suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Sonuç bulunamadı.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.suggestions.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final suggestion = state.suggestions[index];
        return ListTile(
          onTap: () {
            context.read<MapBloc>().add(
              MapSearchSuggestionSelected(
                location: suggestion,
                isStart: false,
                isStop: true,
              ),
            );
          },
          leading: Icon(
            Icons.location_on_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            suggestion.label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: suggestion.subtitle != null
              ? Text(
                  suggestion.subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _PoiBusinessMock {
  final String title;
  final String distance;
  final String? imageUrl;
  final String? duration;
  final String? type;
  final double? rating;
  final int? reviewCount;
  final bool? isOpen;
  final String? address;

  const _PoiBusinessMock(
    this.title,
    this.distance,
    this.address, {
    this.imageUrl,
    this.duration,
    this.type,
    this.rating,
    this.reviewCount,
    this.isOpen,
  });
}
