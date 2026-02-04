import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/glass_input_field.dart';
import '../widgets/invite_rider_card.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final List<Map<String, String>> _allFriends = [
    {
      "name": "Ahmet Manyas",
      "username": "ahmet_m",
      "img": "https://i.pravatar.cc/150?img=11",
    },
    {
      "name": "Salih Öztürk",
      "username": "salih_z",
      "img": "https://i.pravatar.cc/150?img=3",
    },
    {
      "name": "Harun Karabacak",
      "username": "harun_k",
      "img": "https://i.pravatar.cc/150?img=59",
    },
    {
      "name": "Caner Demir",
      "username": "caner_d",
      "img": "https://i.pravatar.cc/150?img=12",
    },
    {
      "name": "Mert Yılmaz",
      "username": "mert_y",
      "img": "https://i.pravatar.cc/150?img=18",
    },
  ];

  final List<Map<String, String>> _selectedRiders = [];
  String _searchQuery = "";

  void _toggleRider(Map<String, String> rider) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedRiders.contains(rider)
          ? _selectedRiders.remove(rider)
          : _selectedRiders.add(rider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Sürücü Davet Et", style: AppTextStyles.h3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(_selectedRiders),
            child: Text(
              "Bitti",
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          /// 🌈 ARKA PLAN
          Container(
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
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔥 SEÇİLENLER ALANI (BUGSIZ)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      SizeTransition(sizeFactor: anim, child: child),
                  child: _selectedRiders.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          key: const ValueKey("selected"),
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 4,
                          ),
                          child: SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              padding:
                                  const EdgeInsets.only(), // Üstten pay bıraktık
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

                /// 🔍 ARAMA
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GlassInputField(
                    hintText: "Kullanıcı Ara...",
                    prefixIcon: Icons.search,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                /// 📋 LİSTE
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _allFriends.length,
                    itemBuilder: (context, index) {
                      final rider = _allFriends[index];
                      if (_searchQuery.isNotEmpty &&
                          !rider['name']!.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }

                      final nameParts = rider['name']!.split(' ');
                      final firstName = nameParts.first;
                      final lastName = nameParts.length > 1
                          ? nameParts.skip(1).join(' ')
                          : "";

                      return InviteRiderCard(
                        firstName: firstName,
                        lastName: lastName,
                        username: rider['username']!,
                        profileImageUrl: rider['img']!,
                        isFriend: true,
                        isSelected: _selectedRiders.contains(rider),
                        onInviteTap: () => _toggleRider(rider),
                        onFriendshipTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 SEÇİLEN AVATAR
  Widget _buildSelectedAvatar(
    Map<String, String> rider,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(rider['img']!),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: GestureDetector(
                  onTap: () => _toggleRider(rider),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rider['username']!,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
