import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_event.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_state.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/group_ride/data/dto/create_group_ride_request_dto.dart';
import '../../../../features/group_ride/domain/entities/group_ride_entity.dart';

class GroupSettings extends StatefulWidget {
  final GroupRideArgs data;
  final ScrollController? scrollController;

  const GroupSettings({super.key, required this.data, this.scrollController});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  // Kontrolcüler
  late TextEditingController _groupNameController;
  late TextEditingController _destinationController;
  late TextEditingController _descriptionController;

  // Durum değişkenleri
  late String selectedPrivacy;
  late String selectedDifficulty;
  late String selectedRidingStyle;
  late String selectedMaxParticipantsKey;
  bool isOrganizer = false;

  // Katılımcı Seçenekleri (Map)
  final Map<String, int> participantOptions = {
    '4 riders': 4,
    '6 riders': 6,
    '8 riders': 8,
    '10 riders': 10,
    '12 riders': 12,
  };

  @override
  void initState() {
    super.initState();
    // 1. Verileri Doldur (Pre-fill)
    _groupNameController = TextEditingController(text: widget.data.groupName);
    _destinationController = TextEditingController(
      text: widget.data.destination,
    );
    _descriptionController = TextEditingController(
      text: widget.data.description,
    );

    selectedPrivacy = widget.data.privacy ?? "Public";
    selectedDifficulty = widget.data.difficulty ?? "Beginner";
    selectedRidingStyle = widget.data.ridingStyle ?? "Sakin";

    final matchingKey = participantOptions.keys.firstWhere(
      (k) => participantOptions[k] == widget.data.maxParticipants,
      orElse: () => '6 riders',
    );
    selectedMaxParticipantsKey = matchingKey;

    // 2. Yetki Kontrolü (ReadOnly Mode)
    _checkPermission();

    // 3. Güncel Verileri Yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupRideBloc>().add(
        LoadGroupRideDetailsEvent(widget.data.rideId),
      );
    });
  }

  Future<void> _checkPermission() async {
    final user = await sl<AuthRepository>().getPersistedUser();
    if (mounted) {
      setState(() {
        isOrganizer =
            (user != null &&
            widget.data.organizerId != null &&
            user.id == widget.data.organizerId);
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateControllers(GroupRideEntity ride) {
    if (_groupNameController.text != ride.title) {
      _groupNameController.text = ride.title;
    }
    if (_destinationController.text != ride.endLocation) {
      _destinationController.text = ride.endLocation;
    }
    if (_descriptionController.text != ride.description) {
      _descriptionController.text = ride.description ?? "";
    }

    setState(() {
      selectedDifficulty = ride.difficulty ?? "Beginner";
      selectedRidingStyle = ride.ridingStyle ?? "Sakin";

      final matchingKey = participantOptions.keys.firstWhere(
        (k) => participantOptions[k] == ride.maxParticipants,
        orElse: () => '6 riders',
      );
      selectedMaxParticipantsKey = matchingKey;
    });
  }

  // Güncelleme İşlemi
  void _onUpdate() {
    if (!isOrganizer) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final request = CreateGroupRideRequestDto(
      title: _groupNameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDateTime: widget.data.startDateTime ?? DateTime.now(),
      endDateTime:
          widget.data.endDateTime ??
          DateTime.now().add(const Duration(hours: 2)),
      startLocation: widget.data.startLocation ?? "",
      startLatitude: widget.data.startLatitude ?? 0,
      startLongitude: widget.data.startLongitude ?? 0,
      endLocation: _destinationController.text.trim(),
      endLatitude: widget.data.endLatitude ?? 0,
      endLongitude: widget.data.endLongitude ?? 0,
      maxParticipants: participantOptions[selectedMaxParticipantsKey] ?? 6,
      difficulty: selectedDifficulty,
      ridingStyle: selectedRidingStyle,
      privacy: selectedPrivacy,
    );

    context.read<GroupRideBloc>().add(
      UpdateGroupRideEvent(
        widget.data.rideId,
        request,
        widget.data.organizerId ?? 0,
      ),
    );
  }

  void _onDelete() {
    context.read<GroupRideBloc>().add(
      DeleteGroupRideEvent(
        widget.data.rideId,
        voiceSessionId: widget.data.voiceSessionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A100A), Color(0xFF12100E)],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    final labelStyle = AppTextStyles.inputLabel.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return BlocListener<GroupRideBloc, GroupRideState>(
      listener: (context, state) {
        if (state is GroupRideDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Grup turu ve ses oturumu sonlandırıldı"),
            ),
          );
          context.go('/communication');
        } else if (state is GroupRideFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Hata: ${state.message}")));
        } else if (state is GroupRideSuccess) {
          _updateControllers(state.ride);
          if (state.message.contains("güncellendi")) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        }
      },
      child: BlocBuilder<GroupRideBloc, GroupRideState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  // --- 1. Sabit Başlık (Sticky Header) ---
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: Center(
                      child: AppFrostedButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                        size: 40,
                      ),
                    ),
                    centerTitle: true,
                    title: Text(
                      "Grup Ayarları",
                      style: AppTextStyles.h3.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),

                  // --- 2. Form İçeriği ---
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),

                        // Grup Adı
                        Text("Grup Adı", style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _groupNameController,
                          hint: "Grup Adı",
                          leadingIcon: Icons.group,
                          enabled: isOrganizer,
                        ),
                        const SizedBox(height: 16),

                        // Maksimum Sürücü
                        Text("Maksimum Sürücü", style: labelStyle),
                        const SizedBox(height: 6),
                        _buildGlassDropdown(colorScheme),
                        const SizedBox(height: 16),

                        // Grup Gizliliği
                        Text("Grup Gizliliği", style: labelStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrivacyCard(
                                title: "Herkese Açık",
                                subtitle: "Herkes katılabilir",
                                icon: Icons.public,
                                isSelected: selectedPrivacy == 'Public',
                                onTap: isOrganizer
                                    ? () => setState(
                                        () => selectedPrivacy = 'Public',
                                      )
                                    : () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPrivacyCard(
                                title: "Özel",
                                subtitle: "Sadece davetliler",
                                icon: Icons.lock_outline,
                                isSelected: selectedPrivacy == 'Private',
                                onTap: isOrganizer
                                    ? () => setState(
                                        () => selectedPrivacy = 'Private',
                                      )
                                    : () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rota / Hedef
                        Text("Rota / Hedef", style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _destinationController,
                          hint: "Örn: Abant Gölü",
                          leadingIcon: Icons.map,
                          enabled: isOrganizer,
                        ),
                        const SizedBox(height: 16),

                        // Sürüş Tarzı ve Zorluk
                        Text("Sürüş Tarzı ve Zorluk", style: labelStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAccordionSelector(
                                title: selectedRidingStyle,
                                icon: Icons.two_wheeler,
                                options: ['Sakin', 'Tour', 'Viraj', 'Sehir'],
                                onSelected: isOrganizer
                                    ? (val) => setState(
                                        () => selectedRidingStyle = val,
                                      )
                                    : (val) {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildAccordionSelector(
                                title: selectedDifficulty,
                                icon: Icons.speed,
                                options: [
                                  'Beginner',
                                  'Intermediate',
                                  'Advanced',
                                  'Expert',
                                ],
                                onSelected: isOrganizer
                                    ? (val) => setState(
                                        () => selectedDifficulty = val,
                                      )
                                    : (val) {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Açıklama
                        Text("Açıklama", style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _descriptionController,
                          hint: "Sürüş hakkında açıklama...",
                          leadingIcon: Icons.description,
                          maxLines: 3,
                          enabled: isOrganizer,
                        ),
                        const SizedBox(height: 30),
                      ]),
                    ),
                  ),

                  // --- 3. Butonlar (Sadece Organizer ise) ---
                  if (isOrganizer)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppFrostedTextButton(
                                    text: "Sonlandır",
                                    height: 52,
                                    backgroundColor: colorScheme.error
                                        .withOpacity(0.1),
                                    textColor: colorScheme.error,
                                    onPressed: _onDelete,
                                    isLoading: state is GroupRideLoading,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppFrostedTextButton(
                                    text: "Güncelle",
                                    height: 52,
                                    backgroundColor: colorScheme.primary
                                        .withOpacity(0.1),
                                    textColor: colorScheme.primary,
                                    onPressed: _onUpdate,
                                    isLoading: state is GroupRideLoading,
                                  ),
                                ),
                              ],
                            ),
                            // Bottom Navigation Bar'ın arkasında kalmaması için safe area padding
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 80,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Eğer Organizer değilse de bottom padding ekle
                  if (!isOrganizer)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 80,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMaxParticipantsKey,
          dropdownColor: colorScheme.surfaceContainerLow,
          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
          isExpanded: true,
          style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
          items: participantOptions.keys.map((String key) {
            return DropdownMenuItem<String>(value: key, child: Text(key));
          }).toList(),
          onChanged: isOrganizer
              ? (newValue) {
                  if (newValue != null) {
                    setState(() => selectedMaxParticipantsKey = newValue);
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionSelector({
    required String title,
    required IconData icon,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      enabled: isOrganizer,
      onSelected: onSelected,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -4),
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(
            opt,
            style: AppTextStyles.bodySmall.copyWith(
              color: opt == title ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: opt == title ? FontWeight.w500 : FontWeight.w300,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
