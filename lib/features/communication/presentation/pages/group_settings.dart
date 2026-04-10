import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/utils/friendship_error_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_state.dart';
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/group_ride/data/dto/create_group_ride_request_dto.dart';
import '../../../../features/group_ride/domain/entities/group_ride_entity.dart';
import '../../../../core/navigation/base_navigation_args.dart';
import '../../../../core/mixins/navigation_guard_mixin.dart';
import '../../../../features/attendance_management/domain/entities/group_role.dart';

class GroupSettings extends StatefulWidget {
  final GroupRideArgs data;
  final ScrollController? scrollController;

  const GroupSettings({super.key, required this.data, this.scrollController});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings>
    with NavigationGuardMixin<GroupSettings> {
  @override
  BaseNavigationArgs? get args => widget.data;

  // Kontrolcüler
  late TextEditingController _groupNameController;
  late TextEditingController _destinationController;
  late TextEditingController _descriptionController;

  // Durum değişkenleri
  late String selectedPrivacy;
  late String selectedDifficulty;
  late String selectedRidingStyle;
  late String selectedMaxParticipantsKey;

  // Permissions
  bool canEdit = false;
  bool canDelete = false;

  // Katılımcı Seçenekleri (Map)
  final List<int> participantCounts = [4, 6, 8, 10, 12];
  late int selectedMaxParticipants;

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
    selectedMaxParticipants = widget.data.maxParticipants ?? 6;

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
    if (user == null || !mounted) return;

    // 1. Admin = Organizer of the GroupRide
    final bool isAdmin =
        (widget.data.organizerId != null && user.id == widget.data.organizerId);

    // 2. Admin = adminId of the VoiceSession
    bool isHost = false;
    try {
      final vsState = context.read<VoiceSessionBloc>().state;
      if (vsState.session != null) {
        isHost =
            vsState.session!.adminId == user.id ||
            vsState.session!.participants.any(
              (p) =>
                  p.userId == user.id &&
                  (p.role == GroupRole.admin || p.role == GroupRole.captain),
            );
      }
    } catch (_) {
      // VoiceSessionBloc not available in tree — skip
    }

    setState(() {
      canEdit = isAdmin || isHost;
      canDelete = isAdmin || isHost;
    });
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
      selectedMaxParticipants = ride.maxParticipants;
    });
  }

  // Güncelleme İşlemi
  void _onUpdate() {
    if (!canEdit) return;

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
      maxParticipants: selectedMaxParticipants,
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
    // ── STEP 1: Dispatch to BOTH Blocs ──
    context.read<GroupRideBloc>().add(
      DeleteGroupRideEvent(
        widget.data.rideId,
        sessionId: widget.data.sessionId,
      ),
    );
    if (widget.data.sessionId != null) {
      context.read<VoiceSessionBloc>().add(
        EndVoiceSessionEvent(widget.data.sessionId!),
      );
    }

    // ── STEP 2: Optimistic UI cleanup ──
    context.read<GroupRideBloc>().add(const ClearGroupDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelStyle = AppTextStyles.inputLabel.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return BlocListener<GroupRideBloc, GroupRideState>(
      listener: (context, state) {
        if (state is GroupRideDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.groupRideAndVoiceSessionEnded),
            ),
          );
          context.go('/communication');
        } else if (state is GroupRideFailure) {
          final mappedMessage = FriendshipErrorMapper.mapForUi(
            rawMessage: state.message,
            l10n: l10n,
            fallback: l10n.errorOccurred,
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorWithPrefix(mappedMessage))));
        } else if (state is GroupRideSuccess) {
          _updateControllers(state.ride);
          if (state.message.contains(l10n.updated)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        }
      },
      child: BlocBuilder<GroupRideBloc, GroupRideState>(
        builder: (context, state) {
          return AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: CustomScrollView(
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
                      l10n.groupSettings,
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
                        Text(l10n.groupName, style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _groupNameController,
                          hint: l10n.groupNameHint,
                          leadingIcon: Icons.group,
                          enabled: canEdit,
                        ),
                        const SizedBox(height: 16),

                        // Maksimum Sürücü
                        Text(l10n.maxRiders, style: labelStyle),
                        const SizedBox(height: 6),
                        _buildGlassDropdown(colorScheme, l10n),
                        const SizedBox(height: 16),

                        // Grup Gizliliği
                        Text(l10n.groupPrivacy, style: labelStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrivacyCard(
                                title: l10n.public,
                                subtitle: l10n.everyoneCanJoin,
                                icon: Icons.public,
                                isSelected: selectedPrivacy == 'Public',
                                onTap: canEdit
                                    ? () => setState(
                                        () => selectedPrivacy = 'Public',
                                      )
                                    : () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPrivacyCard(
                                title: l10n.private,
                                subtitle: l10n.onlyInvitees,
                                icon: Icons.lock_outline,
                                isSelected: selectedPrivacy == 'Private',
                                onTap: canEdit
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
                        Text(l10n.destination, style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _destinationController,
                          hint: l10n.destinationHint,
                          leadingIcon: Icons.map,
                          enabled: canEdit,
                        ),
                        const SizedBox(height: 16),

                        // Sürüş Tarzı ve Zorluk
                        Text(l10n.ridingStyle, style: labelStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAccordionSelector(
                                title: selectedRidingStyle,
                                icon: Icons.two_wheeler,
                                options: ['Sakin', 'Tour', 'Viraj', 'Sehir'],
                                onSelected: canEdit
                                    ? (val) => setState(
                                        () => selectedRidingStyle = val,
                                      )
                                    : (val) {},
                                l10n: l10n,
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
                                onSelected: canEdit
                                    ? (val) => setState(
                                        () => selectedDifficulty = val,
                                      )
                                    : (val) {},
                                l10n: l10n,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Açıklama
                        Text(l10n.description, style: labelStyle),
                        const SizedBox(height: 6),
                        AppInputField(
                          controller: _descriptionController,
                          hint: l10n.descriptionHint,
                          leadingIcon: Icons.description,
                          maxLines: 3,
                          enabled: canEdit,
                        ),
                        const SizedBox(height: 30),
                      ]),
                    ),
                  ),

                  // --- 3. Butonlar ---
                  if (canEdit || canDelete)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: canDelete
                                      ? AppFrostedTextButton(
                                          text: l10n.terminate,
                                          height: 52,
                                          backgroundColor: colorScheme.error
                                              .withValues(alpha: 0.1),
                                          textColor: colorScheme.error,
                                          onPressed: _onDelete,
                                          isLoading: state is GroupRideLoading,
                                        )
                                      : const SizedBox(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppFrostedTextButton(
                                    text: l10n.update,
                                    height: 52,
                                    backgroundColor: colorScheme.primary
                                        .withValues(alpha: 0.1),
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

                  // Eğer yetkili değilse de bottom padding ekle
                  if (!canEdit)
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

  Widget _buildGlassDropdown(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMaxParticipants,
          dropdownColor: colorScheme.surfaceContainerLow,
          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
          isExpanded: true,
          style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
          items: participantCounts.map((int val) {
            return DropdownMenuItem<int>(
                value: val, child: Text(l10n.ridersCount(val)));
          }).toList(),
          onChanged: canEdit
              ? (newValue) {
                  if (newValue != null) {
                    setState(() => selectedMaxParticipants = newValue);
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
    required AppLocalizations l10n,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      enabled: canEdit,
      onSelected: onSelected,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -4),
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(
            _getLocalizedOption(opt, l10n),
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
                _getLocalizedOption(title, l10n),
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

  String _getLocalizedOption(String option, AppLocalizations l10n) {
    switch (option) {
      case 'Sakin':
        return l10n.chill;
      case 'Tour':
        return l10n.tour;
      case 'Viraj':
        return l10n.fast;
      case 'Sehir':
        return l10n.city;
      case 'Beginner':
        return l10n.beginner;
      case 'Intermediate':
        return l10n.intermediate;
      case 'Advanced':
        return l10n.advanced;
      case 'Expert':
        return l10n.expert;
      default:
        return option;
    }
  }
}
