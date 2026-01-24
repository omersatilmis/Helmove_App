import 'dart:math' as math; // 🔥 1. Ekleme: Matematik kütüphanesi (Max işlemi için)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';
import 'package:flutter_application_1/features/profile/widgets/profile_info.dart';
import 'package:flutter_application_1/features/profile/widgets/profile_tabs.dart';
import 'package:flutter_application_1/core/widgets/app_button_frosted.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileInfoKey = GlobalKey();

  // Veriler (Başlangıçta boş veya placeholder olabilir)
  final String _firstName = "MarcusX";
  final String _lastName = "Teanly";
  final String _username = "marcusteanly";

  // 🔥 2. Düzeltme: Başlangıç değeri 0 olmasın, güvenli bir değer olsun.
  double _dynamicHeight = 450; 

  double _headerOpacity = 1.0;
  double _statsOpacity = 1.0;
  bool _showPinnedTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    
    // İlk açılışta ölçüm yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeight();
    });
  }

  void _calculateHeight() {
    final RenderBox? renderBox = _profileInfoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      // Eğer ölçülen boyut ile mevcut boyut farklıysa güncelle
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
    
    // 0'a bölünme hatasını önlemek için kontrol
    final totalHeight = _dynamicHeight > 0 ? _dynamicHeight : 300.0;
    
    final headerFade = (1 - (offset / (totalHeight * 0.75))).clamp(0.0, 1.0);
    final statsStart = totalHeight * 0.35;
    final statsEnd = totalHeight * 0.55;

    // statsEnd - statsStart 0 olursa hata verir, onu da koruyalım
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topSafe = MediaQuery.of(context).padding.top;

    // 🔥 4. Çözüm: Minimum Yükseklik Hesabı (ExpandedHeight Koruması)
    // Toolbar yüksekliği + Status bar + biraz boşluk
    final double minAppBarHeight = kToolbarHeight + topSafe + 20;

    return DefaultTabController(
      length: 5,
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
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      sliver: SliverAppBar(
                        // 🔥 5. Çözüm: math.max kullanımı
                        // Dinamik yükseklik ne kadar küçük gelirse gelsin,
                        // asla minAppBarHeight'tan daha küçük olamaz. Hata vermez.
                        expandedHeight: math.max(_dynamicHeight, minAppBarHeight),
                        
                        toolbarHeight: kToolbarHeight + topSafe + 15,
                        pinned: true,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        centerTitle: true,
                        
                        title: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _showPinnedTitle ? 1 : 0,
                          child: Padding(
                            padding: EdgeInsets.only(top: topSafe / 1.5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$_firstName $_lastName", 
                                  style: AppTextStyles.h3.copyWith(
                                    fontSize: 18,
                                    color: theme.colorScheme.onSurface
                                  )
                                ),
                                Text(
                                  "@$_username", 
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  )
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Container(
                                    // 🔥 Key burada olduğu sürece her şeyi ölçeriz
                                    key: _profileInfoKey,
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ProfileInfo(
                                      firstName: _firstName,
                                      lastName: _lastName,
                                      username: _username,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Fade efektleri (Aynı kalıyor)
                              IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 120),
                                  opacity: 1 - _headerOpacity,
                                  child: Container(color: theme.scaffoldBackgroundColor),
                                ),
                              ),
                              Positioned(
                                bottom: 0, left: 0, right: 0, height: 160,
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 120),
                                    opacity: 1 - _statsOpacity,
                                    child: Container(color: theme.scaffoldBackgroundColor),
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

            // Butonlar (Aynı kalıyor)
            Positioned(
              top: topSafe + 5,
              left: 12, right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppFrostedButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  AppFrostedButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}