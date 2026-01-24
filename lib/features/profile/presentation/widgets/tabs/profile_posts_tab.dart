import 'package:flutter/material.dart';

class ProfilePostsTab extends StatelessWidget {
  const ProfilePostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema bağımsız, direkt o attığın fotodaki koyu tonu yakalayalım
    // Karelerin rengi (Çok koyu gri)
    final Color placeholderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : const Color.fromARGB(255, 166, 166, 175);

    return CustomScrollView(
      key: const PageStorageKey('posts_tab'),
      slivers: [
        // 🔥 Header ile çakışmayı önleyen zımbırtı
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.only(top: 2), // Üstten minik boşluk
          
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Yan yana 3 tane
              mainAxisSpacing: 1.5, // Aradaki çizgi inceliği (Resimdeki gibi ince)
              crossAxisSpacing: 1.5, 
              childAspectRatio: 1.0, // Tam Kare
            ),
            
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return InkWell(
                  onTap: () {
                    // İlerde buraya detay sayfasına gitme kodu gelecek
                    print("Post $index tıklandı");
                  },
                  child: Container(
                    color: placeholderColor,
                    // İlerde resim geldiğinde burası şöyle olacak:
                    // child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                );
              },
              childCount: 24,
            ),
          ),
        ),
        
        // En alta boşluk (Navigasyonun altında kalmasın)
        const SliverToBoxAdapter(
          child: SizedBox(height: 80), 
        ),
      ],
    );
  }
}
