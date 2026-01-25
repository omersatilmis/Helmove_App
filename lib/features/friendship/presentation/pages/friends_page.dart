import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart'; // 🔥 Frosted Button Importu
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'widgets/friends_list.dart';
import 'widgets/pending_requests.dart';
import 'widgets/sent_requests.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppFrostedButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),

        // Başlık Stili
        title: Text('Arkadaşlık', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama Alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppInputField(
              controller: _searchController,
              hint: 'Arkadaş ara...',
              leadingIcon: Icons.search,
              //type: AppInputType.standard, // Gerekirse açabilirsin
            ),
          ),

          // 🔥 TAB BAR (Özelleştirilmiş)
          TabBar(
            controller: _tabController,
            labelStyle: AppTextStyles.bold.copyWith(
              fontSize: 14,
            ), // Seçili yazı
            unselectedLabelStyle: AppTextStyles.medium.copyWith(
              fontSize: 14,
            ), // Pasif yazı
            labelColor: theme.colorScheme.primary, // Seçili renk
            unselectedLabelColor:
                theme.colorScheme.onSurfaceVariant, // Pasif renk
            indicatorColor: theme.colorScheme.primary, // Çizgi rengi
            indicatorSize: TabBarIndicatorSize.tab, // Çizgi genişliği
            tabs: const [
              Tab(text: 'Arkadaşlarım'),
              Tab(text: 'Bekleyenler'),
              Tab(text: 'Gönderilenler'),
            ],
          ),

          // TAB İÇERİKLERİ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FriendsList(),
                PendingRequests(),
                SentRequests(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
