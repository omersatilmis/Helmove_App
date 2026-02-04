import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

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
    setState(() {
      if (_selectedRiders.contains(rider)) {
        _selectedRiders.remove(rider);
      } else {
        _selectedRiders.add(rider);
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Seçilenleri geri döndür veya backend'e gönder
              Navigator.pop(context, _selectedRiders);
            },
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
          // Arka Plan Gradyanı (Diğer sayfalarla aynı)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
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
                        colorScheme.primary.withOpacity(0.05),
                        colorScheme.surface,
                      ],
                      stops: const [0.0, 0.4],
                    ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. SEÇİLEN KİŞİLER (Yatay Pit Stop Alanı)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _selectedRiders.isEmpty ? 0 : 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedRiders.length,
                    itemBuilder: (context, index) {
                      final rider = _selectedRiders[index];
                      return _buildSelectedAvatar(rider, colorScheme);
                    },
                  ),
                ),

                // 2. ARAMA INPUT ALANI (Buzlu Cam)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildGlassSearchField(colorScheme),
                ),

                // 3. ARKADAŞ / ARAMA LİSTESİ
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _allFriends.length,
                    itemBuilder: (context, index) {
                      final rider = _allFriends[index];
                      // Basit arama filtresi
                      if (_searchQuery.isNotEmpty &&
                          !rider['name']!.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }
                      return _buildRiderCard(rider, colorScheme);
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

  // Üstteki seçili PP'ler
  Widget _buildSelectedAvatar(
    Map<String, String> rider,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(rider['img']!),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _toggleRider(rider),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
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

  // Buzlu Cam Arama Alanı
  Widget _buildGlassSearchField(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Kullanıcı Ara...",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  // Alt Liste Kartları
  Widget _buildRiderCard(Map<String, String> rider, ColorScheme colorScheme) {
    bool isSelected = _selectedRiders.contains(rider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(rider['img']!),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider['name']!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("@${rider['username']}", style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _toggleRider(rider),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? colorScheme.surface
                  : colorScheme.primary,
              foregroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(color: colorScheme.primary)
                    : BorderSide.none,
              ),
            ),
            child: Text(isSelected ? "Çıkar" : "Ekle"),
          ),
        ],
      ),
    );
  }
}
