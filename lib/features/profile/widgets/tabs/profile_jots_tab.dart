import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/profile/widgets/tabs/jots/jots_widget.dart';
// Yeni sayfan

class ProfileJotsTab extends StatefulWidget {
  const ProfileJotsTab({super.key});

  @override
  State<ProfileJotsTab> createState() => _ProfileJotsTabState();
}

class _ProfileJotsTabState extends State<ProfileJotsTab> {
  final List<Map<String, String>> _jots = [
    {
      "firstName": "Marcus",
      "lastName": "Teanly",
      "userName": "marcusteanly",
      "content": "Hafta sonu rotası belli mi beyler? Teker dönsün! 🏍️💨 #motolife",
      "time": "2h"
    },
    {
      "firstName": "Marcus",
      "lastName": "Teanly",
      "userName": "marcusteanly",
      "content": "Yeni rotalar keşfetmek için sabırsızlanıyorum. Belgrad ormanı tarafı sakin midir?",
      "time": "5h"
    },
  ];

// 🔥 GoRouter ile Sayfaya Giden ve Veriyi Alan Fonksiyon
  void _openCreateJot() async {
    // 1. Adım: Belirlediğin path üzerinden sayfayı aç
    // Not: app_route.dart içinde path'i ne verdiysen onu yaz (Örn: '/create-jot')
    final result = await context.push<String>('/create_jots');

    // 2. Adım: Eğer kullanıcı "Jotla" dediyse ve boş dönmediyse listeye ekle
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _jots.insert(0, {
          "firstName": "Marcus",
          "lastName": "Teanly",
          "userName": "marcusteanly",
          "content": result,
          "time": "Şimdi"
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 🔥 TWITTER TARZI YUVARLAK FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateJot,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(), // Tam yuvarlak yapar
        child: const Icon(Icons.edit_note_rounded, size: 28),
      ),
      // Butonu sağ alt köşeye tam oturtur (zaten default budur ama garantiye alalım)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      body: CustomScrollView(
        key: const PageStorageKey('jots_tab'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final jot = _jots[index];
                return JotCardWidget(
                  firstName: jot["firstName"]!,
                  lastName: jot["lastName"]!,
                  userName: jot["userName"]!,
                  content: jot["content"]!,
                  timeAgo: jot["time"]!,
                );
              },
              childCount: _jots.length,
            ),
          ),
          // Listenin bitişinde butonun içeriği kapatmaması için boşluk
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}