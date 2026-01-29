import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- KENDİ PROJE IMPORTLARIN ---
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/profile_info.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/profile_tabs.dart';

// 🔥 PROVIDER IMPORTLARI
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

// 🔥 FRIENDSHIP BLOC IMPORTLARI
import 'package:flutter_bloc/flutter_bloc.dart'
    hide ReadContext, WatchContext, SelectContext;
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/list/friendship_list_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/list/friendship_list_event.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/list/friendship_list_state.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_event.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/status/friendship_status_state.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_event.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/bloc/action/friendship_action_state.dart';
import 'package:moto_comm_app_1/features/friendship/domain/entities/friendship_status.dart';
import 'package:moto_comm_app_1/features/messages/presentation/pages/chat_page.dart';

class ProfilePage extends StatefulWidget {
  // Opsiyonel: Eğer dışarıdan bir ID ile gelindiyse bu parametre dolu olur.
  // Boş ise "Kendi profilim" varsayılır.
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileInfoKey = GlobalKey();
  final GlobalKey _optionsButtonKey =
      GlobalKey(); // 🔥 Seçenekler butonu için key

  double _dynamicHeight = 450;
  double _headerOpacity = 1.0;
  double _statsOpacity = 1.0;
  bool _showPinnedTitle = false;

  // 🔥 Friendship Stats Bloc
  FriendshipListBloc? _friendshipBloc;
  FriendshipStatusBloc? _statusBloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // 🔥 INITIALIZE BLOCS IMMEDIATELY to avoid null crash in first build
    final authProvider = context.read<AuthProvider>();
    final myIdStr = authProvider.currentUser?.id;

    // Kendi profilim mi diye kontrol et
    bool isMe = false;
    if (widget.userId == null) {
      isMe = true;
    } else if (myIdStr != null && widget.userId == myIdStr) {
      isMe = true;
    }

    if (isMe) {
      // 🔥 Kendi profilimizse arkadaşlık istatistiklerini yükle
      _friendshipBloc = sl<FriendshipListBloc>()
        ..add(LoadFriendshipStatsEvent());
    } else {
      // Başkasının profili, ID'yi int'e çevirip yükle
      final userIdInt = int.tryParse(widget.userId!);
      if (userIdInt != null) {
        // 🔥 Status Bloc Başlat
        _statusBloc = sl<FriendshipStatusBloc>()
          ..add(CheckFriendshipStatusEvent(targetUserId: userIdInt));

        // 🔥 NEW: Load stats for visited profile too
        _friendshipBloc = sl<FriendshipListBloc>()
          ..add(LoadFriendshipStatsEvent(userId: userIdInt));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMe) {
        context.read<ProfileProvider>().loadProfile();
      } else {
        final userIdInt = int.tryParse(widget.userId!);
        if (userIdInt != null) {
          context.read<ProfileProvider>().loadUserProfile(userIdInt);
        }
      }
      _calculateHeight();
    });
  }

  void _calculateHeight() {
    final RenderBox? renderBox =
        _profileInfoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      if (renderBox.size.height != _dynamicHeight) {
        setState(() {
          _dynamicHeight = renderBox.size.height;
        });
      }
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final topSafe = MediaQuery.of(context).padding.top;
    final totalHeight = _dynamicHeight > 0 ? _dynamicHeight : 300.0;

    final headerFade = (1 - (offset / (totalHeight * 0.75))).clamp(0.0, 1.0);
    final statsStart = totalHeight * 0.35;
    final statsEnd = totalHeight * 0.55;
    final range = (statsEnd - statsStart) > 0 ? (statsEnd - statsStart) : 1.0;
    final statsFade = (1 - ((offset - statsStart) / range)).clamp(0.0, 1.0);
    final showTitle = offset > (totalHeight - kToolbarHeight - topSafe - 20);

    if (headerFade != _headerOpacity ||
        statsFade != _statsOpacity ||
        showTitle != _showPinnedTitle) {
      setState(() {
        _headerOpacity = headerFade;
        _statsOpacity = statsFade;
        _showPinnedTitle = showTitle;
      });
    }
  }

  // 🔥 ProfileInfo'yu Bloc ile sarmalayan yardımcı metod
  Widget _buildProfileInfoWithBloc({
    required String firstName,
    required String lastName,
    required String username,
    required bool isOwnProfile,
    String? bio,
    String? profileImageUrl,
    int? otherUserId,
  }) {
    // Navigation callback
    final onMessageTap = (otherUserId != null)
        ? () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  otherUserId: otherUserId,
                  username: username,
                  firstName: firstName,
                  lastName: lastName,
                  profileImageUrl: profileImageUrl,
                ),
              ),
            );
          }
        : null;

    // 🔥 Safety Check: Eğer bloc null ise (hata durumu veya geçersiz ID) düz ProfileInfo döndür
    if (_friendshipBloc == null) {
      return ProfileInfo(
        firstName: firstName,
        lastName: lastName,
        username: username,
        bio: bio,
        profileImageUrl: profileImageUrl,
        isOwnProfile: isOwnProfile,
        friendCount: "0",
        onMessageTap: onMessageTap,
      );
    }

    // Ortak BlocBuilder: Hem kendi hem başkasının profili için istatistikleri dinle
    // Eğer _friendshipBloc yoksa (bir hata durumu vs.) statik "0" gösteririz.

    // Arkadaşlık DURUMU (Status) için Listener/Builder (Sadece başkasının profilinde)
    Widget profileInfo = BlocBuilder<FriendshipListBloc, FriendshipListState>(
      bloc: _friendshipBloc,
      builder: (context, statsState) {
        String friendCount = "0";
        if (statsState is FriendshipStatsLoaded) {
          friendCount = statsState.stats.totalFriends.toString();
        }

        // Eğer kendi profilimizse direkt ProfileInfo döndür
        if (isOwnProfile) {
          return ProfileInfo(
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            profileImageUrl: profileImageUrl,
            isOwnProfile: true,
            friendCount: friendCount, // 🔥 Dinamik Arkadaş Sayısı
            onFriendsTap: () => context.push('/friends'),
            onMessageTap: onMessageTap,
            onRatingTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rating sayfası yakında...")),
              );
            },
            onFollowersTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Takipçiler sayfası yakında...")),
              );
            },
            onFollowingTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Takip edilenler sayfası yakında..."),
                ),
              );
            },
          );
        }

        // Başkasının profili ise FriendshipStatusBloc ile sarmala
        return BlocListener<FriendshipActionBloc, FriendshipActionState>(
          listener: (context, actionState) {
            if (actionState is FriendshipActionSuccess) {
              if (otherUserId != null) {
                _statusBloc?.add(
                  CheckFriendshipStatusEvent(targetUserId: otherUserId),
                );
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(actionState.message)));
            } else if (actionState is FriendshipActionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(actionState.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<FriendshipStatusBloc, FriendshipStatusState>(
            bloc: _statusBloc,
            builder: (context, statusState) {
              FriendshipStatus? status;
              FriendRequestType? requestType;
              int? friendshipId;

              if (statusState is FriendshipStatusLoaded) {
                status = statusState.status;
                requestType = statusState.requestType;
                friendshipId = statusState.friendshipId;
              }

              return ProfileInfo(
                firstName: firstName,
                lastName: lastName,
                username: username,
                bio: bio,
                profileImageUrl: profileImageUrl,
                isOwnProfile: false,
                friendCount: friendCount, // 🔥 Dinamik Arkadaş Sayısı (Visited)
                friendshipStatus: status,
                friendRequestType: requestType,
                onMessageTap: onMessageTap,
                onSendRequest: () {
                  if (otherUserId != null) {
                    context.read<FriendshipActionBloc>().add(
                      SendFriendRequestEvent(
                        targetUserId: otherUserId,
                        message: "Merhaba!",
                      ),
                    );
                  }
                },
                onCancelRequest: () {
                  // Backend endpoint yok
                },
                onAcceptRequest: () {
                  if (friendshipId != null) {
                    context.read<FriendshipActionBloc>().add(
                      AcceptFriendRequestEvent(friendshipId: friendshipId),
                    );
                  }
                },
                onRejectRequest: () {
                  if (friendshipId != null) {
                    context.read<FriendshipActionBloc>().add(
                      RejectFriendRequestEvent(friendshipId: friendshipId),
                    );
                  }
                },
                onRemoveFriend: () {
                  if (otherUserId != null) {
                    context.read<FriendshipActionBloc>().add(
                      RemoveFriendEvent(friendId: otherUserId),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );

    return profileInfo;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _friendshipBloc?.close();
    _statusBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topSafe = MediaQuery.of(context).padding.top;

    // 🔥 1. AuthProvider'dan BENİM ID'mi al
    final authProvider = context.watch<AuthProvider>();
    final myIdStr = authProvider.currentUser?.id;
    final myId = myIdStr != null ? int.tryParse(myIdStr) : null;

    // 🔥 4. Kendi profilim mi kontrolü (Logic taşıdık)
    bool isOwnProfile = false;
    if (widget.userId == null) {
      isOwnProfile = true;
    } else if (myId != null && widget.userId == myId.toString()) {
      isOwnProfile = true;
    }

    // 🔥 2. ProfileProvider'dan DOĞRU kullanıcıyı al
    final profileProvider = context.watch<ProfileProvider>();
    // Eğer kendi profilimse 'profile', başkasıysa 'visitedProfile'
    final displayedUser = isOwnProfile
        ? profileProvider.profile
        : profileProvider.visitedProfile;

    // 🔥 3. Verileri hazırla (Null check)
    final firstName = displayedUser?.firstName ?? "";
    final lastName = displayedUser?.lastName ?? "";
    final username = displayedUser?.username ?? "";
    final bio = displayedUser?.bio;
    final profileImageUrl = displayedUser?.profileImageUrl;

    final double minAppBarHeight = kToolbarHeight + topSafe + 20;

    // Loading durumu (Opsiyonel: İstersen tam sayfa loading yapabilirsin)
    // if (profileProvider.isLoading) return Scaffold(...Loading...);

    return MultiBlocProvider(
      providers: [
        BlocProvider<FriendshipActionBloc>(
          create: (_) => sl<FriendshipActionBloc>(),
        ),
        if (_friendshipBloc != null)
          BlocProvider.value(value: _friendshipBloc!),
        if (_statusBloc != null) BlocProvider.value(value: _statusBloc!),
      ],
      child: DefaultTabController(
        length: 5, // Tab sayısı
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                        sliver: SliverAppBar(
                          expandedHeight: math.max(
                            _dynamicHeight,
                            minAppBarHeight,
                          ),
                          toolbarHeight: kToolbarHeight + topSafe + 15,
                          pinned: true,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          centerTitle: true,

                          // Pinned Title (Kaydırınca çıkan isim)
                          title: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _showPinnedTitle ? 1 : 0,
                            child: Padding(
                              padding: EdgeInsets.only(top: topSafe / 1.5),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "$firstName $lastName",
                                    style: AppTextStyles.h3.copyWith(
                                      fontSize: 18,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    "@$username",
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          flexibleSpace: FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: Container(
                                      key: _profileInfoKey,
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),

                                      // 🔥 5. isOwnProfile değerini widget'a gönder
                                      child: _buildProfileInfoWithBloc(
                                        firstName: firstName,
                                        lastName: lastName,
                                        username: username,
                                        bio: bio,
                                        profileImageUrl: profileImageUrl,
                                        isOwnProfile: isOwnProfile,
                                        otherUserId: displayedUser?.id,
                                      ),
                                    ),
                                  ),
                                ),

                                // Header Fade Efekti
                                IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 120),
                                    opacity: 1 - _headerOpacity,
                                    child: Container(
                                      color: theme.scaffoldBackgroundColor,
                                    ),
                                  ),
                                ),
                                // İstatistik Fade Efekti
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 160,
                                  child: IgnorePointer(
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      opacity: 1 - _statsOpacity,
                                      child: Container(
                                        color: theme.scaffoldBackgroundColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const ProfileTabBarSliver(),
                    ];
                  },
                  body: const ProfileTabViews(),
                ),
              ),

              // Üst Butonlar (Geri / Seçenekler)
              Positioned(
                top: topSafe + 5,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppFrostedButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        // Eğer navigasyon geçmişi varsa geri dön, yoksa anasayfaya
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // context.go('/home'); // İsteğe bağlı
                        }
                      },
                    ),

                    // 🔥 Opsiyonel: Kendi profilimse Ayarlar, değilse Şikayet/Block ikonu
                    Container(
                      key: _optionsButtonKey, // Pozisyon almak için
                      child: AppFrostedButton(
                        // 🔥 İKON: Artık her iki durumda da 3 nokta
                        icon: Icons.more_horiz_rounded,

                        // 🔥 MANTIK: Tıklanınca yine kimin profili olduğuna bakıyor
                        onTap: () {
                          if (isOwnProfile) {
                            _showOptionsMenu(context);
                          } else {
                            // Başkasının profili: Şikayet et / Engelle menüsü
                            // print("Başkasının profili: Şikayet menüsünü aç");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsMenu(BuildContext context) async {
    // Butonun konumunu al
    final RenderBox? renderBox =
        _optionsButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final theme = Theme.of(context);

    final value = await showMenu(
      context: context,
      // Butonun hemen altında açılması için pozisyon hesabı
      position: RelativeRect.fromLTRB(
        offset.dx - 150 + size.width, // Sağa yaslı olması için solunu kaydır
        offset.dy + size.height + 10,
        offset.dx + size.width, // Sağ sınır
        offset.dy + size.height + 200, // Alt sınır
      ),
      elevation: 8,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(
                "Profili Paylaş",
                style: AppTextStyles.medium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(
                "Ayarlar",
                style: AppTextStyles.medium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;
    if (value == 'share') {
      // TODO: Profil paylaşımı implementasyonu
    } else if (value == 'settings') {
      // ignore: use_build_context_synchronously
      context.push('/settings');
    }
  }
}
