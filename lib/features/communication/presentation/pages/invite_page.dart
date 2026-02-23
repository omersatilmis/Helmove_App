import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- DI & CORE WIDGETS ---
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/theme/text_styles.dart';

// --- DOMAIN & ENTITIES ---
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../../../voice_session/data/dto/invite_users_request_dto.dart';

// --- BLOCS ---
import '../../../friendship/presentation/bloc/list/friendship_list_bloc.dart';
import '../../../friendship/presentation/bloc/list/friendship_list_event.dart';
import '../../../friendship/presentation/bloc/list/friendship_list_state.dart';
import '../../../discover/presentation/bloc/discover_bloc.dart';
import '../../../discover/presentation/bloc/discover_event.dart';
import '../../../discover/presentation/bloc/discover_state.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../../../voice_session/domain/entities/voice_session_entity.dart';
import '../../../voice_session/domain/entities/voice_session_participant_entity.dart';
import '../../../group_ride/presentation/bloc/group_ride_bloc.dart';
import '../../../group_ride/presentation/bloc/group_ride_event.dart';
import '../../../group_ride/presentation/bloc/group_ride_state.dart';
import '../../../group_ride/data/dto/create_group_ride_request_dto.dart';
import '../../../group_ride/presentation/models/group_ride_args.dart';

// --- LOCAL WIDGETS ---
import '../widgets/invite_rider_card.dart';

import '../../../../core/navigation/base_navigation_args.dart';
import '../../../../core/mixins/navigation_guard_mixin.dart';
import '../models/invite_args.dart';

class InvitePage extends StatefulWidget {
  final InviteArgs args;

  const InvitePage({super.key, required this.args});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage>
    with NavigationGuardMixin<InvitePage> {
  @override
  BaseNavigationArgs? get args => widget.args;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<FriendshipListBloc>()..add(LoadMyFriendsEvent()),
        ),
        BlocProvider(create: (_) => sl<DiscoverBloc>()),
        BlocProvider.value(value: sl<VoiceSessionBloc>()),
        BlocProvider.value(value: context.read<GroupRideBloc>()),
      ],
      child: _InviteView(args: widget.args),
    );
  }
}

class _InviteView extends StatefulWidget {
  final InviteArgs args;

  const _InviteView({required this.args});

  @override
  State<_InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends State<_InviteView> {
  final List<FriendUserEntity> _selectedRiders = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.args.sessionId > 0) {
      context.read<VoiceSessionBloc>().add(
        GetVoiceSessionDetailsEvent(widget.args.sessionId),
      );
    }
  }

  void _toggleRider(FriendUserEntity rider) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _selectedRiders.indexWhere((r) => r.userId == rider.userId);
      if (index != -1) {
        _selectedRiders.removeAt(index);
      } else {
        _selectedRiders.add(rider);
        // Arama sonucundan eklediyse aramayı temizle ve klavyeyi kapat
        if (_isSearching) {
          _isSearching = false;
          _searchController.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      }
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);
      context.read<DiscoverBloc>().add(SearchUsersEvent(query: query));
    } else {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final session = context.select<VoiceSessionBloc, VoiceSessionEntity?>(
      (bloc) => bloc.state.session,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<VoiceSessionBloc, VoiceSessionState>(
          listener: (context, state) {
            if (state.status == VoiceSessionStatus.created) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sesli oturum oluşturuldu!")),
              );
            } else if (state.status == VoiceSessionStatus.inviteSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Davetler başarıyla gönderildi!"),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop();
            } else if (state.status == VoiceSessionStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? "Bir hata oluştu"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<GroupRideBloc, GroupRideState>(
          listener: (context, state) {
            if (state is GroupRideFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Hata: ${state.message}"),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is GroupRideCreatedSync) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Grup ve Sesli Oturum başarıyla oluşturuldu!"),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to Group Page with the new data
              // 使用 context.go to reset the stack so Back button goes to Communication Page
              context.go(
                '/communication/group-page',
                extra: GroupRideArgs(
                  rideId: state.ride.id,
                  sessionId: state.sessionId,
                  groupName: state.ride.title,
                  maxParticipants: state.ride.maxParticipants,
                  currentParticipants: 1,
                  destination: state.ride.endLocation,
                  ridingStyle: state.ride.difficulty ?? "Sakin Sürüş",
                  privacy: "Public",
                ),
              );
            } else if (state is GroupRideSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange,
                ),
              );
              context.go(
                '/communication/group-page',
                extra: GroupRideArgs(
                  rideId: state.ride.id,
                  groupName: state.ride.title,
                  maxParticipants: state.ride.maxParticipants,
                  currentParticipants: 1,
                  destination: state.ride.endLocation,
                  ridingStyle: state.ride.difficulty ?? "Sakin Sürüş",
                  privacy: "Public",
                ),
              );
            }
          },
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
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
                    colorScheme.surfaceContainerLowest,
                    colorScheme.surface,
                  ],
                ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // 🔥 Stack yerine Column yapısı (Sabit Header ve Footer için)
          body: SafeArea(
            child: Column(
              children: [
                // --- 1. HEADER (SABİT) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: [
                      AppFrostedButton(
                        icon: Icons.close,
                        size: 44,
                        onTap: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          "Sürücü Davet Et",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Sağ taraf boş kalsın ki başlık ortalansın (veya buraya başka buton eklenebilir)
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // --- 2. İÇERİK (SCROLLABLE & EXPANDED) ---
                Expanded(
                  child: Column(
                    children: [
                      // SEÇİLENLER (Yatay Liste)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            SizeTransition(sizeFactor: anim, child: child),
                        child: _selectedRiders.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                key: const ValueKey("selected"),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemCount: _selectedRiders.length,
                                    itemBuilder: (context, index) {
                                      return _buildSelectedAvatar(
                                        _selectedRiders[index],
                                        colorScheme,
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),

                      // ARAMA INPUTU
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: AppInputField(
                          controller: _searchController,
                          hint: "Kullanıcı Ara...",
                          leadingIcon: Icons.search,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _performSearch(),
                          onChanged: (val) {
                            if (val.isEmpty && _isSearching) {
                              setState(() => _isSearching = false);
                            }
                          },
                          suffixWidget: IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              color: colorScheme.primary,
                            ),
                            onPressed: _performSearch,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // KULLANICI LİSTESİ (Expanded ile kalan alanı kaplar)
                      Expanded(
                        child: _isSearching
                            ? _buildSearchResults(session)
                            : _buildFriendsList(session),
                      ),
                    ],
                  ),
                ),

                // --- 3. FOOTER (SABİT BUTON) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: BlocBuilder<GroupRideBloc, GroupRideState>(
                    builder: (context, rideState) {
                      return BlocBuilder<VoiceSessionBloc, VoiceSessionState>(
                        builder: (context, vsState) {
                          final isLoading =
                              rideState is GroupRideLoading ||
                              vsState.status == VoiceSessionStatus.loading;
                          return AppFrostedTextButton(
                            text: widget.args.isFromCreateGroup
                                ? "Grubu Kur"
                                : "Kişileri Davet Et",
                            isLoading: isLoading,
                            height: 52,
                            // 🔥 Turuncu (Primary) Renk
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            textColor: colorScheme.primary,
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (widget.args.isFromCreateGroup &&
                                        widget.args.groupData != null) {
                                      // ... (Log omitted for brevity)
                                      // ... (CreateGroupRideRequestDto building omitted)
                                      final request = CreateGroupRideRequestDto(
                                        title:
                                            widget
                                                .args
                                                .groupData!["groupName"] ??
                                            "Yeni Grup",
                                        description:
                                            (widget
                                                    .args
                                                    .groupData!["description"]
                                                    ?.toString()
                                                    .isNotEmpty ??
                                                false)
                                            ? widget
                                                  .args
                                                  .groupData!["description"]
                                            : "belirlenmedi",
                                        maxParticipants:
                                            widget
                                                .args
                                                .groupData!["maxParticipants"] ??
                                            10,
                                        privacy:
                                            widget.args.groupData!["privacy"] ??
                                            "Public",
                                        startDateTime: DateTime.now(),
                                        endDateTime: DateTime.now().add(
                                          const Duration(hours: 4),
                                        ),
                                        startLocation: "Mevcut Konum",
                                        startLatitude: 0,
                                        startLongitude: 0,
                                        endLocation:
                                            widget
                                                .args
                                                .groupData!["destination"] ??
                                            "Hedef Belirtilmedi",
                                        endLatitude: 0,
                                        endLongitude: 0,
                                        difficulty:
                                            widget
                                                .args
                                                .groupData!["difficulty"] ??
                                            "Beginner",
                                        ridingStyle:
                                            widget
                                                .args
                                                .groupData!["ridingStyle"] ??
                                            "Sakin",
                                        invitedUserIds: _selectedRiders
                                            .map((e) => e.userId)
                                            .toList(),
                                      );

                                      context.read<GroupRideBloc>().add(
                                        CreateGroupRideEvent(request),
                                      );
                                    } else if (widget.args.sessionId > 0 &&
                                        _selectedRiders.isNotEmpty) {
                                      debugPrint(
                                        "📨 [VoiceSession] Davet event'i gönderiliyor. SessionID: ${widget.args.sessionId}",
                                      );
                                      final request = InviteUsersRequestDto(
                                        userIds: _selectedRiders
                                            .map((e) => e.userId)
                                            .toList(),
                                      );
                                      context.read<VoiceSessionBloc>().add(
                                        InviteUsersEvent(
                                          widget.args.sessionId,
                                          request,
                                        ),
                                      );
                                      // Button will be disabled due to loading state, no need to pop here.
                                    } else {
                                      debugPrint(
                                        "🔙 [GroupRide] Geri dönülüyor: ${_selectedRiders.length} kişi",
                                      );
                                      context.pop(_selectedRiders);
                                    }
                                  },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSelectedAvatar(FriendUserEntity rider, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      (rider.profilePictureUrl != null &&
                          rider.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(rider.profilePictureUrl!)
                      : null,
                  child:
                      (rider.profilePictureUrl == null ||
                          rider.profilePictureUrl!.isEmpty)
                      ? Text(rider.username[0].toUpperCase())
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: GestureDetector(
                  onTap: () => _toggleRider(rider),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: Text(
              rider.username,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(VoiceSessionEntity? session) {
    return BlocBuilder<DiscoverBloc, DiscoverState>(
      builder: (context, state) {
        if (state is DiscoverLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DiscoverFailure) {
          return Center(child: Text(state.message));
        } else if (state is DiscoverLoaded) {
          final results = state.results;
          if (results.isEmpty) {
            return const Center(child: Text("Sonuç bulunamadı."));
          }
          return _buildRiderList(
            results,
            isFriendshipFixed: false,
            session: session,
          );
        }
        return const Center(child: Text("Aramak için 'Ara' butonuna basın"));
      },
    );
  }

  Widget _buildFriendsList(VoiceSessionEntity? session) {
    return BlocBuilder<FriendshipListBloc, FriendshipListState>(
      builder: (context, state) {
        if (state is FriendshipListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendshipListFailure) {
          return Center(child: Text(state.message));
        } else if (state is MyFriendsLoaded) {
          final friends = state.friends;
          if (friends.isEmpty) {
            return const Center(child: Text("Henüz arkadaşınız yok."));
          }
          return _buildRiderList(
            friends,
            isFriendshipFixed: true,
            session: session,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRiderList(
    List<FriendUserEntity> riders, {
    required bool isFriendshipFixed,
    required VoiceSessionEntity? session,
  }) {
    // Liste scroll edilebilir, footer sabit olduğu için bottom padding'e gerek yok (Container padding'i var)
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: riders.length,
      itemBuilder: (context, index) {
        final rider = riders[index];
        final isSelected = _selectedRiders.any((r) => r.userId == rider.userId);
        final inviteStatus = _resolveInviteStatus(rider.userId, session);

        return InviteRiderCard(
          firstName: rider.firstName ?? "",
          lastName: rider.lastName ?? "",
          username: rider.username,
          profileImageUrl: rider.profilePictureUrl ?? "",
          isFriend: isFriendshipFixed,
          isSelected: isSelected,
          inviteStatus: inviteStatus,
          onInviteTap: () => _toggleRider(rider),
          onFriendshipTap: () {},
        );
      },
    );
  }

  InviteStatus _resolveInviteStatus(int userId, VoiceSessionEntity? session) {
    final participants = session?.participants ?? const [];
    VoiceSessionParticipantEntity? matched;
    for (final participant in participants) {
      if (participant.userId == userId) {
        matched = participant;
        break;
      }
    }

    switch (matched?.status) {
      case 'Invited':
        return InviteStatus.pending;
      case 'Accepted':
      case 'Joined':
      case 'Disconnected':
        return InviteStatus.accepted;
      case 'Rejected':
      case 'Left':
        return InviteStatus.rejected;
      default:
        return InviteStatus.none;
    }
  }
}
